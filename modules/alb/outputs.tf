output "alb_arn" { value = aws_lb.alb.arn }
output "alb_dns_name" { value = aws_lb.alb.dns_name }

# Map of target group ARNs by key from var.target_groups (eg. frontend, backend, admin)
output "target_group_arns" {
	value = { for k, v in aws_lb_target_group.tgs : k => v.arn }
}
