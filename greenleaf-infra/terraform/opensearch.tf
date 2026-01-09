resource "aws_security_group" "opensearch" {
  name        = "${var.project_name}-opensearch-sg"
  description = "Allow OpenSearch from app servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "HTTPS from app SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-opensearch-sg" })
}

data "aws_iam_policy_document" "opensearch_access" {
  statement {
    actions   = ["es:*"]
    resources = ["${aws_opensearch_domain.main.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_opensearch_domain" "main" {
  domain_name    = "${var.project_name}-search"
  engine_version = var.opensearch_engine_version

  cluster_config {
    instance_type          = var.opensearch_instance_type
    instance_count         = 1
    dedicated_master_enabled = false
    zone_awareness_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.opensearch_volume_size
    volume_type = "gp3"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
  }

  vpc_options {
    subnet_ids         = [for subnet in aws_subnet.public : subnet.id][0:1]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-opensearch" })
}

resource "aws_opensearch_domain_policy" "main" {
  domain_name     = aws_opensearch_domain.main.domain_name
  access_policies = data.aws_iam_policy_document.opensearch_access.json
}
