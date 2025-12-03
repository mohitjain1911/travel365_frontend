terraform {
  backend "s3" {
    # Replace these placeholders with your real backend resources
    bucket         = "REPLACE_WITH_YOUR_TFSTATE_BUCKET"
    key            = "travel365/production/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "REPLACE_WITH_YOUR_DYNAMODB_TABLE"
    encrypt        = true
  }
}
