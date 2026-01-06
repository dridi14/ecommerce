# Guide de déploiement

## Prérequis
- AWS CLI configuré (`aws configure`) avec un rôle/compte disposant des droits VPC/EC2/RDS/IAM/ALB.
- Terraform >= 1.6.
- Ansible (optionnel si vous laissez user-data tout gérer).
- Cloner ce dépôt et se placer dans `greenleaf-infra/terraform`.
- Mettre à disposition ce dépôt dans un repo Git accessible par les instances (HTTPS) et renseigner `ansible_repo_url`.

## Variables sensibles
Définir au minimum :
- `db_password`
- `magento_admin_password`

Options : `key_name`, `allow_ssh_cidr`, `magento_base_url`, `rds_multi_az`, `ansible_repo_url`.

Vous pouvez créer un fichier `terraform.tfvars` (non commité) ou exporter des variables d’environnement `TF_VAR_*`.

## Déploiement
```bash
cd greenleaf-infra/terraform
terraform init
terraform apply
```
ou via script :
```bash
../scripts/bootstrap.sh
```

## Récupérer les sorties
```bash
terraform output
terraform output -raw alb_dns_name
terraform output -raw rds_endpoint
```

## Validation
- Attendre quelques minutes que l’instance termine sa configuration Ansible (cf `/var/log/user-data.log` sur l’instance ou SSM).
- Tester : `../scripts/validate.sh`
- Ouvrir `http://<alb_dns_name>` dans un navigateur.

## Mise à jour / redéploiement
- Modifier les variables Terraform puis `terraform apply`.
- Pour mise à jour Ansible/Magento : pousser vos changements dans la branche utilisée par `ansible_repo_url`. Les nouvelles instances appliqueront automatiquement. Pour forcer une instance existante, exécuter manuellement Ansible sur l’instance ou recyclez l’ASG.

## Destruction
```bash
cd greenleaf-infra/terraform
terraform destroy
```
ou `../scripts/destroy.sh`.
