import os
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

def load_data():
    """
    Função principal que busca dados. 
    Tenta conectar ao Snowflake (Ouro/ML). Se falhar por falta de credenciais (ambiente local),
    gera um dataset sintético baseado nas colunas reais para simular e testar o treinamento auditável.
    """
    try:
        from cryptography.hazmat.backends import default_backend
        from cryptography.hazmat.primitives.asymmetric import rsa
        from cryptography.hazmat.primitives.asymmetric import dsa
        from cryptography.hazmat.primitives import serialization
        import snowflake.connector
        
        # Fonte Única de Verdade: Carregar variáveis de ambiente
        try:
            from dotenv import load_dotenv
            dotenv_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))
            if os.path.exists(dotenv_path):
                load_dotenv(dotenv_path)
        except ImportError:
            pass

        user = os.getenv("DBT_SNOWFLAKE_USER", "DRAGON")
        account = os.getenv("DBT_SNOWFLAKE_ACCOUNT", "sfedu02-gfb24387")
        role = os.getenv("DBT_SNOWFLAKE_ROLE", "TRAINING_ROLE")
        warehouse = os.getenv("DBT_SNOWFLAKE_WAREHOUSE", "DRAGON_WH")
        database = os.getenv("DBT_SNOWFLAKE_DATABASE", "DRAGON_DB")
        schema = os.getenv("DBT_SNOWFLAKE_ML_SCHEMA", "MUNKA_ML")
        key_path = os.getenv("DBT_SNOWFLAKE_PRIVATE_KEY_PATH", os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "dbt", "rsa_key.p8")))
        
        if not os.path.isabs(key_path) and not os.path.exists(key_path):
            key_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "dbt", os.path.basename(key_path)))

        with open(key_path, "rb") as key:
            p_key = serialization.load_pem_private_key(
                key.read(),
                password=None,
                backend=default_backend()
            )
        
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
        query = f"SELECT * FROM {database}.{schema}.ML_TAREFA_FEATURES"
        df = pd.read_sql(query, ctx)
        ctx.close()
        print("Dados carregados com sucesso do Snowflake!")
    except Exception as e:
        print(f"[Aviso] Falha ao conectar no Snowflake: {e}")
        print("[Aviso] Gerando dataset sintético baseado no schema para fins de execução e auditoria local.")
        df = generate_mock_data()
        
    return df

def generate_mock_data(n_samples=5000):
    """Gera um dataset mock imitando a tabela MUNKA_ML.ML_TAREFA_FEATURES"""
    np.random.seed(42)
    return pd.DataFrame({
        'FATOR_AJUSTE': np.random.uniform(0.5, 2.0, n_samples),
        'HET_MAX': np.random.randint(10, 100, n_samples),
        'QTD_IMAGENS': np.random.poisson(2, n_samples),
        'QTD_LINKS': np.random.poisson(1, n_samples),
        'TEM_CODIGO': np.random.randint(0, 2, n_samples),
        'TEM_SQL': np.random.randint(0, 2, n_samples),
        'TEM_COMMIT': np.random.randint(0, 2, n_samples),
        'TEM_ANEXO': np.random.randint(0, 2, n_samples),
        'FL_ENVOLVE_FRONTEND': np.random.randint(0, 2, n_samples),
        'FL_ENVOLVE_BACKEND': np.random.randint(0, 2, n_samples),
        'FL_ENVOLVE_DADOS': np.random.randint(0, 2, n_samples),
        'FL_IS_BUGFIX': np.random.randint(0, 2, n_samples),
        'QTD_BLOCOS_CODIGO': np.random.poisson(1, n_samples),
        'FL_TEM_PULL_REQUEST': np.random.randint(0, 2, n_samples),
        'TAMANHO_TEXTO': np.random.randint(10, 2000, n_samples),
        # Target: Simulação de Horas baseada linearmente em algumas features + ruído
        'HORAS_EXECUTADAS': np.random.uniform(2, 50, n_samples)
    })

def get_raw_dataset():
    """
    Retorna X, y brutos e a lista com o nome das features.
    O particionamento (K-Fold/Holdout) e a Normalização deverão ser
    feitos pelo script de orquestração para evitar Data Leakage.
    """
    df = load_data()
    
    # Remover colunas não-numéricas/identificadores se existirem no dataset real
    cols_to_drop = ['TAREFA_ID', 'NOME_TAREFA', 'NOME_PROJETO', 'SPRINT_OBJETIVOS', 'NOME_COMPLEXIDADE', 'TOTAL_UST', 'SCORE_QUALIDADE_EVIDENCIA']
    df = df.drop(columns=[col for col in cols_to_drop if col in df.columns])
    
    # Preencher nulos (boa prática) e converter para numérico limpo
    df = df.fillna(0)
    
    feature_names = [col for col in df.columns if col != 'HORAS_EXECUTADAS']
    X = np.nan_to_num(df.drop(columns=['HORAS_EXECUTADAS']).values, nan=0.0, posinf=0.0, neginf=0.0)
    y = np.nan_to_num(df['HORAS_EXECUTADAS'].values.reshape(-1, 1), nan=0.0, posinf=0.0, neginf=0.0)
    
    return X, y, feature_names

def get_train_test_split(test_size=0.2, random_state=42):
    """
    Função centralizada para partição reprodutiva em todo o projeto ML.
    Garante que 80% (4.000) fiquem em Treino/HPO e 20% (1.000) fiquem em Teste Holdout.
    """
    X, y, feature_names = get_raw_dataset()
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state
    )
    return X_train, X_test, y_train, y_test, feature_names

