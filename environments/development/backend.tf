terraform {
	backend "s3" {
		# Replace these placeholders with your real backend resources
		bucket         = "tfstate-bucket-travel365"
		key            = "travel365/development/terraform.tfstate"
		region         = "eu-west-2"
		dynamodb_table = "tfstate-bucket-travel365"
		encrypt        = true
	}
}

