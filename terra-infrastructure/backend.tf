# store the terraform state file in s3 and lock with dynamodb
terraform {
  backend "s3" {
    bucket         = "devops-capstone"
    key            = "/demo/backend/terraform.tfstate"
    region         = "us-east-1"
    profile        = "capstone"
    encrypt        = true
    use_lockfile   = true
  }
}