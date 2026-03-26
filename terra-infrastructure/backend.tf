# store the terraform state file in s3 and lock with dynamodb
terraform {
  backend "s3" {
    bucket         = "devops-capstone"
    key            = "terraform_module/qr-code/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}