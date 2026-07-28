"""
batch_inference.py
Pipeline de inferência contínua (Passo 6).
Este script carrega o modelo campeão e o scaler salvos no Passo 5,
recebe novas tarefas (mock ou do Snowflake) e prevê o esforço (HORAS_ESTIMADAS).
"""

import os
import joblib
import pandas as pd
import numpy as np
from datetime import datetime

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
        
        private_key_file = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "dbt", "rsa_key.p8"))
        
        with open(private_key_file, "rb") as key:
            p_key = serialization.load_pem_private_key(
                key.read(), password=None, backend=default_backend()
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
        
        # Suponha que exista uma View/Tabela de novas tarefas
        query = "SELECT * FROM DRAGON_DB.MUNKA_ML.ML_TAREFA_FEATURES WHERE HORAS_EXECUTADAS IS NULL LIMIT 100"
        df = pd.read_sql(query, ctx)
        ctx.close()
        print(" Novas tarefas carregadas do Snowflake!")
        return df
    except Exception as e:
        print(f" [Aviso] Falha ao conectar no Snowflake: {e}")
        print(" [Aviso] Gerando 100 tarefas simuladas na fila (Mock Data)...")
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
    model_path = os.path.join(OUTPUT_DIR, "sklearn_best_model.joblib")
    scaler_path = os.path.join(OUTPUT_DIR, "scaler.joblib")
    
    if not os.path.exists(model_path) or not os.path.exists(scaler_path):
        raise FileNotFoundError(
            f"Artefatos nao encontrados!\n"
            f"Certifique-se de que a DAG Passo 5 (Retreinamento) rodou com sucesso para gerar:\n"
            f"- {model_path}\n"
            f"- {scaler_path}"
        )
        
    print(f" Carregando Scaler: {scaler_path}")
    scaler = joblib.load(scaler_path)
    
    print(f" Carregando Modelo Campeão: {model_path}")
    model = joblib.load(model_path)
    
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
    
    # 2. Predizer
    print(" Processando inferência através da Rede Neural...")
    predictions = model.predict(X_scaled)
    
    # Criar DataFrame de Resultados
    df_results = pd.DataFrame({
        'TAREFA_ID': task_ids,
        'HORAS_ESTIMADAS': np.round(predictions, 2)
    })
    
    # Garantir que não haja previsões negativas bizarras
    df_results['HORAS_ESTIMADAS'] = df_results['HORAS_ESTIMADAS'].apply(lambda x: max(0.5, x))
    
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
