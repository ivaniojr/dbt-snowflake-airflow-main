# Arquitetura de Desacoplamento: Airflow + AWS ECS Fargate

Atualmente, seu Airflow está executando pesados scripts de Machine Learning (treinamento e otimização) no próprio container do *Worker*. Para desacoplar a **Orquestração** (Airflow) da **Execução** (Computação Pesada) utilizando a sua conta AWS, a solução ideal e mais moderna é utilizar o **AWS ECS com Fargate**.

O Fargate permite rodar containers sob demanda sem gerenciar servidores EC2. O Airflow apenas "dá a ordem" para a AWS ligar uma máquina, rodar o script e desligar, pagando apenas pelos minutos de uso.

---

## 🏗️ Como Funciona o Novo Fluxo

1. **Airflow (Orquestrador):** Fica leve. Não precisa de `scikit-learn` ou `optuna` instalados. Ele apenas gerencia dependências de tempo e aciona a AWS via API (`EcsRunTaskOperator`).
2. **AWS ECR (Elastic Container Registry):** Armazena a imagem Docker contendo o seu código Python (`src/ml/*`).
3. **AWS ECS Fargate (Computação):** Levanta um container isolado com CPU/RAM dedicados (ex: 4 vCPU, 16GB RAM) especificamente para rodar o `train_best.py` ou `batch_inference.py`.
4. **AWS S3 / MLflow:** Os artefatos (`.joblib`, gráficos) não ficam mais perdidos em um disco local. Eles são enviados diretamente para um bucket S3 pelo script de ML, e o MLflow lê desse S3.

---

## 🛠️ Passo a Passo para Implementação

### Passo 1: Criar o Dockerfile de Machine Learning
Crie uma imagem Docker **separada** da imagem do Airflow, dedicada apenas para rodar os algoritmos do MUNKA.

```dockerfile
# /src/ml/Dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copia os scripts de ML
COPY . /app/

# Define o ponto de entrada (será sobrescrito pelo Airflow para cada DAG)
ENTRYPOINT ["python"]
```

### Passo 2: Subir a Imagem para o AWS ECR
No painel da AWS, crie um repositório no Elastic Container Registry (ECR) chamado `munka-ml-jobs`. Faça o build e push:

```bash
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <seu-account-id>.dkr.ecr.us-east-2.amazonaws.com
docker build -t munka-ml-jobs ./src/ml
docker tag munka-ml-jobs:latest <seu-account-id>.dkr.ecr.us-east-2.amazonaws.com/munka-ml-jobs:latest
docker push <seu-account-id>.dkr.ecr.us-east-2.amazonaws.com/munka-ml-jobs:latest
```

### Passo 3: Configurar a "Task Definition" no ECS
Vá no AWS ECS e crie uma **Task Definition**:
* **Tipo:** Fargate.
* **Imagem:** A URI da imagem no ECR gerada no passo anterior.
* **CPU/RAM:** Defina recursos generosos (ex: 2 vCPU, 8GB de RAM) dependendo da necessidade do HPO.
* **IAM Role:** Adicione a *Task Execution Role* com permissões de acesso ao S3 e ao Snowflake (Secrets Manager).

### Passo 4: Refatorar a DAG do Airflow
No Airflow, você removerá o `BashOperator` (que rodava localmente) e passará a usar o provedor da AWS (`apache-airflow-providers-amazon`). O Airflow enviará o comando exato que o container na AWS deve rodar.

```python
from airflow import DAG
from airflow.providers.amazon.aws.operators.ecs import EcsRunTaskOperator
from datetime import datetime

with DAG("passo5_ml_hpo_aws", start_date=datetime(2023,1,1), catchup=False) as dag:

    # Em vez de rodar o bash local, disparamos a AWS!
    rodar_hpo_na_aws = EcsRunTaskOperator(
        task_id="hpo_sklearn_aws",
        cluster="munka-ecs-cluster", # Nome do cluster criado na AWS
        task_definition="munka-ml-task", # Definição criada no Passo 3
        launch_type="FARGATE",
        overrides={
            "containerOverrides": [
                {
                    "name": "munka-ml-container",
                    # Passamos o script que queremos rodar
                    "command": ["hpo.py", "--model", "sklearn"] 
                }
            ]
        },
        network_configuration={
            "awsvpcConfiguration": {
                "subnets": ["subnet-xyz123"],
                "securityGroups": ["sg-xyz123"],
                "assignPublicIp": "ENABLED"
            }
        },
        aws_conn_id="aws_default" # A mesma conexão que criamos pro S3!
    )
```

### Passo 5: Refatorar a Persistência (S3)
Como o container na AWS vai "morrer" assim que o script terminar, ele não pode salvar o `sklearn_best_model.joblib` localmente.
O código Python dentro do `train_best.py` deve fazer upload para o S3:

```python
import boto3
import joblib

# Salva localmente DENTRO do container Fargate
joblib.dump(final_model, "/tmp/sklearn_best_model.joblib")

# Faz upload para o bucket S3
s3 = boto3.client("s3")
s3.upload_file("/tmp/sklearn_best_model.joblib", "munka-dev-070980587239-us-east-2", "ml-artifacts/sklearn_best_model.joblib")
```

Na Inferência (Passo 6), o `batch_inference.py` fará o fluxo reverso: fará o download do S3 para a pasta temporária do Fargate, carregará o modelo e fará a inferência.

---

## 📈 Vantagens Dessa Arquitetura
1. **Performance Infinita:** O Optuna precisa de mais CPU? É só mudar um dropdown na AWS. O Airflow não sofre impacto.
2. **Isolamento Total:** Se o container de Machine Learning der um erro fatal de "Out of Memory" (OOM), o Airflow não cai junto.
3. **Custo-Eficiência:** A máquina do Fargate só é cobrada durante os minutos em que o HPO está rodando. O servidor do Airflow pode ser uma máquina super barata (T3.small) o mês inteiro.
