# Document d'Architecture Technique (DAT)

**Projet :** GreenLeaf - Plateforme E-commerce Magento sur AWS

**Auteurs :** Équipe Infrastructure GreenLeaf

**Date :** 2024

**Version :** 1.0

## 1. Introduction

Ce document présente l'architecture technique de la plateforme e-commerce GreenLeaf, déployée sur Amazon Web Services (AWS). L'objectif est de fournir une infrastructure hautement disponible, scalable et sécurisée pour héberger une application Magento Open Source 2.4.7-p1.

Le besoin initial de la startup GreenLeaf est de disposer d'une plateforme e-commerce robuste capable de gérer la croissance du trafic tout en maintenant des coûts maîtrisés. La mission de l'équipe infrastructure est de concevoir et déployer une architecture cloud-native utilisant les meilleures pratiques AWS, avec une automatisation complète via Infrastructure as Code (Terraform) et Configuration Management (Ansible).

Cette architecture répond aux exigences de haute disponibilité en répartissant les ressources sur plusieurs zones de disponibilité (AZ), de scalabilité grâce à l'Auto Scaling Group, et de sécurité via des groupes de sécurité restrictifs et des rôles IAM avec principe du moindre privilège.

## 2. Vue d'Ensemble de l'Architecture

### 2.1. Schéma d'Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ HTTP (80) / HTTPS (443)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Application Load Balancer (ALB)                 │
│              - Multi-AZ (2 zones de disponibilité)          │
│              - Security Group: 80/443 depuis Internet        │
│              - Health Check: HTTP / (interval: 30s)         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ HTTP (80) depuis ALB SG
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Auto Scaling Group (ASG)                         │
│  ┌────────────────────┐      ┌────────────────────┐        │
│  │  EC2 Instance 1    │      │  EC2 Instance 2    │        │
│  │  - t3.micro        │      │  - t3.micro        │        │
│  │  - Ubuntu 22.04    │      │  - Ubuntu 22.04    │        │
│  │  - Nginx           │      │  - Nginx           │        │
│  │  - PHP 8.2-FPM     │      │  - PHP 8.2-FPM     │        │
│  │  - Magento 2.4.7   │      │  - Magento 2.4.7   │        │
│  │  - Public Subnet 1 │      │  - Public Subnet 2 │        │
│  └────────────────────┘      └────────────────────┘        │
│              Min: 1 | Desired: 1 | Max: 2                   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ MySQL (3306) depuis EC2 SG
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Amazon RDS MySQL 8.0                           │
│              - db.t3.micro                                  │
│              - Multi-AZ: Activé (par défaut)                │
│              - Storage: 20 GB                                │
│              - Non accessible publiquement                  │
│              - Security Group: 3306 depuis EC2 SG           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              VPC (10.0.0.0/16)                              │
│  ┌────────────────────┐      ┌────────────────────┐        │
│  │  Public Subnet 1   │      │  Public Subnet 2   │        │
│  │  10.0.1.0/24       │      │  10.0.2.0/24       │        │
│  │  AZ-1              │      │  AZ-2              │        │
│  │  - ALB             │      │  - ALB             │        │
│  │  - EC2 Instances   │      │  - EC2 Instances   │        │
│  │  - RDS (optionnel) │      │  - RDS (optionnel) │        │
│  └────────────────────┘      └────────────────────┘        │
│                                                              │
│  Internet Gateway (IGW)                                     │
│  - Route: 0.0.0.0/0 → IGW                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              CloudWatch                                     │
│              - Alarm: CPU > 70% (2 périodes de 5 min)      │
│              - Métriques: EC2, RDS, ALB                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              IAM                                            │
│              - Role: EC2 Instance Role                      │
│              - Policy: AmazonSSMManagedInstanceCore         │
│              - Instance Profile attaché aux EC2             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2. Justification des Choix d'Architecture

