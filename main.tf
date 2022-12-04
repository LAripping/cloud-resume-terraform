terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.45.0"
    }
  }
}


locals {
  or_id = "tf-cf-or"
  project = "cloud-resume-tf"
  mime_types = jsondecode(file("${path.module}/mimes.json"))
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "tf-cloud-resume-laripping"
  # acl    = "public-read"  ignored due to Object Ownership
  policy = file("policy.json")

  tags = {
    Name    = "tf-cloud-resume-laripping"
    project = local.project
  }

  website {
    index_document = "resume.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "oo" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_object" "frontend_objects" {
  bucket = aws_s3_bucket.s3_bucket.id
  for_each = fileset("cloud-resume-frontend/", "**")
  key = each.value
  source = "cloud-resume-frontend/${each.value}"
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), null)
}


resource "aws_cloudfront_distribution" "cf_distribution" {
  origin {
    domain_name              = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    # origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.or_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "TF-managed CloudFront distribution pointing to TF Cloud Resume S3"
  default_root_object = "resume.html"

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }

  # aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    target_origin_id = local.or_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    cache_policy_id = aws_cloudfront_cache_policy.cp.id
    compress = true
    viewer_protocol_policy = "redirect-to-https"

  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    project = local.project
  }

  viewer_certificate {
    cloudfront_default_certificate = true   # TODO change after creating yours
  }
}

resource "aws_cloudfront_cache_policy" "cp" {
  name        = "example-policy"
  comment     = "TF-managed Cache Policy for the TF Cloud Resume CF Distribution"
  min_ttl                = 1
  default_ttl            = 86400
  max_ttl                = 31536000
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip = true
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}
