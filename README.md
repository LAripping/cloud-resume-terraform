# Terraforming My Cloud Resume

The terraform code to deploy my Cloud Resume application
The pure-TF website can be found under https://resume.tf.laripping.com/ 

This repo bundles the frontend and backend repos as submodules, so that Terraform can make modifications locally and push it to the deployed AWS resources. 

## Build
 
1. `git clone --recurse-submodules https://github.com/laripping/cloud-resume-terraform`
2. Assuming an authenticated AWS CLI (e.g. by means of an `~/.aws/credentials` profile)
3. Export the profile in-use through the `AWS_PROFILE` environment variable for TF to pick up
4. `terraform init`
5. `terraform apply`