**Architecture multi-AZ pour haute disponibilité :** L'infrastructure est déployée sur deux zones de disponibilité distinctes pour garantir la résilience en cas de panne d'une zone. L'ALB répartit automatiquement le trafic entre les instances saines, et RDS Multi-AZ assure la continuité de service de la base de données avec un basculement automatique en cas d'incident.

**Auto Scaling Group pour scalabilité :** L'ASG permet d'ajuster dynamiquement le nombre d'instances selon la charge (actuellement configuré avec min=1, desired=1, max=2). Cette approche permet de démarrer avec un coût minimal tout en conservant la capacité de monter en charge rapidement. Les instances sont stateless (pas de stockage local persistant), ce qui facilite leur remplacement et leur duplication.

**Séparation des couches (tier architecture) :** L'architecture sépare clairement la couche présentation (EC2 avec Nginx/PHP/Magento), la couche équilibrage (ALB), et la couche données (RDS). Cette séparation améliore la sécurité (isolation réseau via Security Groups), facilite la maintenance et permet l'optimisation indépendante de chaque couche.

**Infrastructure as Code (Terraform) :** L'utilisation de Terraform garantit la reproductibilité, la traçabilité des changements, et facilite la gestion de l'infrastructure. Tous les composants sont définis de manière déclarative, permettant un déploiement cohérent et la gestion des versions.

**Configuration Management (Ansible) :** Ansible est utilisé pour automatiser l'installation et la configuration de l'application Magento sur les instances EC2. L'exécution via user-data garantit que chaque nouvelle instance est automatiquement configurée de manière identique, assurant la cohérence et réduisant les erreurs manuelles.

**Choix de services AWS managés :** L'utilisation de RDS (au lieu d'EC2 auto-gérées) réduit la charge opérationnelle pour la gestion de la base de données (backups, patching, monitoring). L'ALB fournit un équilibrage de charge de niveau 7 avec health checks intégrés, SSL/TLS termination, et intégration native avec Auto Scaling.

## 3. Description Détaillée des Services

### 3.1. Réseau

**CIDR Block :** `10.0.0.0/16`

**Sous-réseaux :**

| Nom | CIDR | Type | Zone de Disponibilité | Usage |
|-----|------|------|----------------------|-------|
| Public Subnet 1 | `10.0.1.0/24` | Public | AZ-1 (première AZ disponible) | ALB, EC2 Instances, RDS |
| Public Subnet 2 | `10.0.2.0/24` | Public | AZ-2 (deuxième AZ disponible) | ALB, EC2 Instances, RDS |

**Tables de Routage :**

- **Public Route Table :** Route par défaut `0.0.0.0/0` vers l'Internet Gateway (IGW)
  - Associée aux deux sous-réseaux publics
  - Permet l'accès Internet sortant et l'attribution d'adresses IP publiques

**Internet Gateway / NAT Gateway :**

- **Internet Gateway (IGW) :** Configuré et attaché au VPC
  - Permet la communication bidirectionnelle avec Internet
  - Nécessaire pour l'ALB (externe) et les instances EC2 dans les sous-réseaux publics
- **NAT Gateway :** Non utilisé dans cette architecture
  - **Justification :** Les instances EC2 sont déployées dans des sous-réseaux publics avec des adresses IP publiques. Bien qu'une architecture avec sous-réseaux privés + NAT Gateway soit plus sécurisée, l'approche actuelle réduit les coûts (pas de frais de NAT Gateway) et simplifie la configuration pour un environnement de développement/staging. Pour la production, il est recommandé d'ajouter des sous-réseaux privés avec NAT Gateway pour une meilleure isolation.

**DNS :**
- DNS Support : Activé (`enable_dns_support = true`)
- DNS Hostnames : Activé (`enable_dns_hostnames = true`)

### 3.2. Calcul (EC2 & Auto Scaling)

**Type d'instance :** `t3.micro`

