# Airflow:2.10 no Docker
Airflow 2.10 rodando no Docker. 

## Pré-requisitos
* Docker

## Como instalar o Docker?
https://www.youtube.com/watch?v=pRFzDVn40rw&list=PLbPvnlmz6e_L_3Zw_fGtMcMY0eAOZnN-H

## Como instalar o Airflow?
Clone o repositório
```

Entre na pasta
```
cd airflow
```

Execute o comando para baixar as imagens e rodar os containers
```
sudo docker compose up -d
```

## Warning
Possivelmente vai dar um erro pela falta da Network. Para criar a network utilize o comando:
```
docker create network network-bigdata
```

Depois de criar, execute novamente o comando para rodar o container.

## Como acessar o Airflow?
localhost:8081

---------------------------------------------

Exemplo Airflow UI:

![image](assets/sample-airflow-ui.png)

---------------------------------------------

## Credenciais

username: airflow

password: airflow

---------------------------------------------

## Conclusão
Parabéns! você já tem o Airflow rodando no Docker.

## 📚 Referências
https://airflow.apache.org/docs/apache-airflow/stable/installation/index.html

## Developer
| Desenvolvedor      | LinkedIn                                   | Email                        | Portfólio                              |
|--------------------|--------------------------------------------|------------------------------|----------------------------------------|

