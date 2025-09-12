# Configure the Terraform AWS provider with version constraint
terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
        }
       
    }
}

# Configure the AWS Provider for us-east-1 region in aws provider block the access key and secret key are picked from environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
provider "aws" {
  region = "us-east-1"
  
}

