# Terraforming My Cloud Resume

The terraform code to deploy my Cloud Resume application
The pure-TF clone can be found under https://resume.tf.laripping.com/ 

## Build

0. Assuming an authenticated AWS CLI (e.g. by means of an `~/.aws/credentials` profile)
1. Export the profile in-use through the `AWS_PROFILE` environment variable for TF to pick up
2. `git clone frontend` ...so that TF grabs the (local) HTML code to push to the S3 Bucket 
3. `git clone backend` ...so that TF grabs the (local) Python code to push to the Lambda
4. `terraform init`
5. `terraform apply`