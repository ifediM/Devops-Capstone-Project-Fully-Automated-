########################################################################################
# GitHub OIDC Configuration
########################################################################################

# Fetch AWS account ID dynamically
data "aws_caller_identity" "current" {}

# OIDC Identity Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f"] 
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        StringLike = {
          "token.actions.githubusercontent.com:sub": "repo:ifediM/Devops-Capstone-Project-Fully-Automated-:*"
        }
      }
    }]
  })
}

# --- NEW: S3 Backend Specific Policy ---
resource "aws_iam_role_policy" "s3_backend_access" {
  name = "terraform-s3-backend-permissions"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission to see the bucket and check its region
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::devops-capstone"
      },
      {
        # Permission to read/write/check the state file
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:HeadObject" 
        ]
        Resource = "arn:aws:s3:::devops-capstone/demo/backend/terraform.tfstate"
      }
    ]
  })
}

# Attach AdministratorAccess
resource "aws_iam_role_policy_attachment" "attach_github_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}