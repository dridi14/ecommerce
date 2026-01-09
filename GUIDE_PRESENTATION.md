# Guide de Présentation - GreenLeaf Architecture AWS

**Durée totale :** ~8 minutes (30 secondes par slide × 16 slides)

**Contexte :** Présentation du projet GreenLeaf - Infrastructure E-commerce Magento sur AWS

**📋 Slides DAT :** Les slides marquées "📋 Slide DAT" correspondent au Document d'Architecture Technique (DAT.md). Ce sont les slides 3 à 9 qui détaillent l'architecture technique du projet.

---

## Slide 1 : Titre - Architecture E-commerce Magento sur AWS
**Durée : 30 secondes**

### Points à mentionner :
- Bonjour, je présente le projet **GreenLeaf**
- Architecture e-commerce **Magento** déployée sur **AWS**
- Approche **Infrastructure as Code** avec **Terraform** et **Ansible**
- Déploiement haute disponibilité, scalable et sécurisé
- Présentation de l'équipe DevOps/Cloud

### Phrases clés :
> "Aujourd'hui, je vous présente l'architecture GreenLeaf, une plateforme e-commerce Magento déployée sur AWS avec une approche Infrastructure as Code."

---

## Slide 2 : Contexte & Objectifs
**Durée : 30 secondes**

### Points à mentionner :
- **GreenLeaf** : startup e-commerce produits écoresponsables
- Projet étudiant pour infrastructure de production robuste
- **4 objectifs stratégiques** :
  1. Haute Disponibilité (Multi-AZ)
  2. Scalabilité Automatique (Auto Scaling)
  3. Sécurité & Isolation (VPC privé, WAF, HTTPS)
  4. Budget maîtrisé (optimisation coûts)

### Phrases clés :
> "GreenLeaf commercialise des produits écoresponsables. Notre mission : concevoir une infrastructure production-ready avec haute disponibilité, scalabilité automatique, sécurité renforcée et budget optimisé."

---

## Slide 3 : Vue d'ensemble de l'architecture
**Durée : 30 secondes**  
**📋 Slide DAT** - Document d'Architecture Technique

### Points à mentionner :
- **Diagramme** : flux de données Multi-AZ
- **CloudFront CDN** en point d'entrée (distribution globale)
- **ALB Public** distribuant le trafic sur 2 zones
- **Auto Scaling** sur 2 AZs (tolérance aux pannes)
- **RDS Multi-AZ** (Active/Standby) pour la base de données

### Phrases clés :
> "L'architecture suit un flux Multi-AZ : CloudFront distribue le trafic, l'ALB répartit sur nos instances EC2 dans deux zones, et RDS assure la haute disponibilité avec réplication synchrone."

---

## Slide 4 : Composants Réseau (VPC)
**Durée : 30 secondes**  
**📋 Slide DAT** - Document d'Architecture Technique

### Points à mentionner :
- **VPC** : CIDR 10.0.0.0/16 en région eu-west-3 (Paris)
- **2 sous-réseaux publics** : AZ-a (10.0.1.0/24) et AZ-b (10.0.2.0/24)
- **Internet Gateway** pour connectivité publique
- **Security Groups** en profondeur :
  - ALB : 80/443 depuis Internet
  - EC2 : 80 depuis ALB uniquement
  - RDS : 3306 depuis EC2 uniquement

### Phrases clés :
> "Notre VPC est segmenté en deux sous-réseaux publics Multi-AZ. Les Security Groups appliquent le principe du moindre privilège : chaque couche n'accepte que le trafic strictement nécessaire."

---

## Slide 5 : Couche Applicative
**Durée : 30 secondes**  
**📋 Slide DAT** - Document d'Architecture Technique

### Points à mentionner :
- **Application Load Balancer** : point d'entrée unique avec HTTPS (ACM)
- **Auto Scaling Group** : Min=1, Desired=1, Max=2 instances
- **Instances EC2** : t3.small (2 vCPU / 2 Go RAM) pour stabilité Magento
- **Ubuntu 22.04** configuré via Ansible
- **Health Checks** : remplacement automatique des instances non saines en < 60s

### Phrases clés :
> "L'ALB distribue le trafic HTTPS vers nos instances EC2 t3.small. L'Auto Scaling s'adapte à la charge, et les health checks garantissent la résilience avec remplacement automatique."

---

## Slide 6 : Base de Données
**Durée : 30 secondes**  
**📋 Slide DAT** - Document d'Architecture Technique

### Points à mentionner :
- **RDS MySQL** : db.t3.small Multi-AZ
- **Haute Disponibilité** : réplication synchrone vers instance standby
- **Failover automatique** : RTO < 5 minutes
- **Sauvegardes** : rétention 7 jours, snapshots automatiques
- **Sécurité** : base isolée, accessible uniquement depuis EC2 via Security Groups