**Justification du choix :**
- **Performance vs. Coût :** Le type `t3.micro` offre un bon équilibre pour un environnement de développement/staging ou une petite production. Il fournit 2 vCPU, 1 GB de RAM, et un crédit CPU burstable, suffisant pour Magento avec un trafic modéré. Pour la production avec trafic élevé, il est recommandé de passer à `t3.small` (2 vCPU, 2 GB RAM) ou `t3.medium` (2 vCPU, 4 GB RAM).
- **Coût :** Environ $0.0104/heure (~$7.50/mois) par instance, permettant de démarrer avec un budget maîtrisé.
- **Scalabilité :** L'ASG permet de monter en charge en ajoutant des instances ou en changeant le type d'instance via le Launch Template.

**AMI utilisée :** Ubuntu 22.04 LTS (Jammy Jellyfish)
- Source : Canonical (`099720109477`)
- Filtre : `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*`
- **Justification :** Ubuntu 22.04 LTS est une distribution stable, bien supportée, avec une large communauté et une excellente compatibilité avec les outils DevOps (Ansible, Terraform). Support LTS jusqu'en 2027.

**Configuration du Groupe Auto Scaling :**

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| Min Size | 1 | Nombre minimum d'instances garanties |
| Desired Capacity | 1 | Nombre d'instances cible au démarrage |
| Max Size | 2 | Nombre maximum d'instances autorisées |
| Health Check Type | EC2 | Vérifie l'état de santé des instances EC2 |
| Health Check Grace Period | 300 secondes | Délai avant de considérer une instance comme non saine |
| VPC Zone Identifier | 2 sous-réseaux publics | Répartition sur 2 AZ pour haute disponibilité |

**Politique de scaling :**
- Actuellement, aucune politique de scaling automatique n'est configurée (scaling manuel uniquement)
- **Recommandation pour production :** Ajouter des policies basées sur :
  - CPU Utilization (ex: scale out si CPU > 70% pendant 5 minutes)
  - ALB Request Count (ex: scale out si > 1000 requêtes/min)
  - ALB Target Response Time (ex: scale out si > 2 secondes)

**Modèle de Lancement (Launch Template) :**

**User Data Script :** Le script `user_data.sh.tpl` exécute les étapes suivantes lors du démarrage de l'instance :

1. **Installation des dépendances système :**
   - Mise à jour des packages (`apt-get update`)
   - Installation de Git, Python3, pip3

2. **Installation d'Ansible :**
   - Installation d'Ansible 2.15+ via pip3

3. **Clonage du repository Ansible :**
   - Clone du repository Git contenant les playbooks Ansible
   - URL et branche configurables via variables Terraform

4. **Création de l'inventaire Ansible :**
   - Inventaire local (`localhost ansible_connection=local`)

5. **Configuration des variables Ansible :**
   - Création de `group_vars/all.yml` avec :
     - Paramètres Magento (base URL, admin credentials)
     - Paramètres de base de données (host, name, credentials)

6. **Exécution du playbook Ansible :**
   - Exécution de `playbooks/site.yml` qui installe :
     - Packages système communs (role: common)
     - PHP 8.2-FPM avec extensions Magento (role: php)
     - Nginx avec configuration Magento (role: nginx)
     - Magento 2.4.7-p1 via Composer (role: magento)

**IAM Instance Profile :**
- Rôle IAM attaché : `greenleaf-ec2-role`
- Permissions : `AmazonSSMManagedInstanceCore` (accès SSM Session Manager pour support à distance sans SSH)

**Network Interfaces :**
- `associate_public_ip_address = true` : Attribution automatique d'une adresse IP publique
- Security Group : `greenleaf-ec2-sg` (détaillé en section 4.1)

**Tagging :**
- Tags appliqués : `Project`, `Name`, `Role` (magento-app)
- Tags propagés aux volumes EBS

### 3.3. Équilibrage de Charge

**Type :** Application Load Balancer (ALB) - Niveau 7 (HTTP/HTTPS)

**Listeners :**

