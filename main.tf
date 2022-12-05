terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.45.0"
    }
    # namecheap = {
    #   source = "namecheap/namecheap"
    #   version = ">= 2.0.0"
    # }
  }
}


# Define the default provider (no alias defined):
provider "aws" {
  region = "eu-west-2"
}

# "To use ACM cert with CF, the cert needs to be in 'us-east-1' region" 
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html#https-requirements-certificate-issuer
provider "aws" {
  region = "us-east-1"
  alias = "useast1"
}

# provider "namecheap" {
#   user_name = "user"
#   api_user = "user"
#   api_key = "key"
#   client_ip = "123.123.123.123"
#   use_sandbox = false
# }

locals {
  or_id = "tf-cf-or"
  project = "cloud-resume-tf"
  mime_types = jsondecode(file("${path.module}/mimes.json"))
  resume_subdomain = "resume.tf"
  domain_name = "laripping.com"
}




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
    origin_id                = local.or_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "TF-managed CloudFront distribution pointing to TF Cloud Resume S3"
  default_root_object = "resume.html"
  aliases = [ join(".",[local.resume_subdomain, local.domain_name]) ]
  price_class = "PriceClass_All"


  default_cache_behavior {
    target_origin_id = local.or_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    cache_policy_id = aws_cloudfront_cache_policy.cp.id
    compress = true
    viewer_protocol_policy = "redirect-to-https"

  }
 

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
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
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

resource "aws_acm_certificate" "cert" {
  provider = aws.useast1
  domain_name       = join(".",[local.resume_subdomain, local.domain_name])
  validation_method = "DNS"

  tags = {
    project = local.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DAMN YOU NAMECHEAP WITH YOUR GREEDY POLICIES - YOU RUINED EVERYTHING !!!11
# resource "namecheap_domain_records" "dns_records" {
#   domain = local.domain_name
#   mode = "MERGE"

#   record {
#     hostname = local.resume_subdomain
#     type = "CNAME"
#     address = aws_cloudfront_distribution.cf_distribution.domain_name
#   }

#   record {
#     hostname = aws_acm_certificate.cert.domain_validation_options.resource_record_name # might need to split(.laripping)[0]
#     type = "CNAME"
#     address = aws_acm_certificate.cert.domain_validation_options.resource_record_value
#   }
# }


resource "aws_dynamodb_table" "db" {
  name = "VisitorsTF"
  hash_key = "IP"
  range_key = "UA"
  read_capacity = 2
  write_capacity = 2

  attribute {
    name = "IP"
    type = "S"
  }

  attribute {
    name = "UA"
    type = "S"
  }
  
}