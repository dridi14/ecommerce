variable "project_name" {
  description = "Project name tag prefix."
  type        = string
  default     = "greenleaf"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs (must match availability_zones order)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for Magento app."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional SSH key pair name. Leave empty to disable SSH."
  type        = string
  default     = ""
}

variable "allow_ssh_cidr" {
  description = "CIDR allowed to SSH to instances when key_name is set."
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Magento database name."
  type        = string
  default     = "magento"
}

variable "db_username" {
  description = "Master username for RDS."
  type        = string
  default     = "magento"
}

variable "db_password" {
  description = "Master password for RDS."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB."
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ RDS deployment."
  type        = bool
  default     = true
}

variable "magento_base_url" {
  description = "Base URL for Magento (e.g., http://your-alb-dns-name)."
  type        = string
  default     = ""
}

variable "ansible_repo_url" {
  description = "Git URL for Ansible playbooks to run from user data."
  type        = string
  default     = "https://github.com/example/greenleaf-infra.git"
}

variable "ansible_repo_branch" {
  description = "Branch of the Ansible repo to use."
  type        = string
  default     = "main"
}

variable "magento_admin_email" {
  description = "Magento admin email."
  type        = string
  default     = "admin@example.com"
}

variable "magento_admin_firstname" {
  description = "Magento admin first name."
  type        = string
  default     = "Admin"
}

variable "magento_admin_lastname" {
  description = "Magento admin last name."
  type        = string
  default     = "User"
}

variable "magento_admin_password" {
  description = "Magento admin password."
  type        = string
  sensitive   = true
}

variable "magento_admin_username" {
  description = "Magento admin username."
  type        = string
  default     = "admin"
}

variable "magento_backend_frontname" {
  description = "Magento admin path."
  type        = string
  default     = "admin"
}

variable "availability_zones" {
  description = "Optional list of AZs to use. Leave empty to pick first two automatically."
  type        = list(string)
  default     = []
}
