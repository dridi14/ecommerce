output "alb_dns_name" {
  description = "ALB DNS name to reach Magento."
  value       = aws_lb.app.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint."
  value       = aws_db_instance.magento.address
}

output "vpc_id" {
  description = "VPC identifier."
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "Public subnet IDs."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "opensearch_endpoint" {
  description = "OpenSearch endpoint."
  value       = aws_opensearch_domain.main.endpoint
}
