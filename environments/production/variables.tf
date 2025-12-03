variable "region" {
	type    = string
	default = "eu-west-2"
}

variable "enable_rds" {
	type    = bool
	default = true
}

variable "enable_sqs" {
	type    = bool
	default = true
}

variable "enable_cloudfront" {
	type    = bool
	default = true
}

variable "enable_waf" {
	type    = bool
	default = true
}

variable "enable_ses" {
	type    = bool
	default = true
}

variable "enable_nat" {
	type    = bool
	default = true
}

variable "frontend_desired_count" {
	type    = number
	default = 2
}

variable "backend_desired_count" {
	type    = number
	default = 2
}

variable "admin_desired_count" {
	type    = number
	default = 1
}

variable "frontend_cpu" {
	type    = number
	default = 512
}

variable "frontend_memory" {
	type    = number
	default = 1024
}

variable "backend_cpu" {
	type    = number
	default = 512
}

variable "backend_memory" {
	type    = number
	default = 1024
}

variable "admin_cpu" {
	type    = number
	default = 512
}

variable "admin_memory" {
	type    = number
	default = 1024
}

variable "domain_name" {
	type    = string
	default = "clientdomain.com"
}

variable "create_hosted_zone" {
	type    = bool
	default = true
}

variable "app_name" {
	type    = string
	default = "travel365"
}

variable "environment" {
	type    = string
	default = "production"
}

variable "public_subnet_cidrs" {
	type    = list(string)
	default = ["10.0.1.0/24","10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
	type    = list(string)
	default = ["10.0.11.0/24","10.0.12.0/24"]
}

variable "db_username" {
	type    = string
	default = ""
}

variable "db_password" {
	type    = string
	default = ""
}

variable "frontend_image" {
	type    = string
	default = ""
}

variable "backend_image" {
	type    = string
	default = ""
}

variable "admin_image" {
	type    = string
	default = ""
}

