#Environment variables
variable "region" {}
variable "project_name" {}
variable "environment" {}

#vpc variables
variable "vpc_cidr" {}
variable "public_subnet_az1_cidr" {}
variable "public_subnet_az2_cidr" {}
variable "private_app_subnet_az1_cidr" {}
variable "private_app_subnet_az2_cidr" {}


#Security-group variables
variable "ssh_ip" {}

#Amazon cert manager variables
variable "domain_name" {}
variable "alternative_names" {}

#OIDC variables
variable "iam_role_name" {}
variable "github_org" {}
variable "github_repo" {}


variable "record_name" {}
variable "target_type" {}




