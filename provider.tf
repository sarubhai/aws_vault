# Name: provider.tf
# Owner: Saurav Mitra
# Description: This terraform config will Configure Terraform Providers
# https://www.terraform.io/docs/language/providers/requirements.html

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure Terraform AWS Provider
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs

# $ export AWS_ACCESS_KEY_ID="AccessKey"
# $ export AWS_SECRET_ACCESS_KEY="SecretKey"
# $ export AWS_DEFAULT_REGION="us-west-2"

provider "aws" {
  # Configuration options
}
