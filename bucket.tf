

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "tf-cloud-resume-laripping"
  # acl    = "public-read"  ignored due to Object Ownership
  policy = file("policy.json")

  tags = {
    Name    = "tf-cloud-resume-laripping"
    project = local.project
  }
}

resource "aws_s3_bucket_website_configuration" "webconfig" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  index_document {
    suffix = "resume.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "oo" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# hack to exclude .git from cloud-resume-frontend/
# https://riferrei.com/excluding-files-from-a-list-in-terraform/
locals {
  frontend_files_all = fileset("cloud-resume-frontend/", "**")
  frontend_files = toset([
    for ff in local.frontend_files_all:
      ff if !startswith(ff,".git")
  ])
}

resource "aws_s3_bucket_object" "frontend_objects" {
  bucket = aws_s3_bucket.s3_bucket.id
  for_each = local.frontend_files
  key = each.value
  source = "cloud-resume-frontend/${each.value}"
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), null)

  etag   = "${filemd5("cloud-resume-frontend/${each.value}")}"

  # force a sync (re-upload) of frontend files when the API changes
  # ...as the provisioner must be re-run to replace the API URL in api.js 
  depends_on = [ 
    aws_api_gateway_stage.api_stg, 
    aws_api_gateway_resource.api_res,
    null_resource.replace_api 
  ]

  # the above block did not trigger re-upload when the provisioner ran...
  # hopefully this block will do the trick
  lifecycle {
    replace_triggered_by = [
      aws_api_gateway_deployment.api_depl
    ]
  }
  
}
