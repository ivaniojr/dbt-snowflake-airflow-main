"""
batch_inference.py
Pipeline de inferência contínua (Passo 6).
Este script carrega o modelo campeão e o scaler salvos no Passo 5,
recebe novas tarefas (mock ou do Snowflake) e prevê o esforço (HORAS_ESTIMADAS).
"""

import os
import sys
import joblib
import pandas as pd
import numpy as np
from datetime import datetime

# Adicionar o diretório atual ao path para poder importar mlp_numpy
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from mlp_numpy import NumPyMLPRegressor

# ──────────────────────────────────────────────
# 1. Obtenção de Dados Novos
# ──────────────────────────────────────────────
def get_new_tasks():
    """
    Tenta ler novas tarefas do Snowflake (onde HORAS_ESTIMADAS é NULL).
    Se não conseguir conectar, gera 100 tarefas mock para simular a fila de trabalho.
    """
    try:
        from cryptography.hazmat.backends import default_backend
        from cryptography.hazmat.primitives.asymmetric import rsa
        from cryptography.hazmat.primitives import serialization
        import snowflake.connector
        
        # Fonte Única de Verdade: Carregar variáveis de ambiente (.env)
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
        
        key_path = os.getenv(
            "DBT_SNOWFLAKE_PRIVATE_KEY_PATH",
            os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "dbt", "rsa_key.p8"))
        )
        
        if not os.path.isabs(key_path) and not os.path.exists(key_path):
            key_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "dbt", os.path.basename(key_path)))

        with open(key_path, "rb") as key:
            p_key = serialization.load_pem_private_key(
                key.read(), password=None, backend=default_backend()
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
        
        # Suponha que exista uma View/Tabela de novas tarefas
        query = f"SELECT * FROM {database}.{schema}.ML_TAREFA_FEATURES WHERE HORAS_EXECUTADAS IS NULL LIMIT 100"
        df = pd.read_sql(query, ctx)
        ctx.close()
        
        if df.empty:
            print(" [Aviso] Conexão com Snowflake obteve sucesso, mas a fila de tarefas sem HORAS_EXECUTADAS está vazia (0 registros).")
            print(" [Aviso] Para demonstração da DAG, gerando 100 tarefas simuladas na fila (Mock Data)...")
            return _generate_mock_tasks()

        print(" Novas tarefas carregadas do Snowflake!")
        return df
    except Exception as e:
        print(f" [Aviso] Falha ao conectar no Snowflake: {e}")
        print(" [Aviso] Gerando 100 tarefas simuladas na fila (Mock Data)...")
        return _generate_mock_tasks()

def _generate_mock_tasks():
    np.random.seed(datetime.now().microsecond)
    n_samples = 100
        
    return pd.DataFrame({
        'TAREFA_ID': [f"TASK-{i}" for i in range(1000, 1000 + n_samples)],
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
        'TAMANHO_TEXTO': np.random.randint(10, 2000, n_samples)
    })

# ──────────────────────────────────────────────
# 2. Pipeline de Inferência
# ──────────────────────────────────────────────
def run_batch_inference():
    print(f"\n{'='*55}")
    print(f" INFERÊNCIA EM LOTE (BATCH) - PASSO 6")
    print(f"{'='*55}")
    
    OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
    # Arquivos salvos no Passo 5
    sklearn_model_path = os.path.join(OUTPUT_DIR, "sklearn_best_model.joblib")
    numpy_model_path = os.path.join(OUTPUT_DIR, "numpy_best_model.npz")
    scaler_path = os.path.join(OUTPUT_DIR, "scaler.joblib")
    
    if not os.path.exists(sklearn_model_path) or not os.path.exists(scaler_path) or not os.path.exists(numpy_model_path):
        raise FileNotFoundError(
            f"Artefatos nao encontrados!\n"
            f"Certifique-se de que a DAG Passo 5 (Retreinamento) rodou com sucesso para gerar:\n"
            f"- {sklearn_model_path}\n"
            f"- {numpy_model_path}\n"
            f"- {scaler_path}"
        )
        
    print(f" Carregando Scaler: {scaler_path}")
    scaler = joblib.load(scaler_path)
    
    print(f" Carregando Modelo Campeão (Sklearn): {sklearn_model_path}")
    sklearn_model = joblib.load(sklearn_model_path)
    
    print(f" Carregando Modelo Campeão (NumPy): {numpy_model_path}")
    numpy_model = NumPyMLPRegressor.from_weights(numpy_model_path)
    
    df_new = get_new_tasks()
    
    if df_new.empty:
        print(" Nenhuma tarefa nova encontrada na fila. Encerrando.")
        return
        
    print(f" Total de tarefas na fila para prever: {len(df_new)}")
    
    # Salvar IDs para o resultado final
    if 'TAREFA_ID' in df_new.columns:
        task_ids = df_new['TAREFA_ID'].values
    else:
        task_ids = [f"UNKNOWN-{i}" for i in range(len(df_new))]
        
    # Filtrar apenas as colunas de features numéricas usadas no treinamento
    cols_to_drop = ['TAREFA_ID', 'NOME_TAREFA', 'NOME_PROJETO', 'SPRINT_OBJETIVOS', 
                    'NOME_COMPLEXIDADE', 'TOTAL_UST', 'SCORE_QUALIDADE_EVIDENCIA', 'HORAS_EXECUTADAS']
    X_raw = df_new.drop(columns=[col for col in cols_to_drop if col in df_new.columns])
    X_raw = X_raw.fillna(0)
    
    # 1. Normalizar usando o MESMO scaler do treinamento
    X_scaled = scaler.transform(X_raw.values)
    
    # 2. Predizer Sklearn
    print(" Processando inferência através do modelo Scikit-Learn...")
    preds_sklearn = sklearn_model.predict(X_scaled)
    
    # 3. Predizer NumPy
    print(" Processando inferência através do modelo NumPy Matemático...")
    preds_numpy = numpy_model.predict(X_scaled)
    
    # Criar DataFrame de Resultados
    df_results = pd.DataFrame({
        'TAREFA_ID': task_ids,
        'HORAS_ESTIMADAS_SKLEARN': np.round(preds_sklearn.flatten(), 2),
        'HORAS_ESTIMADAS_NUMPY': np.round(preds_numpy.flatten(), 2)
    })
    
    # Garantir que não haja previsões negativas bizarras em nenhum modelo
    df_results['HORAS_ESTIMADAS_SKLEARN'] = df_results['HORAS_ESTIMADAS_SKLEARN'].apply(lambda x: max(0.5, x))
    df_results['HORAS_ESTIMADAS_NUMPY'] = df_results['HORAS_ESTIMADAS_NUMPY'].apply(lambda x: max(0.5, x))
    
    # Adicionar uma coluna de Diferença Absoluta para comparação
    df_results['DIFERENCA_MODELOS'] = np.abs(df_results['HORAS_ESTIMADAS_SKLEARN'] - df_results['HORAS_ESTIMADAS_NUMPY']).round(2)
    
    # Salvar CSV
    output_csv = os.path.join(OUTPUT_DIR, "novas_previsoes.csv")
    df_results.to_csv(output_csv, index=False)
    
    print(f"{'='*55}")
    print(f" SUCESSO! {len(df_results)} previsões geradas.")
    print(f" Salvo em: {output_csv}")
    print(f"{'='*55}")
    
    # Mostrando amostra
    print(df_results.head(10))

if __name__ == "__main__":
    run_batch_inference()
