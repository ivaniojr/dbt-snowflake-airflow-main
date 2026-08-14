"""
load_analise_retrospectiva.py
Carga independente da análise retrospectiva (analise_retrospectiva.csv)
diretamente para a tabela DRAGON_DB.MUNKA_ML.ML_ANALISE_RETROSPECTIVA no Snowflake.

Este script pode ser executado manualmente ou via DAG independente a qualquer momento.
"""

import os
import sys
import pandas as pd
import numpy as np

def load_to_snowflake():
    print(f"\n{'='*65}")
    print(" CARGA INDEPENDENTE: ANÁLISE RETROSPECTIVA -> SNOWFLAKE")
    print(f"{'='*65}")

    # 1. Localizar o CSV de análise retrospectiva
    base_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(base_dir, "analise_retrospectiva.csv")

    if not os.path.exists(csv_path):
        # Tentar caminho alternativo no seeds
        alt_path = os.path.abspath(os.path.join(base_dir, "..", "dbt", "seeds", "analise_retrospectiva.csv"))
        if os.path.exists(alt_path):
            csv_path = alt_path
        else:
            raise FileNotFoundError(
                f"Arquivo analise_retrospectiva.csv não encontrado em:\n- {csv_path}\n- {alt_path}\n"
                "Execute primeiro a inferência em lote (src/ml/batch_inference.py)."
            )

    print(f" Lendo arquivo CSV: {csv_path}")
    df = pd.read_csv(csv_path)
    print(f" Total de registros encontrados: {len(df)}")

    # 2. Carregar variáveis de ambiente e conectar ao Snowflake
    try:
        from dotenv import load_dotenv
        dotenv_path = os.path.abspath(os.path.join(base_dir, "..", "..", ".env"))
        if os.path.exists(dotenv_path):
            load_dotenv(dotenv_path)
    except ImportError:
        pass

    try:
        from cryptography.hazmat.backends import default_backend
        from cryptography.hazmat.primitives import serialization
        import snowflake.connector
        from snowflake.connector.pandas_tools import write_pandas

        user = os.getenv("DBT_SNOWFLAKE_USER", "DRAGON")
        account = os.getenv("DBT_SNOWFLAKE_ACCOUNT", "sfedu02-gfb24387")
        role = os.getenv("DBT_SNOWFLAKE_ROLE", "TRAINING_ROLE")
        warehouse = os.getenv("DBT_SNOWFLAKE_WAREHOUSE", "DRAGON_WH")
        database = os.getenv("DBT_SNOWFLAKE_DATABASE", "DRAGON_DB")
        schema = os.getenv("DBT_SNOWFLAKE_ML_SCHEMA", "MUNKA_ML")

        key_path = os.getenv(
            "DBT_SNOWFLAKE_PRIVATE_KEY_PATH",
            os.path.abspath(os.path.join(base_dir, "..", "dbt", "rsa_key.p8"))
        )
        if not os.path.isabs(key_path) and not os.path.exists(key_path):
            key_path = os.path.abspath(os.path.join(base_dir, "..", "dbt", os.path.basename(key_path)))

        print(f" Conectando ao Snowflake ({account}, DB: {database}, Schema: {schema})...")
        with open(key_path, "rb") as key:
            p_key = serialization.load_pem_private_key(key.read(), password=None, backend=default_backend())

        pkb = p_key.private_bytes(
            encoding=serialization.Encoding.DER,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )

        ctx = snowflake.connector.connect(
            user=user,
            account=account,
            private_key=pkb,
            role=role,
            warehouse=warehouse,
            database=database,
            schema=schema
        )

        cur = ctx.cursor()

        # 3. Garantir a criação da tabela no Snowflake caso não exista
        table_name = "ML_ANALISE_RETROSPECTIVA"
        ddl_create = f"""
        CREATE TABLE IF NOT EXISTS {database}.{schema}.{table_name} (
            TAREFA_ID VARCHAR(255),
            FONTE_DADOS VARCHAR(50),
            HORAS_EXECUTADAS FLOAT,
            HORAS_ESTIMADAS_SKLEARN FLOAT,
            HORAS_ESTIMADAS_NUMPY FLOAT,
            ERRO_SKLEARN FLOAT,
            ERRO_ABSOLUTO_SKLEARN FLOAT,
            ERRO_QUADRATICO_SKLEARN FLOAT,
            ERRO_PERCENTUAL_SKLEARN FLOAT,
            ERRO_NUMPY FLOAT,
            ERRO_ABSOLUTO_NUMPY FLOAT,
            ERRO_QUADRATICO_NUMPY FLOAT,
            ERRO_PERCENTUAL_NUMPY FLOAT,
            DIFERENCA_MODELOS FLOAT,
            MODELO_MAIS_PROXIMO VARCHAR(50),
            MODEL_SCOPE VARCHAR(100),
            FEATURE_SET_NAME VARCHAR(100),
            DATA_ANALISE TIMESTAMP_NTZ,
            DATA_CARGA_SNOWFLAKE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
        );
        """
        cur.execute(ddl_create)
        print(f" Tabela {database}.{schema}.{table_name} verificada/criada.")

        # 4. Tratar tipos do DataFrame antes de carregar
        df_load = df.copy()
        df_load.columns = [col.upper() for col in df_load.columns]
        df_load["TAREFA_ID"] = df_load["TAREFA_ID"].astype(str)
        df_load["FONTE_DADOS"] = df_load["FONTE_DADOS"].astype(str)
        df_load["DATA_ANALISE"] = pd.to_datetime(df_load["DATA_ANALISE"])

        # Substituir tabela existente com os dados mais recentes (ou append)
        # Limpar registros anteriores para idempotência da análise
        cur.execute(f"TRUNCATE TABLE {database}.{schema}.{table_name}")
        print(f" Tabela {table_name} truncada para nova carga completa.")

        # 5. Escrever dados usando write_pandas
        success, nchunks, nrows, _ = write_pandas(
            conn=ctx,
            df=df_load,
            table_name=table_name,
            database=database,
            schema=schema,
            auto_create_table=False,
            quote_identifiers=False
        )

        print(f"\n{'='*65}")
        if success:
            print(f" SUCESSO! {nrows} registros carregados com sucesso em {database}.{schema}.{table_name}.")
        else:
            print(f" [Aviso] Carga finalizada com status: {success}")
        print(f"{'='*65}\n")

        cur.close()
        ctx.close()

    except Exception as e:
        print(f" [Erro] Falha ao carregar dados no Snowflake: {e}")
        raise

if __name__ == "__main__":
    load_to_snowflake()
