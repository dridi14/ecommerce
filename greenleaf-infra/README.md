# GreenLeaf – Magento on AWS (HA)

Terraform builds a minimal-but-HA Magento stack (VPC, ALB, ASG, RDS). Ansible installs Nginx/PHP/Magento on Ubuntu 22.04 via EC2 user-data.

## What’s included
- VPC with 2 public subnets (multi-AZ), IGW, route tables.
- Security groups: ALB (80/443 from Internet), EC2 (80 from ALB, SSH optional), RDS (3306 from EC2).
- ALB + Target Group + Listener 80.
- Launch Template + ASG (min/des=1, max=2) with user-data running Ansible from this repo.
- RDS MySQL 8 (non-public, Multi-AZ configurable).
- IAM role/profile for EC2 (AmazonSSMManagedInstanceCore) and CPU alarm.
- Ansible roles: common, php (8.2), nginx, magento (2.4.7-p1 via repo.magento.com).
- Scripts: bootstrap/destroy/validate.

## Quick start
```bash
cd greenleaf-infra/terraform
export TF_VAR_db_password='Drudu==!!123'
export TF_VAR_magento_admin_password='Drudu==!!123'
export TF_VAR_magento_public_key='6f5807b97f3c153692a03a6e80a0f7a7'
export TF_VAR_magento_private_key='b097fcae7ac58f93d6861afc5b369ce1'
# optional: export TF_VAR_magento_base_url="http://my-custom-domain"
# required: export TF_VAR_ansible_repo_url="https://github.com/<you>/greenleaf-infra.git"   # user-data clones this
terraform init
terraform apply
```
or run `../scripts/bootstrap.sh`.

Retrieve endpoints:
```bash
terraform output -raw alb_dns_name
terraform output -raw rds_endpoint
```
Validate: `../scripts/validate.sh`

Magento should be reachable at `http://<alb_dns_name>` once user-data finishes (check `/var/log/user-data.log` on the instance).

## Customization
- Size: `instance_type`, `db_instance_class`, `max_size` in `asg.tf`.
- HA DB: toggle `rds_multi_az` (default true).
- SSH: set `key_name` + `allow_ssh_cidr`.
- Ansible source: `ansible_repo_url`/`ansible_repo_branch` (defaults to this repo).
- Magento base URL: set `magento_base_url` (falls back to `http://<alb_dns_name>`).

## Secrets
Never commit secrets. Provide via:
- `terraform.tfvars` (see `terraform.tfvars.example`)
- or environment variables `TF_VAR_db_password`, `TF_VAR_magento_admin_password`, etc.

## Repo structure
- `terraform/` infrastructure definitions + user_data template.
- `ansible/` playbooks, roles, templates, group_vars example.
- `docs/` DAT, FINOPS, DEPLOYMENT_GUIDE.
- `scripts/` automation helpers.

## Notes
- Default deployment is HTTP-only. Add ACM cert + HTTPS listener for production.
- Magento install uses repo.magento.com with Marketplace keys in `/root/.composer/auth.json`.
- Instances are in public subnets with public IPs for simplicity; add private subnets + NAT if stronger isolation is needed.