| Port | Protocole | Action | Description |
|------|-----------|--------|-------------|
| 80 | HTTP | Forward vers Target Group | Écoute HTTP, redirige vers les instances EC2 |

**Note :** HTTPS (port 443) n'est pas configuré par défaut. Pour la production, il est recommandé d'ajouter :
- Un certificat ACM (Amazon Certificate Manager)
- Un listener HTTPS (443) avec redirection HTTP → HTTPS

**Règles de routage :**
- **Règle par défaut :** Toutes les requêtes HTTP (port 80) sont routées vers le Target Group `greenleaf-tg`

**Configuration du Groupe Cible (Target Group) :**

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| Nom | `greenleaf-tg` | Identifiant du groupe cible |
| Protocole | HTTP | Protocole de communication avec les instances |
| Port | 80 | Port d'écoute sur les instances EC2 |
| Target Type | Instance | Cible directe : instances EC2 |
| VPC | VPC principal | Réseau dans lequel les instances sont déployées |

**Health Checks :**

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| Path | `/` | Chemin de vérification de santé |
| Protocol | HTTP | Protocole du health check |
| Port | traffic-port | Utilise le port du Target Group (80) |
| Healthy Threshold | 2 | Nombre de checks réussis consécutifs pour marquer "healthy" |
| Unhealthy Threshold | 5 | Nombre de checks échoués consécutifs pour marquer "unhealthy" |
| Timeout | 5 secondes | Délai d'attente pour une réponse |
| Interval | 30 secondes | Intervalle entre les health checks |
| Success Codes | 200-399 | Codes HTTP considérés comme sains |

**Stickiness (Session Affinity) :** Non configurée (par défaut, répartition round-robin)

**Deregistration Delay :** 300 secondes (délai avant déconnexion lors du scale-in)

**Security Group :**
- `greenleaf-alb-sg` : Autorise le trafic entrant sur les ports 80 (HTTP) et 443 (HTTPS) depuis Internet (`0.0.0.0/0`)

### 3.4. Base de Données

**Moteur et version :** MySQL 8.0

**Justification :**
- MySQL 8.0 est la version recommandée par Magento 2.4.x
- Performances améliorées, support JSON natif, meilleure sécurité
- Compatibilité complète avec toutes les fonctionnalités Magento

**Type d'instance :** `db.t3.micro`

**Justification :**
- **Performance :** 2 vCPU, 1 GB RAM, adapté pour développement/staging ou petite production
- **Coût :** Environ $0.017/heure (~$12.24/mois) pour une instance Single-AZ, ~$24.48/mois pour Multi-AZ
- **Scalabilité :** Possibilité de modifier le type d'instance (modify) sans interruption pour Single-AZ, avec interruption minimale pour Multi-AZ
- **Recommandation production :** `db.t3.small` (2 vCPU, 2 GB RAM) ou `db.t3.medium` (2 vCPU, 4 GB RAM) selon le volume de données et le trafic

**Configuration Multi-AZ :** Activée (par défaut : `rds_multi_az = true`)

**Justification :**
- **Haute disponibilité :** En cas de panne de la base primaire, basculement automatique vers la base secondaire dans une autre AZ (RTO < 60 secondes)
- **Protection des données :** Réplication synchrone vers la base secondaire
- **Maintenance :** Les mises à jour de maintenance sont appliquées d'abord sur la base secondaire, puis basculement automatique
- **Coût :** Double le coût de l'instance (2x instances), mais essentiel pour la production
- **Alternative :** Pour développement/staging, peut être désactivé (`rds_multi_az = false`) pour réduire les coûts

**Stockage :**
- **Allocated Storage :** 20 GB (par défaut)
- **Storage Type :** gp3 (General Purpose SSD) - performance et coût optimisés
- **Storage Auto Scaling :** Non configuré (peut être activé pour croissance automatique)

