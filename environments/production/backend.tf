terraform {
  backend "s3" {
    bucket         = "<REPLACE_WITH_STATE_BUCKET>"
    key            = "travel365/production/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "<REPLACE_WITH_DYNAMODB_TABLE>"
    encrypt        = true
  }
}
