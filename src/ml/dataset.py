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
        
        # Caminho relativo para a chave rsa_key.p8 na raiz src/dbt
        private_key_file = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "dbt", "rsa_key.p8"))
        
        with open(private_key_file, "rb") as key:
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
            user="DRAGON",
            account="sfedu02-gfb24387",
            private_key=pkb,
            role="TRAINING_ROLE",
            warehouse="DRAGON_WH",
            database="DRAGON_DB",
            schema="MUNKA_ML"
        )
        query = "SELECT * FROM DRAGON_DB.MUNKA_ML.ML_TAREFA_FEATURES"
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
    
    # Preencher nulos (boa prática)
    df = df.fillna(0)
    
    feature_names = [col for col in df.columns if col != 'HORAS_EXECUTADAS']
    X = df.drop(columns=['HORAS_EXECUTADAS']).values
    y = df['HORAS_EXECUTADAS'].values.reshape(-1, 1)
    
    return X, y, feature_names