**Backup :**
- **Backup Retention Period :** 1 jour (configurable, recommandé 7 jours pour production)
- **Backup Window :** Fenêtre de maintenance AWS (configurable)
- **Skip Final Snapshot :** `true` (pour faciliter la destruction en dev, mettre `false` en production)

**Sécurité :**
- **Publicly Accessible :** `false` - La base n'est accessible que depuis le VPC
- **Security Group :** `greenleaf-rds-sg` - Autorise uniquement le port 3306 depuis le Security Group des instances EC2
- **Subnet Group :** `greenleaf-db-subnets` - Utilise les sous-réseaux publics (pour simplifier, idéalement utiliser des sous-réseaux privés dédiés)

**Paramètres de base de données :**
- **Database Name :** `magento` (configurable via `var.db_name`)
- **Master Username :** `magento` (configurable via `var.db_username`)
- **Master Password :** Fourni via variable Terraform sensible (`var.db_password`)

**Deletion Protection :** `false` (par défaut, mettre `true` en production pour éviter les suppressions accidentelles)

### 3.5. Cache (ElastiCache)

**Statut :** Non configuré dans l'architecture actuelle

**Recommandation pour production :**
- **Moteur :** Redis 7.x
- **Type de nœud :** `cache.t3.micro` (développement) ou `cache.t3.small` (production)
- **Cas d'usage :**
  - **Cache de session Magento :** Stockage des sessions utilisateurs (panier, authentification)
  - **Cache de page :** Cache des pages générées par Magento (Full Page Cache)
  - **Cache d'objets :** Cache des résultats de requêtes complexes
- **Configuration :** Cluster mode désactivé pour début (single node), activer le cluster mode pour haute disponibilité
- **Placement :** Déployer dans des sous-réseaux privés dédiés avec Security Group autorisant uniquement les instances EC2

### 3.6. Stockage (S3)

**Statut :** Non configuré dans l'architecture actuelle

**Recommandation pour production :**
- **Nom du bucket :** `greenleaf-magento-media-{region}-{account-id}` (nom unique global)
- **Configuration :**
  - **Versioning :** Activé pour protection contre suppression accidentelle
  - **Block Public Access :** Activé (blocage de l'accès public par défaut)
  - **Encryption :** SSE-S3 (chiffrement côté serveur avec clés gérées par AWS)
  - **Lifecycle Policies :** Transition vers S3 Glacier pour archives après 90 jours
- **Usage :** Stockage des médias Magento (images produits, fichiers téléchargés)
- **Intégration :** Configurer Magento pour utiliser S3 comme backend de stockage via extension AWS S3

### 3.7. CDN (CloudFront)

**Statut :** Non configuré dans l'architecture actuelle

**Recommandation pour production :**
- **Origines :**
  - **Origin 1 :** ALB (pour contenu dynamique)
  - **Origin 2 :** Bucket S3 (pour médias statiques)
- **Comportements de cache :**
  - **Path Pattern `/media/*` :** Cache depuis S3, TTL 1 an, compression activée
  - **Path Pattern `/static/*` :** Cache depuis S3, TTL 1 an
  - **Default (*) :** Cache depuis ALB, TTL 1 heure, forwarding des cookies/headers nécessaires pour Magento
- **Objet racine par défaut :** `index.php`
- **HTTPS :** Certificat SSL/TLS géré par CloudFront (gratuit)
- **WAF :** Optionnel - Web Application Firewall pour protection contre attaques

## 4. Sécurité

### 4.1. Groupes de Sécurité

Les Security Groups (SG) agissent comme des firewalls au niveau de l'instance, contrôlant le trafic entrant et sortant.

#### Security Group ALB (`greenleaf-alb-sg`)

| Direction | Type | Protocol | Port | Source/Destination | Description |
|-----------|------|----------|------|-------------------|-------------|
| Inbound | HTTP | TCP | 80 | 0.0.0.0/0 | Accès HTTP depuis Internet |
| Inbound | HTTPS | TCP | 443 | 0.0.0.0/0 | Accès HTTPS depuis Internet (préparé pour futur) |
| Outbound | All | All | All | 0.0.0.0/0 | Tous les trafics sortants autorisés |

**Justification :** L'ALB doit être accessible depuis Internet pour recevoir le trafic des utilisateurs. Le trafic sortant est autorisé pour permettre la communication avec les instances EC2 et les services AWS.

#### Security Group EC2 (`greenleaf-ec2-sg`)

| Direction | Type | Protocol | Port | Source/Destination | Description |
|-----------|------|----------|------|-------------------|-------------|
| Inbound | HTTP | TCP | 80 | `greenleaf-alb-sg` | Trafic HTTP uniquement depuis l'ALB |
| Inbound | SSH | TCP | 22 | Variable `allow_ssh_cidr` | SSH optionnel (si `key_name` configuré) |
| Outbound | All | All | All | 0.0.0.0/0 | Tous les trafics sortants autorisés |

**Justification :**
- Les instances EC2 ne reçoivent du trafic que depuis l'ALB (pas d'accès direct depuis Internet), renforçant la sécurité.
- SSH est optionnel et restreint à une CIDR spécifique (ex: IP du bureau) si configuré.
- Le trafic sortant est nécessaire pour : mises à jour système, téléchargement de packages, communication avec RDS, accès à S3, etc.

