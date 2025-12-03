terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional remote state backend (S3 + DynamoDB) - configure if you want:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "travel-website/production/terraform.tfstate"
  #   region         = "eu-west-2"
  #   dynamodb_table = "terraform-lock-table"
  #   encrypt        = true
  # }
}
