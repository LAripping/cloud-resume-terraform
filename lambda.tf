# TODO find a way to get these from state instead 
data "aws_caller_identity" "personal" {}
data "aws_region" "crc_region" {}


locals {
  account_id = data.aws_caller_identity.personal.account_id
  region = data.aws_region.crc_region.name
}

data "archive_file" "lambda_archive" {
  type = "zip"
  source_dir  = "${path.module}/cloud-resume-backend/fetch_visitors"
  output_path = "${path.module}/fetch_visitors.zip"
}


resource "aws_lambda_function" "lambda" {
  filename      = "fetch_visitors.zip"
  function_name = "fetch_visitors"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.8"

  source_code_hash = data.archive_file.lambda_archive.output_base64sha256

  environment {
      variables = {
        APP_URL     = join("",[
          "https://",
          local.resume_subdomain,
          local.domain_name]),
        TABLE_NAME  = aws_dynamodb_table.db.name
      }
    }
}

# policy allowing the API Gateway to execute the Lambda function
resource "aws_lambda_permission" "lambda_perm" {
  statement_id  = "statement-AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.api_method.http_method}${aws_api_gateway_resource.api_res.path}"
}

## The Lambda's IAM role, incl. the 2 policies:
# 1. trust policy: who can assume that role
# 2. permissions:  what the role is allowed to do
resource "aws_iam_role" "lambda_role" {
  name = "tf-lambda-role"

  # 1
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json

  # 2 - consiting in turn of 
  #   + a managed policy (to allow logging etc) 
  #   + an inline policy (to allow DB ops)
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  inline_policy {
    name = "db-ops-policy"
    policy = data.aws_iam_policy_document.db_ops_inline_policy.json
  }


}



data "aws_iam_policy_document" "trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}


data "aws_iam_policy_document" "db_ops_inline_policy" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:Scan"
    ]

    resources = [
      "arn:aws:dynamodb:${local.region}:${local.account_id}:table/${aws_dynamodb_table.db.name}"
    ]

    
  }
}