### Phrases clés :
> "RDS MySQL en Multi-AZ assure la haute disponibilité avec réplication synchrone. En cas de panne, le failover automatique garantit un RTO inférieur à 5 minutes."

---

## Slide 7 : Stockage & Performance
**Durée : 30 secondes**  
**📋 Slide DAT** - Document d'Architecture Technique

### Points à mentionner :
- **EBS Volumes** : stockage local gp3 attaché aux instances EC2 pour système de fichiers et médias
- **Amazon EFS** : système de fichiers partagé Multi-AZ pour médias produits, accessible depuis toutes les instances
- **Compression** : Gzip/Brotli activé sur Nginx réduit trafic sortant de 70%
- **Sauvegarde** : Snapshots EBS automatiques et sauvegardes EFS
- **Optimisation** : Compression réduit coûts Data Transfer et améliore performances

### Phrases clés :
> "EBS stocke les données locales, EFS partage les médias entre instances. La compression Gzip/Brotli réduit le trafic sortant de 70% et optimise les coûts."

---

## Slide 8 : Monitoring & Observabilité
**Durée : 30 secondes**  
**📋 Slide DAT** - Document d'Architecture Technique

### Points à mentionner :
- **CloudWatch Metrics** : suivi EC2 CPU, RDS IOPS, ALB RequestCount
- **Alarmes SNS** : notifications email pour CPU > 80%, HTTP 5xx > 1%, RDS storage < 2GB
- **CloudWatch Logs** : centralisation logs applicatifs (Nginx, PHP-FPM, Magento)
- **Dashboard unifié** : vue d'ensemble santé système (EC2 + RDS + ALB)
- **Réactivité** : Auto Scaling déclenché automatiquement + notifications

### Phrases clés :
> "CloudWatch surveille l'infrastructure en temps réel. Les alarmes SNS alertent l'équipe et déclenchent l'Auto Scaling pour une réactivité immédiate."

---

## Slide 9 : Sécurité & Conformité
**Durée : 30 secondes**  
**📋 Slide DAT** - Document d'Architecture Technique

### Points à mentionner :
- **Security Groups restrictifs** : principe du moindre privilège appliqué
- **IAM** : rôles granulaires (EC2 pour Secrets, utilisateur Terraform dédié)
- **Secrets Manager** : gestion sécurisée credentials DB et clés API Magento
- **Chiffrement** : données au repos (EBS, EFS, RDS) et en transit (TLS/SSL via ACM)
- **Conformité** : respect AWS Well-Architected Framework (pilier Sécurité)

### Phrases clés :
> "La sécurité est renforcée à tous les niveaux : Security Groups restrictifs, IAM avec moindres privilèges, Secrets Manager pour les credentials, et chiffrement bout en bout."

---

## Slide 10 : Infrastructure as Code
**Durée : 30 secondes**

### Points à mentionner :
- **Pipeline automatisé** : déploiement en 15-20 minutes
- **4 étapes** :
  1. **Terraform** : Provisionning (VPC, Security Groups, RDS, ALB)
  2. **Ansible** : Configuration (Nginx, PHP-FPM, Composer, Magento Setup)
  3. **Post-Install** : Compilation assets, migration DB, cache flush
  4. **Production** : Auto Scaling, CloudWatch Alarms, backups auto
- **Avantages** : Idempotence, Secrets Manager, Version Control Git

### Phrases clés :
> "Notre pipeline IaC déploie l'infrastructure en 15-20 minutes : Terraform provisionne, Ansible configure, puis Magento est déployé. Tout est versionné et reproductible."

---

## Slide 11 : Guide de Déploiement
**Durée : 30 secondes**

### Points à mentionner :
- **Prérequis** : AWS CLI configuré, Terraform ≥ 1.6, Ansible
- **Variables sensibles** : db_password, magento_admin_password via terraform.tfvars
- **Déploiement** : `terraform init` puis `terraform apply` (ou script bootstrap.sh)
- **Validation** : scripts validate.sh, accès via ALB DNS
- **Scripts disponibles** : bootstrap.sh, validate.sh, destroy.sh

### Phrases clés :
> "Le déploiement est simple : après configuration des variables sensibles, terraform init et apply créent l'infrastructure. Les scripts automatisent validation et destruction."

---

## Slide 12 : Estimation des Coûts & FinOps
**Durée : 30 secondes**

### Points à mentionner :
- **Coût mensuel** : $291.50 (Pay-As-You-Go) ou $254.90 optimisé
- **Répartition** : RDS (72$), VPC NAT (74$), EC2 (50$), ALB (26$), autres (69$)
- **Stratégies d'optimisation** :
  - Right-Sizing : t3.small pour stabilité Magento
  - Compression : Gzip/Brotli réduit trafic de 70%
  - Savings Plans : économie ~30% avec engagement 1 an
