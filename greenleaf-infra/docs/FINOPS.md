Rapport d'Analyse FinOps 

Projet : GreenLeaf - Déploiement d'une Plateforme E-commerce Scalable sur AWS 

Groupe: Incorporatti 

Date : 09 Janvier 2026 

 

1. Résumé Exécutif (Executive Summary) 

Ce rapport présente l'analyse financière de l'infrastructure de production pour GreenLeaf. L'architecture a été calibrée pour garantir la stabilité de Magento (passage aux instances small) tout en maintenant une rigueur budgétaire stricte via une gestion asymétrique des environnements (Dev vs Prod). 

Nous confirmons que le projet respecte les contraintes budgétaires avec une marge confortable. 

Coût Mensuel Estimé (Pay-As-You-Go) : 291,50 $**Coût Mensuel Optimisé (avec recommandations) : 254,90$ 

Économie Potentielle : ~12,5 % (supplémentaire) 

 

2. Estimation Détaillée des Coûts 

L'estimation repose sur les tarifs publics AWS (Région eu-west-3 Paris), pour une activité 24/7 (730h) en Production Haute Disponibilité. 

Service 

Composant 

Coût Mensuel Estimé ($) 

Hypothèses de Calcul 

EC2 (Web) 

2x t3.small (Linux) 

33,60 $ 

Instances à la demande. 2 vCPU / 2 Go RAM requis pour la stabilité PHP/Magento. 

EC2 (Search) 

1x t3.small 

16,80 $ 

Auto-hébergement d'OpenSearch (vs Service Managé à >100$). 

RDS 

1x db.t3.small Multi-AZ 

72,00 $ 

Moteur MariaDB. Multi-AZ activé pour la Haute Disponibilité (SLA). 

VPC 

2x NAT Gateways 

74,40 $ 

Sécurisation des subnets privés sur 2 zones (Coût fixe). 

ALB 

1x Application Load Balancer 

26,50 $ 

730h/mois + traitement du trafic entrant/sortant. 

ElastiCache 

1x cache.t3.micro 

13,00 $ 

Instance Redis pour le cache de session (suffisant en micro). 

Data Transfer 

Trafic Sortant (Internet) 

45,00 $ 

Estimation réaliste de 500 Go de transfert (basée sur compression active). 

Stockage 

EBS gp3  

6,00 $ 

Volumes racines et stockage partagé pour les médias produits. 

Monitoring 

CloudWatch & Route53 

4,20 $ 

Logs (rétention 7j), Alarmes et Zone DNS. 

TOTAL 

 

291,50 $ 

Budget : 500 $(Marge : +208$) 

 

3. Stratégies d'Optimisation des Coûts Mises en Place 

3.1. Dimensionnement (Right-Sizing) 

Le choix de la taille des instances a été crucial pour l'équilibre Coût/Performance : 

Arbitrage t3.micro vs t3.small : Nos tests ont montré que le t3.micro (1 Go RAM) provoquait des crashs (Out Of Memory) sous Magento. Nous avons basculé la production sur t3.small (2 Go RAM). Bien que plus cher (~ +15$/instance), cela garantit la continuité de service. 

Approche Asymétrique : Pour compenser ce coût, l'environnement de DEV a été réduit au minimum (Single-AZ, pas de Load Balancer, arrêt la nuit), rendant le coût hors-production négligeable. 

3.2. Utilisation d'un CDN et Optimisation Trafic 

Le trafic sortant coûtant 0.09 $/Go, nous avons agi sur le volume de données : 

Compression : Activation de Gzip/Brotli sur les serveurs Nginx. Cela réduit le poids des fichiers texte de 70%. 

CloudFront (Futur) : Prévu pour la phase 2. Pour l'instant, le trafic direct (500 Go) reste largement dans le budget grâce à la compression. 

3.3. Automatisation et Scalabilité (Scénario de Montée en Charge) 

L'Auto Scaling est notre assurance contre les crashs, mais aussi un outil de maîtrise des coûts. Nous ne payons les ressources supplémentaires que durant les minutes exactes où elles sont nécessaires. 

Simulation FinOps : Scénario "Campagne Marketing" (100 000 Visiteurs) 

Nous avons modélisé l'impact financier d'un pic de trafic soudain (ex: passage TV ou influenceur) amenant 100 000 utilisateurs sur 24 heures. 

Comportement de l'Auto Scaling : 

Déclencheur : Dès que la charge CPU moyenne dépasse 60%, le groupe ASG lance automatiquement de nouveaux serveurs t3.small. 

Plafond (Safety Cap) : Nous avons configuré une limite stricte max_size = 10 instances pour éviter une consommation infinie en cas d'attaque DDoS. 

Calcul du Coût du Pic ("The Coffee Cost") : 

Si nous devons passer de 2 à 10 serveurs pendant 24h pour absorber la charge : 

Coût unitaire : 0,023 $ / heure / serveur. 

Surplus : 8 serveurs supplémentaires x 24 heures x 0,023 $. 

Coût total du Scale-Out : ~4,42 $. 

