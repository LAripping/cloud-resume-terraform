resource "aws_api_gateway_rest_api" "api" {
  name = "tf-api"
}

resource "aws_api_gateway_resource" "api_res" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "fetch-update-visitor-count"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "api_method" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.api_res.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_integration" "api_int" {
  http_method = aws_api_gateway_method.api_method.http_method
  resource_id = aws_api_gateway_resource.api_res.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  type        = "AWS_PROXY"
  integration_http_method = "GET"
  uri         = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "api_depl" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api_res.id,
      aws_api_gateway_method.api_method.id,
      aws_api_gateway_integration.api_int.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stg" {
  deployment_id = aws_api_gateway_deployment.api_depl.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "Prod"
}