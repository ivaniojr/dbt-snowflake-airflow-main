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
        import snowflake.connector
        
        account = os.getenv("SNOWFLAKE_ACCOUNT")
        user = os.getenv("SNOWFLAKE_USER")
        password = os.getenv("SNOWFLAKE_PASSWORD")
        
        if not all([account, user, password]):
            raise ValueError("Credenciais Snowflake não configuradas.")
            
        ctx = snowflake.connector.connect(
            user=user,
            password=password,
            account=account,
            database="DRAGON_DB",
            schema="MUNKA_ML"
        )
        query = "SELECT * FROM ML_TAREFA_FEATURES"
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

def get_processed_dataset():
    """
    Retorna X_train, X_test, y_train, y_test 
    com Data Leakage evitado (StandardScaler ajustado APENAS no treino)
    """
    df = load_data()
    
    # Remover colunas não-numéricas/identificadores se existirem no dataset real
    cols_to_drop = ['TAREFA_ID', 'NOME_TAREFA', 'NOME_PROJETO', 'SPRINT_OBJETIVOS', 'NOME_COMPLEXIDADE', 'TOTAL_UST', 'SCORE_QUALIDADE_EVIDENCIA']
    df = df.drop(columns=[col for col in cols_to_drop if col in df.columns])
    
    # Preencher nulos (boa prática)
    df = df.fillna(0)
    
    X = df.drop(columns=['HORAS_EXECUTADAS'])
    y = df['HORAS_EXECUTADAS'].values.reshape(-1, 1)
    
    # Split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Feature Scaling (Crucial para Redes Neurais!)
    scaler_X = StandardScaler()
    scaler_y = StandardScaler() # Opcional, mas ajuda MLPs a convergirem melhor
    
    # O fit ocorre APENAS no X_train para evitar Vazamento de Dados!
    X_train_scaled = scaler_X.fit_transform(X_train)
    X_test_scaled = scaler_X.transform(X_test)
    
    y_train_scaled = scaler_y.fit_transform(y_train)
    y_test_scaled = scaler_y.transform(y_test)
    
    return X_train_scaled, X_test_scaled, y_train_scaled, y_test_scaled, scaler_y
