# Infraestrutura como Código (IaC) — AWS CloudFormation (MUNKA)

Este diretório contém os templates oficiais de Infraestrutura como Código em **YAML** para o provisionamento e governança dos recursos AWS utilizados no projeto **MUNKA (IFG)**.

---

## 🏗️ Recursos Provisionados

O template `cloudformation.yaml` cria a seguinte estrutura na AWS:

1. **S3 Bucket (`munka-dev-070980587239-us-east-2`)**:
   - Criptografia padrão habilitada (SSE-S3 AES-256).
   - Bloqueio total de acesso público (`BlockPublicAccess`).
   - Versionamento de objetos ativo.
   - Estrutura de diretórios para camadas de dados:
     - `s3://munka-data/raw/` (Dados brutos)
     - `s3://munka-data/processed/` (Dados limpos)
     - `s3://munka-data/features/` (Features para ML)
     - `s3://munka-data/ml/` (Artefatos e predições)

2. **IAM Role (`MunkaSnowflakeS3IntegrationRole-dev`)**:
   - Role com menor privilégio para autorizar o Snowflake a ler e escrever no bucket S3 via `STORAGE INTEGRATION` com IAM Role.

3. **CloudWatch Log Group (`/aws/munka/dev/pipeline-logs`)**:
   - Retenção configurada para 30 dias para auditoria de orquestração do Airflow e cargas.

---

## 🚀 Como Executar o Deploy

### Pré-requisitos
- [AWS CLI](https://aws.amazon.com/cli/) instalado e configurado (`aws configure`).
- Credenciais AWS com permissões para criar buckets S3, roles IAM e grupos do CloudWatch.

### Comando de Validação
```bash
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation.yaml
```

### Comando de Deploy
```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation.yaml \
  --stack-name munka-infrastructure-stack \
  --parameter-overrides EnvironmentName=dev \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-2
```

### Comando para Verificar os Outputs
```bash
aws cloudformation describe-stacks \
  --stack-name munka-infrastructure-stack \
  --query "Stacks[0].Outputs" \
  --output table
```
