# FINOPS

## Services qui coûtent
- EC2 (instances ASG, EBS racine).
- RDS MySQL (instance, stockage, sauvegardes, Multi-AZ si activé).
- Application Load Balancer.
- Trafic sortant Internet.
- CloudWatch (alarme, métriques supplémentaires si ajoutées).
- Bande passante NAT non utilisée (instances en subnets publics).

## Estimation (AWS Pricing Calculator)
1. Ajouter EC2 (Ubuntu t3.micro, 1 instance moyenne) + 20–30 Go EBS gp3.
2. Ajouter ALB (Application Load Balancer, ~1 LCUs par défaut).
3. Ajouter RDS MySQL (db.t3.micro, 20 Go gp3, Multi-AZ si souhaité).
4. Ajouter CloudWatch Alarms (coût marginal).
5. Simuler 1–2 To/mois de transfert sortant selon besoin.

## Optimisation
- Démarrage « MVP » : t3.micro (app) et db.t3.micro, ASG min=1/desired=1/max=2.
- Désactiver `rds_multi_az` en dev pour réduire le coût, l’activer en prod.
- Limiter `max_size` de l’ASG si le trafic est faible ; ajouter policies d’auto-scale basées sur CPU/ALB RequestCount.
- Considérer Savings Plans/RI sur RDS et éventuellement EC2 une fois les charges stables.
- Utiliser des fenêtres de maintenance et `terraform destroy` pour les environnements temporaires.
- Activer compression/Cache HTTP côté Nginx/CDN (optionnel) pour réduire le transfert sortant.

## Suivi budgétaire
- Créer un budget AWS (Cost > Budgets) avec alertes email/Slack sur montant mensuel.
- Activer Cost Explorer + tagging `Project=greenleaf` pour filtrer.
- Mettre en place des alarmes CloudWatch sur coûts (anomaly detection) si besoin.
