data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow app traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb.id]
    description              = "HTTP from ALB"
  }

  dynamic "ingress" {
    for_each = var.key_name != "" && var.allow_ssh_cidr != "" ? [1] : []

    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.allow_ssh_cidr]
      description = "Optional SSH access"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-ec2-sg" })
}

locals {
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    ansible_repo_url        = var.ansible_repo_url
    ansible_repo_branch     = var.ansible_repo_branch
    db_host                 = aws_db_instance.magento.address
    db_name                 = var.db_name
    db_username             = var.db_username
    db_password             = var.db_password
    magento_base_url        = var.magento_base_url != "" ? var.magento_base_url : "http://${aws_lb.app.dns_name}"
    magento_backend_frontname = var.magento_backend_frontname
    magento_admin_email       = var.magento_admin_email
    magento_admin_firstname   = var.magento_admin_firstname
    magento_admin_lastname    = var.magento_admin_lastname
    magento_admin_username    = var.magento_admin_username
    magento_admin_password    = var.magento_admin_password
    magento_public_key        = var.magento_public_key
    magento_private_key       = var.magento_private_key
  })
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = base64encode(local.user_data)

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${var.project_name}-app"
      Role = "magento-app"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(local.common_tags, { Name = "${var.project_name}-root" })
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [for subnet in aws_subnet.public : subnet.id]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}