Impact Data Transfer : 

100 000 visiteurs générant chacun ~2 Mo de trafic (pages compressées) = 200 Go de trafic sortant supplémentaire. 

Coût du Transfert : 200 Go x 0,09 $= **18,00$.** 

Conclusion du Scénario : 

Accueillir 100 000 clients supplémentaires en urgence ne coûtera que ~22,42 $ (Compute + Réseau). 

Cette somme est largement couverte par notre marge de sécurité mensuelle (208 $), prouvant que l'architecture est scalable financièrement. 

 

3.3. Automatisation et Scalabilité (Scénario de Montée en Charge) 

L'Auto Scaling est notre assurance contre les crashs, mais aussi un outil de maîtrise des coûts. Nous ne payons les ressources supplémentaires que durant les minutes exactes où elles sont nécessaires. 

Simulation FinOps : Scénario "Campagne Marketing" (100 000 Visiteurs) 

Nous avons modélisé l'impact financier d'un pic de trafic soudain (ex: passage TV ou influenceur) amenant 100 000 utilisateurs sur 24 heures. 

Comportement de l'Auto Scaling : 

Déclencheur : Dès que la charge CPU moyenne dépasse 60%, le groupe ASG lance automatiquement de nouveaux serveurs t3.small. 

Plafond (Safety Cap) : Nous avons configuré une limite stricte max_size = 10 instances pour éviter une consommation infinie en cas d'attaque DDoS. 

Calcul du Coût du Pic ("The Coffee Cost") : 

Si nous devons passer de 2 à 10 serveurs pendant 24h pour absorber la charge : 

Coût unitaire : 0,023 $ / heure / serveur. 

Surplus : 8 serveurs supplémentaires x 24 heures x 0,023 $. 

Coût total du Scale-Out : ~4,42 $. 

Impact Data Transfer : 

100 000 visiteurs générant chacun ~2 Mo de trafic (pages compressées) = 200 Go de trafic sortant supplémentaire. 

Coût du Transfert : 200 Go x 0,09 $= **18,00$.** 

Conclusion du Scénario : 

Accueillir 100 000 clients supplémentaires en urgence ne coûtera que ~22,42 $ (Compute + Réseau). 

Cette somme est largement couverte par notre marge de sécurité mensuelle (208 $), prouvant que l'architecture est scalable financièrement. 

 

 

3.4. Choix des Services Managés (RDS) 

Nous avons choisi Amazon RDS plutôt qu'une base de données sur EC2, malgré un surcoût apparent (~20%). 

Justification : RDS gère automatiquement les sauvegardes, le patching de l'OS et surtout la réplication Multi-AZ. 

Gain FinOps : Configurer une réplication Multi-AZ manuelle fiable sur EC2 aurait nécessité plusieurs jours-homme de travail DevOps. Le coût du service managé est donc rentabilisé par l'économie de temps de maintenance. 

 

4. Recommandations pour le Futur 

4.1. Instances Réservées et Savings Plans 

Une fois l'architecture stabilisée (après 3 mois), l'engagement est le levier le plus puissant. 

Analyse : La base de données (RDS) et les 3 instances EC2 (2 Web + 1 Search) tournent 24/7. 

Proposition : Achat d'un Compute Savings Plan (1 an, No Upfront) et d'une Instance Réservée RDS. 

Tableau comparatif : 

Service 

Coût à la Demande ($) 

Coût avec Savings Plan/RI 1 an ($) 

Économie (%) 

EC2 (3 instances small) 

50,40 $ 

35,30$ 

~30 % 

RDS (1 instance small) 

72,00 $ 

50,50$ 

~30 % 

TOTAL 

122,40 $ 

85,80 $ 

~36,60 $ / mois 

4.2. Politiques de Cycle de Vie S3 

Les images produits s'accumulent. Nous recommandons une règle de cycle de vie (Lifecycle Policy) pour déplacer les objets de plus de 30 jours vers la classe S3 Standard-IA (Infrequent Access), réduisant le coût de stockage de 40%. 

4.3. Planification de l'Arrêt des Environnements 

Pour l'environnement de Développement/Recette uniquement : mise en place de l'outil AWS Instance Scheduler pour éteindre automatiquement les ressources du vendredi 20h au lundi 8h, réduisant la facture Dev de ~60%. 

 

5. Mise en Place du Suivi Budgétaire 

Pour garantir le pilotage financier par GreenLeaf : 

AWS Budgets : 

Une alerte budgétaire a été configurée avec un seuil à 350 $ (70% du budget total). 

Notification envoyée par email à l'équipe technique en cas de dépassement prévisionnel. 

Cost Explorer : 

Un rapport personnalisé a été créé pour suivre spécifiquement les coûts liés aux NAT Gateways et au Data Transfer, identifiés comme les coûts les plus volatils. 

Tagging : 

Application systématique du tag Project=GreenLeaf et Environment=Production via Terraform sur toutes les ressources. Cela permet de filtrer précisément les coûts dans la console de facturation. 

 