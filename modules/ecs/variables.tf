variable "name" {
	type = string
}

variable "cluster_name" {
	type = string
}

variable "frontend_image" {
	type = string
}

variable "backend_image" {
	type = string
}

variable "admin_image" {
	type = string
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

variable "frontend_desired_count" {
	type    = number
	default = 1
}

variable "backend_desired_count" {
	type    = number
	default = 1
}

variable "admin_desired_count" {
	type    = number
	default = 0
}

variable "enable_autoscaling" {
	type    = bool
	default = false
}

variable "execution_role_arn" {
	type = string
}

variable "task_role_arn" {
	type = string
}

variable "subnet_ids" {
	type = list(string)
}

variable "security_groups" {
	type = list(string)
}

variable "target_group_arns" {
	description = "Map of ALB target group ARNs (keys should match target_groups keys in alb module, e.g. frontend, backend, admin)"
	type = map(string)
	default = {}
}

variable "region" {
	type    = string
	default = "eu-west-2"
}

variable "tags" {
	type    = map(string)
	default = {}
}
