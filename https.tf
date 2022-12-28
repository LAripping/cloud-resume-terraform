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

resource "null_resource" "invalidate_cf_cache" {
  # Only way to trigger invalidation when the state is changed
  # see https://stackoverflow.com/a/69797962
  # ...might introduce requirement for TF AWS user to have cloudfront:create-invalidation perm...
  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.cf_distribution.id} --paths \"/*\""
  }

  # ...and this bit seen here https://faun.pub/lets-do-devops-terraform-hacking-s3-and-cloudfront-dependencies-13c8a2af2f20 
  triggers = {
    any_s3_object_changed = aws_s3_bucket_object.frontend_objects["assets/js/api.js"].etag
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
