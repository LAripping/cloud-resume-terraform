resource "null_resource" "replace_api" {
  # Changes to the API Gateway URL triggers re-provisioning
  triggers = {
    api_url = aws_api_gateway_deployment.api_depl.invoke_url
  }

  provisioner "local-exec" {
    # interpreter = [""]
    command = join("",[
                "python3 ./replace-api-url.py cloud-resume-frontend/assets/js/api.js ", 
                aws_api_gateway_deployment.api_depl.invoke_url
            ])
  }
}