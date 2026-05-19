# aws-localstack-cloud

Lab d'infrastructure n-tiers AWS déployé sur **LocalStack Pro** via Terraform.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  VPC 172.16.0.0/16                                          │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    │
│  │ Public AZ-a  │   │ Public AZ-b  │   │ Public AZ-c  │    │
│  │ + NAT GW     │   └──────────────┘   └──────────────┘    │
│  │ + EC2 web-1  │                                          │
│  └──────┬───────┘                                          │
│         │                                                  │
│  ┌──────┴───────┐   ┌──────────────┐   ┌──────────────┐    │
│  │ Web AZ-a     │   │ Web AZ-b     │   │ Web AZ-c     │    │
│  └──────────────┘   └──────────────┘   └──────────────┘    │
│         (routés via NAT GW)                                │
└─────────────────────────────────────────────────────────────┘

      DynamoDB (hors VPC, service managé)
      Secrets Manager (credentials applicatifs)
```

| Composant | Ressource Terraform | Description |
|---|---|---|
| Réseau | `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_nat_gateway`, `aws_route_table` | VPC `172.16.0.0/16`, 3 AZ, subnets public + web, NAT vers Internet |
| Sécurité | `aws_security_group` | SG ALB (80/443 public), SG web (80 depuis ALB + 22 SSH) |
| Calcul | `aws_instance`, `aws_key_pair`, `data.aws_ami` | 1 instance Ubuntu dans le subnet public, clé SSH `localstack` |
| Données | `aws_dynamodb_table` | Table `lab-factory-table`, `PAY_PER_REQUEST`, PITR + SSE actifs |
| Secrets | `aws_secretsmanager_secret`, `random_password` | Credentials applicatifs (username + password 24 chars généré) |
| DevX | `local_file` | Génère `.env.local` après chaque `apply` |

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- [LocalStack Pro](https://docs.localstack.cloud/getting-started/installation/) (token requis) ou compte trial
- AWS CLI v2
- `jq` pour parser le secret JSON

## Mise en route

### 1. Démarrer LocalStack Pro

```bash
export LOCALSTACK_AUTH_TOKEN=ls-...

docker run -d \
  --name localstack-aws \
  -p 4566:4566 \
  -e LOCALSTACK_AUTH_TOKEN \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack-pro:latest
```

Vérifier :
```bash
curl -s http://localhost:4566/_localstack/info | jq '.edition, .is_license_activated'
```

Attendu : `"pro"` et `true`.

### 2. Déployer

```bash
cd aws-n-tiers-localstack/aws-n-tiers-localstack

terraform init
terraform plan
terraform apply
```

L'apply produit automatiquement un fichier `.env.local` avec toutes les variables nécessaires (endpoint LocalStack, credentials test, nom du secret, etc.).

### 3. Charger l'environnement

```bash
source .env.local
```

Tu disposes alors de :

| Variable | Usage |
|---|---|
| `AWS_ENDPOINT_URL` | Redirige toutes les commandes AWS CLI vers LocalStack |
| `AWS_REGION` | `eu-west-3` |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Credentials factices (`test`/`test`) |
| `DB_SECRET_NAME` / `DB_SECRET_ARN` | Identifiants du secret |
| `DYNAMODB_TABLE_NAME` / `DYNAMODB_TABLE_ARN` | Identifiants de la table |

Astuce : avec [direnv](https://direnv.net) (`brew install direnv` puis `direnv allow`), renommer `.env.local` en `.envrc` charge automatiquement les variables à chaque `cd` dans le dossier.

## Commandes utiles

### Récupérer le password applicatif

```bash
# Bundle JSON complet (username, password, table_name, region)
aws secretsmanager get-secret-value --secret-id "$DB_SECRET_NAME" \
  --query SecretString --output text | jq

# Password seul, capturé dans une variable shell sans affichage
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_NAME" \
  --query SecretString --output text | jq -r .password)
```

### Tester DynamoDB

```bash
aws dynamodb describe-table --table-name "$DYNAMODB_TABLE_NAME"

