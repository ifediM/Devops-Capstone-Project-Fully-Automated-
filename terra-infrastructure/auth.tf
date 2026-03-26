########################################################################################
# GitHub OIDC Configuration
########################################################################################

# Fetch AWS account ID dynamically
data "aws_caller_identity" "current" {}

# OIDC Identity Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f"] # GitHub OIDC cert thumbprint
}

# IAM Role for GitHub Actions
#resource "aws_iam_role" "github_actions" {
#  name = var.iam_role_name

#  assume_role_policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [{
#      Effect = "Allow",
#      Principal = {
#        Federated = "arn:aws:iam::087097353362:oidc-provider/token.actions.githubusercontent.com"
#      },
#      Action = "sts:AssumeRoleWithWebIdentity",
#      Condition = {
#        StringLike = {
#          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
#        }
#      }
#    }]
#  })
#}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        # Using the dynamic account ID from your data source
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        # CRITICAL: AWS usually requires the Audience (aud) to be verified
        StringEquals = {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        # Ensure the repo path is exact (Case Sensitive!)
        StringLike = {
          "token.actions.githubusercontent.com:sub": "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })
}

# Attach AWS-managed AdministratorAccess policy to Role
resource "aws_iam_role_policy_attachment" "attach_github_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}