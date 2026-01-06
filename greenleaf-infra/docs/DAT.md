# GreenLeaf – Document d’Architecture Technique

## Vue d’ensemble
GreenLeaf déploie Magento Open Source sur AWS avec Terraform et Ansible. L’application tourne sur des instances EC2 derrière un Application Load Balancer (ALB) réparti sur deux AZ. Une base RDS MySQL héberge les données. L’initialisation applicative est automatisée via user-data + Ansible.

## Diagramme (Mermaid)
```mermaid
flowchart TB
  Internet --> ALB[ALB (multi-AZ)]
  subgraph VPC[10.0.0.0/16]
    ALB --> ASG[Auto Scaling Group\nEC2 Ubuntu 22.04 + Nginx/PHP/Magento]
    ASG --> RDS[(RDS MySQL)]
  end
```

## Composants
- **Réseau** : VPC /16, 2 sous-réseaux publics (multi-AZ), IGW, tables de routage publiques.
- **Sécurité** : SG ALB (80/443 depuis Internet), SG EC2 (80 depuis ALB, SSH optionnel), SG RDS (3306 depuis EC2).
- **Compute** : Launch Template Ubuntu 22.04, ASG min=1/désiré=1/max=2, user-data déclenchant Ansible.
- **Equilibrage** : ALB HTTP:80, cible EC2, health check `/`.
- **Base de données** : RDS MySQL 8, Multi-AZ configurable, non accessible publiquement.
- **Observabilité** : Alarme CloudWatch CPU haute sur l’ASG.
- **IAM** : Rôle EC2 avec AmazonSSMManagedInstanceCore.

## Sécurité
- Pas de secrets en dur : mots de passe fournis via variables Terraform/Ansible.
- RDS non exposé publiquement ; accès limité au SG des app servers.
- SSH désactivé par défaut (key_name vide). Autoriser une CIDR précise si nécessaire.
- User-data loggé dans `/var/log/user-data.log` pour audit. Packages installés depuis dépôts officiels.
- ALB écoute en HTTP par défaut ; ajouter HTTPS (cert ACM + listener 443) pour prod.

## Disponibilité & Scalabilité
- ALB + ASG sur 2 AZ pour tolérance aux pannes de zone.
- ASG peut être augmenté (max, desired) et couplé à policies sur CPU/ALB si besoin.
- RDS : option Multi-AZ (variable `rds_multi_az`) pour bascule automatique.
- Stateless web tier ; reconfiguration idempotente via Ansible lors du lancement d’instance.

## Flux de trafic
1. Requêtes clientes atteignent l’ALB en HTTP.
2. ALB répartit sur les instances EC2 saines (health check `/`).
3. Nginx sert Magento/PHP-FPM ; Magento lit/écrit dans RDS MySQL.
4. Logs système disponibles localement ; SSM peut être utilisé pour support.