- **Budget** : Alerte configurée à 350$ (70% du budget 500$)

### Phrases clés :
> "Le coût mensuel est de 291 dollars, avec une marge confortable sur notre budget de 500 dollars. Les optimisations permettent de réduire à 255 dollars avec Savings Plans."

---

## Slide 13 : Points Forts de l'Architecture
**Durée : 30 secondes**

### Points à mentionner :
- **6 points forts** :
  1. **Haute Résilience** : Multi-AZ complet (RTO < 5 min)
  2. **Scalabilité Auto** : ASG réactif, zéro downtime
  3. **100% Automatisé** : Terraform + Ansible, IaC complet
  4. **Sécurité Renforcée** : moindres privilèges, Secrets Manager, TLS/EBS
  5. **Observabilité** : CloudWatch complet, alarmes proactives
  6. **Doc & FinOps** : documentation exhaustive, budget optimisé

### Phrases clés :
> "Notre architecture combine résilience Multi-AZ, scalabilité automatique, automatisation complète, sécurité renforcée, observabilité totale et optimisation des coûts."

---

## Slide 14 : Conformité au cahier des charges
**Durée : 30 secondes**

### Points à mentionner :
- **100% Validé** : toutes les exigences respectées
- **Infrastructure & Core** :
  - AWS Only (eu-west-3)
  - Magento Open Source 2.4.7-p1
  - Infrastructure as Code (Terraform + Ansible)
  - Haute Disponibilité Multi-AZ
- **Services & Sécurité** :
  - Scalabilité & Performance (ASG + CloudFront)
  - RDS MySQL géré avec backups auto
  - Monitoring CloudWatch + SNS
  - Sécurité HTTPS, Private Subnets, SG restrictifs

### Phrases clés :
> "Toutes les exigences du cahier des charges sont respectées : AWS uniquement, Magento Open Source, IaC complet, haute disponibilité, scalabilité et sécurité renforcée."

---

## Slide 15 : Optimisations & Évolutions
**Durée : 30 secondes**

### Points à mentionner :
- **Court terme** : Performance & Sécurité (WAF + Redis Cache)
- **Moyen terme** : Optimisation FinOps (Reserved Instances)
- **Long terme** : Résilience Maximale (Disaster Recovery Multi-région)
- **Évolutions prévues** :
  - FinOps : Reserved Instances (~30-40% économie)
  - Performance : ElastiCache Redis, Varnish
  - Sécurité : AWS WAF avec règles OWASP
  - CI/CD : Pipeline complet automatisé

### Phrases clés :
> "Notre roadmap prévoit l'ajout de WAF et Redis à court terme, l'optimisation FinOps avec Reserved Instances, et à long terme un Disaster Recovery Multi-région."

---

## Slide 16 : Conclusion
**Durée : 30 secondes**

### Points à mentionner :
- **Architecture validée et prête** pour la production
- **4 réalisations clés** :
  1. Robustesse & Scalabilité (Multi-AZ, Auto Scaling)
  2. Conformité Totale (AWS, Terraform, Ansible, Magento)
  3. Budget Optimisé ($291/mois, marge sur budget 500$)
  4. Sécurité by Design (TLS/EBS, IAM, isolation réseau)
- **Prochaines étapes** : Tests de charge, CI/CD complet, WAF & Redis
- **Merci et questions**

### Phrases clés :
> "En conclusion, nous avons livré une architecture production-ready, conforme au cahier des charges, avec un budget optimisé et une sécurité renforcée. Merci pour votre attention, avez-vous des questions ?"

---

## Notes Générales

### Transitions entre slides :
- Utiliser des phrases de transition : "Passons maintenant à...", "Voyons en détail...", "Enfin..."
- Faire des liens entre les slides : "Comme nous l'avons vu dans l'architecture globale..."

### Gestion du temps :
- **30 secondes par slide** = environ 8 minutes totales
- Si vous dépassez, accélérez sur les slides techniques (slides 4-8)
- Si vous avez du temps, développez les slides FinOps et Optimisations

### Points d'attention :
- **Slide 3** : Bien expliquer le diagramme (pointer les composants)
- **Slide 12** : Insister sur le budget et la marge confortable
- **Slide 16** : Préparer des réponses aux questions fréquentes

### Questions fréquentes à préparer :
1. "Pourquoi t3.small et pas t3.micro ?" → Stabilité Magento, évite OOM
2. "Pourquoi Multi-AZ si c'est plus cher ?" → Haute disponibilité requise
3. "Comment réduire encore les coûts ?" → Reserved Instances, Savings Plans
4. "Quel est le temps de déploiement ?" → 15-20 minutes avec Terraform/Ansible

---

**Bon courage pour votre présentation ! 🚀**