#### Security Group RDS (`greenleaf-rds-sg`)

| Direction | Type | Protocol | Port | Source/Destination | Description |
|-----------|------|----------|------|-------------------|-------------|
| Inbound | MySQL/Aurora | TCP | 3306 | `greenleaf-ec2-sg` | Accès MySQL uniquement depuis les instances EC2 |
| Outbound | All | All | All | 0.0.0.0/0 | Tous les trafics sortants autorisés |

**Justification :**
- La base de données n'est accessible que depuis les instances applicatives, jamais depuis Internet.
- L'utilisation de Security Group comme source (au lieu de CIDR) garantit que seules les instances autorisées peuvent accéder à la base, même si leurs adresses IP changent.

### 4.2. Gestion des Identités (IAM)

#### Rôle IAM EC2 (`greenleaf-ec2-role`)

**Type :** Service Role pour EC2

**Assume Role Policy :**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Policies attachées :**

| Policy | ARN | Description |
|--------|-----|-------------|
| AmazonSSMManagedInstanceCore | `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` | Permet l'accès à AWS Systems Manager Session Manager pour support à distance sans SSH |

**Instance Profile :** `greenleaf-ec2-profile`
- Attaché au Launch Template
- Permet aux instances EC2 d'assumer le rôle IAM

**Justification :**
- **Principe du moindre privilège :** Seule la policy nécessaire (SSM) est attachée. Les instances n'ont pas besoin d'accès S3, RDS, ou autres services AWS directement (tout passe par les Security Groups et les endpoints réseau).
- **Support sans SSH :** SSM Session Manager permet de se connecter aux instances sans ouvrir le port SSH, améliorant la sécurité.
- **Extensibilité :** Si besoin futur (ex: accès S3 pour médias), ajouter uniquement les policies nécessaires.

**Recommandations pour production :**
- Ajouter une policy pour accès S3 en lecture/écriture si utilisation de S3 pour médias Magento
- Créer des rôles séparés si différents types d'instances nécessitent des permissions différentes
- Utiliser des policies IAM custom avec conditions (ex: restriction par IP, par heure) si nécessaire

### 4.3. Sécurité des Données

#### Chiffrement au repos

**RDS :**
- **Statut :** Chiffrement activé par défaut sur RDS (depuis 2017)
- **Méthode :** Chiffrement AES-256 via AWS KMS (Key Management Service)
- **Clés :** Clés gérées par AWS (AWS Managed Keys) par défaut
- **Stockage :** Données, logs, snapshots, et backups sont chiffrés

