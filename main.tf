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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  backend "s3" {
    bucket = "tf-remote-state-manual"
    key    = "crc-terraform.tfstate"
    region = "eu-west-2"
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

# TODO extract Input in variables.tf (resume_subdomain, domain_name, ..region? )
locals {
  or_id = "tf-cf-or"
  project = "cloud-resume-tf"
  mime_types = jsondecode(file("${path.module}/mimes.json"))
  resume_subdomain = "resume.tf"
  domain_name = "laripping.com"
}