aws dynamodb put-item --table-name "$DYNAMODB_TABLE_NAME" \
  --item '{"id":{"S":"test-001"},"message":{"S":"hello"}}'

aws dynamodb scan --table-name "$DYNAMODB_TABLE_NAME"
```

### SSH vers l'instance EC2 (limité — voir notes)

```bash
$(terraform output -raw ssh_command)
# Équivalent :
ssh -o StrictHostKeyChecking=no -i ./localstack ubuntu@$(terraform output -raw web_public_ip)
```

> **⚠️ État réel de la VM sur LocalStack**
>
> Cette stack a été testée sur LocalStack Pro `2026.5.0.dev` (Mac ARM). Malgré la configuration recommandée par la doc (`EC2_VM_MANAGER=docker`, image taggée `localstack-ec2/<name>:<ami-id>`, socket Docker monté), **aucun container Docker backing n'est spawned** pour l'instance EC2 — celle-ci n'existe qu'en mock dans l'API LocalStack.
>
> **Conséquences** :
> - `aws ec2 describe-instances` retourne `running` avec une IP, mais c'est de la fiction.
> - **SSH ne fonctionne pas** : la commande `ssh_command` échouera en timeout/refus.
> - Le code Terraform est néanmoins **valide pour AWS réel** : `aws_key_pair`, `aws_instance`, `aws_security_group` avec port 22 sont corrects et s'appliqueraient comme attendu sur un vrai compte AWS.
>
> **Pour faire marcher SSH** : soit déployer sur AWS réel (retirer les `endpoints` LocalStack du provider), soit investiguer la configuration LocalStack Pro plus avant (versions stables, AMIs pré-shippées, support).

### Détruire

```bash
terraform destroy
```

## Sécurité

- Le **password DB n'apparaît jamais** dans les outputs Terraform, ni dans le state non chiffré, ni dans `.env.local`. Il vit uniquement dans Secrets Manager et est récupéré à la demande.
- La **clé SSH privée** (`localstack`) est dans `.gitignore` (seule la `.pub` est versionnée).
- Le `.env.local` est généré avec les permissions `0600` et ignoré par git.
- `terraform.tfvars` est également ignoré : ne jamais y mettre de credentials.

## Structure du repo

```
.
├── README.md                            # Ce fichier
├── .gitignore
└── aws-n-tiers-localstack/
    └── aws-n-tiers-localstack/
        ├── provider.tf                  # Providers AWS / random / local + endpoints LocalStack
        ├── variables.tf                 # Variables (project_name, region, vpc_cidr, db_username)
        ├── terraform.tfvars             # Valeurs (sans credentials)
        ├── network.tf                   # VPC, subnets, IGW, NAT, route tables
        ├── security-groups.tf           # SG ALB et web
        ├── ec2.tf                       # key_pair, AMI lookup, instance
        ├── dynamodb.tf                  # Table DynamoDB
        ├── secrets.tf                   # random_password + Secrets Manager
        ├── load-balancer.tf             # ALB (commenté, à activer)
        ├── route53.tf                   # Route53 (commenté, à activer)
        ├── outputs.tf
        ├── env.tf                       # Génère .env.local
        ├── localstack.pub               # Clé SSH publique versionnée
        └── .gitignore
```

## Limitations connues

- **EC2 backing Docker non fonctionnel** sur notre setup LocalStack Pro `2026.5.0.dev` (Mac ARM) : malgré `EC2_VM_MANAGER=docker` et une image AMI taggée localement (`localstack-ec2/<name>:<ami-id>`), LocalStack ne reconnaît pas l'AMI et ne spawn aucun container backing. L'instance n'existe qu'en mock. → SSH non opérationnel en local. Le code Terraform reste valide pour AWS réel.
- LocalStack **Community** (gratuit) ne supporte de toute façon que le **mock VM manager** pour EC2.
- Les modules **ALB** et **Route53** sont commentés (`load-balancer.tf`, `route53.tf`) — à activer pour un setup n-tiers complet.
- Le **NAT Gateway sur LocalStack** rencontre parfois un bug `'NoneType' object has no attribute 'shutdown'` au destroy → contournement : `rm terraform.tfstate*` et restart du container LocalStack.