**EBS (Volumes EC2) :**
- **Statut :** Non explicitement configuré dans le Launch Template
- **Recommandation :** Activer le chiffrement EBS par défaut au niveau du compte AWS, ou ajouter `encrypted = true` dans le Launch Template pour les volumes root et data

**S3 (si utilisé) :**
- **Méthode :** SSE-S3 (Server-Side Encryption avec clés gérées par S3) ou SSE-KMS
- **Recommandation :** Activer le chiffrement par défaut sur le bucket

#### Chiffrement en transit

**HTTPS/TLS :**
- **Statut actuel :** HTTP uniquement (port 80)
- **Recommandation production :** 
  - Obtenir un certificat SSL/TLS via AWS Certificate Manager (ACM)
  - Configurer un listener HTTPS (443) sur l'ALB
  - Rediriger HTTP → HTTPS
  - Forcer HTTPS dans la configuration Magento

**RDS :**
- **Statut :** SSL/TLS disponible mais non forcé par défaut
- **Recommandation :** Configurer Magento pour utiliser une connexion SSL vers RDS (`db_ssl = true` dans la configuration Magento)

**Communication interne VPC :**
- Le trafic entre ALB ↔ EC2 et EC2 ↔ RDS reste dans le VPC (non chiffré par défaut)
- Pour un niveau de sécurité maximal, considérer VPC Endpoints pour services AWS (S3, CloudWatch) pour éviter le trafic Internet

**Secrets Management :**
- **Mots de passe RDS :** Stockés comme variables Terraform sensibles (`sensitive = true`)
- **Mots de passe Magento :** Passés via user-data (visible dans les logs)
- **Recommandation production :** Utiliser AWS Secrets Manager ou Systems Manager Parameter Store pour stocker les secrets de manière sécurisée, et les récupérer via IAM roles

## 5. Monitoring et Logging

### 5.1. Stratégie de surveillance

**CloudWatch Metrics :**

Les métriques suivantes sont automatiquement collectées par AWS CloudWatch :

| Service | Métriques Clés | Description |
|---------|----------------|-------------|
| **EC2** | CPUUtilization | Utilisation CPU des instances |
| | NetworkIn/Out | Trafic réseau entrant/sortant |
| | StatusCheckFailed | Échec des health checks système/instance |
| **ALB** | RequestCount | Nombre de requêtes par seconde |
| | TargetResponseTime | Temps de réponse moyen des instances |
| | HealthyHostCount | Nombre d'instances saines dans le Target Group |
| | UnHealthyHostCount | Nombre d'instances non saines |
| | HTTPCode_Target_2XX/4XX/5XX | Codes de statut HTTP |
| **RDS** | CPUUtilization | Utilisation CPU de la base |
| | DatabaseConnections | Nombre de connexions actives |
| | FreeableMemory | Mémoire disponible |
| | FreeStorageSpace | Espace de stockage disponible |
| | ReadLatency/WriteLatency | Latence des opérations de lecture/écriture |

**Métriques Custom :**
- Aucune métrique custom n'est actuellement configurée
- **Recommandation :** Ajouter des métriques applicatives Magento (ex: temps de génération de page, nombre de commandes/heure) via CloudWatch Agent ou API CloudWatch

### 5.2. Alarmes configurées

**Alarme CPU Haute (`greenleaf-cpu-high`) :**

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| Nom | `greenleaf-cpu-high` | Identifiant de l'alarme |
| Métrique | CPUUtilization | Utilisation CPU moyenne |
| Namespace | AWS/EC2 | Espace de noms CloudWatch |
| Dimension | AutoScalingGroupName | Filtre sur l'ASG `greenleaf-asg` |
| Statistic | Average | Moyenne sur la période |
| Period | 300 secondes (5 minutes) | Période d'évaluation |
| Evaluation Periods | 2 | Nombre de périodes consécutives |
| Threshold | 70% | Seuil d'alerte |
| Comparison Operator | GreaterThanThreshold | Alerte si > 70% |
| Treat Missing Data | missing | Ignore les données manquantes |

**Actions :**
- Aucune action automatique n'est configurée (alarme informative uniquement)
- **Recommandation :** Configurer une action SNS (Simple Notification Service) pour envoyer des notifications (email, SMS, Slack) lorsque l'alarme se déclenche

**Alarmes recommandées pour production :**

| Alarme | Métrique | Seuil | Action |
|--------|----------|-------|--------|
| RDS CPU High | RDS CPUUtilization | > 80% pendant 5 min | Notification SNS |
| RDS Storage Low | RDS FreeStorageSpace | < 2 GB | Notification SNS |
| ALB 5XX Errors | ALB HTTPCode_Target_5XX | > 10 en 5 min | Notification SNS + Auto Scaling |
| ALB Response Time | ALB TargetResponseTime | > 2 secondes | Notification SNS |
| EC2 Status Check Failed | EC2 StatusCheckFailed | > 0 | Notification SNS + Remplacement instance |
| Healthy Host Count Low | ALB HealthyHostCount | < 1 | Notification SNS (critique) |

### 5.3. Gestion des logs

**Logs système et applicatifs :**

**EC2 :**
- **User Data Logs :** `/var/log/user-data.log` - Logs du script d'initialisation
- **Syslog :** `/var/log/syslog` - Logs système Ubuntu
- **Nginx Logs :** 
  - Access: `/var/log/nginx/access.log`
  - Error: `/var/log/nginx/error.log`
- **PHP-FPM Logs :** `/var/log/php8.2-fpm.log`
- **Magento Logs :** `/var/www/magento/var/log/` (exceptions, système)

**Stockage actuel :** Logs stockés localement sur chaque instance EC2

**Recommandations pour production :**

1. **CloudWatch Logs Agent :**
   - Installer et configurer CloudWatch Logs Agent sur les instances EC2
   - Envoyer les logs vers CloudWatch Logs pour centralisation et rétention
   - Configurer des groupes de logs par type (nginx, php-fpm, magento)

2. **Log Retention :**
   - Configurer une rétention de 30 jours pour les logs d'accès
   - Rétention de 90 jours pour les logs d'erreur
   - Archive vers S3 Glacier pour logs anciens (> 90 jours)

3. **Log Insights :**
   - Utiliser CloudWatch Logs Insights pour analyser les logs (ex: requêtes lentes, erreurs fréquentes)

4. **ALB Access Logs :**
   - Activer les access logs de l'ALB vers S3
   - Analyser avec Athena ou CloudWatch Logs Insights

5. **RDS Logs :**
   - Activer les logs MySQL (slow query log, error log) dans RDS
   - Consulter via CloudWatch Logs

**Structured Logging :**
- **Recommandation :** Configurer Magento et Nginx pour générer des logs au format JSON pour faciliter l'analyse

## 6. Conclusion

Cette architecture fournit une base solide pour déployer Magento sur AWS avec haute disponibilité, scalabilité et sécurité. L'utilisation d'Infrastructure as Code (Terraform) et de Configuration Management (Ansible) garantit la reproductibilité et la maintenabilité.

**Points forts :**
- Architecture multi-AZ pour résilience
- Séparation des couches (ALB, EC2, RDS)
- Automatisation complète du déploiement
- Sécurité renforcée via Security Groups et IAM

**Améliorations recommandées pour production :**
- Ajout de sous-réseaux privés avec NAT Gateway
- Configuration HTTPS avec certificat ACM
- Intégration ElastiCache Redis pour cache
- Stockage S3 pour médias Magento
- CDN CloudFront pour performance globale
- Monitoring avancé avec alarmes SNS
- Centralisation des logs vers CloudWatch Logs
- Activation du chiffrement EBS
- Utilisation de AWS Secrets Manager pour les secrets

Cette architecture évolutive permet de démarrer avec un coût maîtrisé tout en conservant la capacité de monter en charge et d'ajouter des services selon les besoins de l'entreprise.
