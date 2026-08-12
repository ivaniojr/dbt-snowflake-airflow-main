"""
evaluate_batch.py
Realiza a análise comparativa entre os modelos NumPy e Scikit-Learn.
Carrega um lote de dados conhecidos (onde HORAS_EXECUTADAS IS NOT NULL),
gera as previsões usando os modelos treinados (Passo 5) e calcula
a taxa de erros e acertos (tolerância de 10%).
"""

import os
import sys
import joblib
import pandas as pd
import numpy as np
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# Adicionar o diretório atual ao path para importações
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from mlp_numpy import NumPyMLPRegressor
from dataset import load_data

def evaluate_models():
    print(f"\n{'='*55}")
    print(f" AVALIAÇÃO COMPARATIVA DE MODELOS (PASSO 6)")
    print(f"{'='*55}")

    OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
    sklearn_model_path = os.path.join(OUTPUT_DIR, "sklearn_best_model.joblib")
    sklearn_restricted_path = os.path.join(OUTPUT_DIR, "sklearn_restricted_best_model.joblib")
    numpy_model_path = os.path.join(OUTPUT_DIR, "numpy_best_model.npz")
    scaler_path = os.path.join(OUTPUT_DIR, "scaler.joblib")
    
    if not os.path.exists(sklearn_model_path) or not os.path.exists(scaler_path) or not os.path.exists(numpy_model_path) or not os.path.exists(sklearn_restricted_path):
        raise FileNotFoundError(
            f"Artefatos nao encontrados! Rode o Passo 5 primeiro."
        )

    print("Carregando dados históricos do Snowflake...")
    # Usamos load_data() para manter a TAREFA_ID para o relatório
    df = load_data()
    
    # Remover tarefas que não tem horas executadas (as que estão na fila de inferência)
    if 'HORAS_EXECUTADAS' in df.columns:
        df = df.dropna(subset=['HORAS_EXECUTADAS'])
        
    if df.empty or 'HORAS_EXECUTADAS' not in df.columns:
        print("Sem dados para avaliação (nenhuma tarefa com HORAS_EXECUTADAS encontrada).")
        return

    # Usar um subconjunto aleatório como lote de avaliação (ex: 200 tarefas)
    df_eval = df.sample(n=min(200, len(df)), random_state=42).copy()
    
    # Preservar IDs e Target Real
    task_ids = df_eval['TAREFA_ID'].values if 'TAREFA_ID' in df_eval.columns else [f"EVAL-{i}" for i in range(len(df_eval))]
    y_real = df_eval['HORAS_EXECUTADAS'].values.reshape(-1, 1)

    # Preparar features
    cols_to_drop = ['TAREFA_ID', 'NOME_TAREFA', 'NOME_PROJETO', 'SPRINT_OBJETIVOS', 
                    'NOME_COMPLEXIDADE', 'TOTAL_UST', 'SCORE_QUALIDADE_EVIDENCIA', 'HORAS_EXECUTADAS']
    X_raw = df_eval.drop(columns=[col for col in cols_to_drop if col in df_eval.columns])
    X_raw = X_raw.fillna(0).values

    print(f"Lote de Avaliação: {len(X_raw)} tarefas")

    print(f"Carregando Scaler e Modelos...")
    scaler = joblib.load(scaler_path)
    X_scaled = scaler.transform(X_raw)

    sklearn_model = joblib.load(sklearn_model_path)
    sklearn_restricted_model = joblib.load(sklearn_restricted_path)
    numpy_model = NumPyMLPRegressor.from_weights(numpy_model_path)

    print("Gerando previsões...")
    preds_sklearn = sklearn_model.predict(X_scaled).flatten()
    preds_sklearn_restricted = sklearn_restricted_model.predict(X_scaled).flatten()
    preds_numpy = numpy_model.predict(X_scaled).flatten()
    y_real_flat = y_real.flatten()

    # Prevenir previsões bizarras negativas
    preds_sklearn = np.maximum(0.5, preds_sklearn)
    preds_sklearn_restricted = np.maximum(0.5, preds_sklearn_restricted)
    preds_numpy = np.maximum(0.5, preds_numpy)

    df_results = pd.DataFrame({
        'TAREFA_ID': task_ids,
        'HORAS_REAIS': np.round(y_real_flat, 2),
        'PREVISAO_SKLEARN': np.round(preds_sklearn, 2),
        'PREVISAO_SKLEARN_RESTRICTED': np.round(preds_sklearn_restricted, 2),
        'PREVISAO_NUMPY': np.round(preds_numpy, 2)
    })

    # Critério de Acerto: erro <= 10% do valor real
    def calculate_hit_rate(y_r, y_p):
        margem = 0.10 * y_r
        acertos = np.abs(y_p - y_r) <= margem
        taxa = (np.sum(acertos) / len(y_r)) * 100
        return taxa, acertos

    taxa_acerto_sklearn, acertos_sklearn = calculate_hit_rate(y_real_flat, preds_sklearn)
    taxa_acerto_sk_rest, acertos_sk_rest = calculate_hit_rate(y_real_flat, preds_sklearn_restricted)
    taxa_acerto_numpy, acertos_numpy = calculate_hit_rate(y_real_flat, preds_numpy)

    df_results['ACERTO_SKLEARN (10%)'] = acertos_sklearn
    df_results['ACERTO_SK_RESTRICTED (10%)'] = acertos_sk_rest
    df_results['ACERTO_NUMPY (10%)'] = acertos_numpy

    # Exportar resultados
    output_csv = os.path.join(OUTPUT_DIR, "evaluation", "comparativo_modelos.csv")
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)
    df_results.to_csv(output_csv, index=False)

    print(f"\n{'='*55}")
    print(f" RESULTADO DA AVALIAÇÃO COMPARATIVA")
    print(f"{'='*55}")
    print("Métricas Scikit-Learn:")
    print(f"  - MAE: {mean_absolute_error(y_real_flat, preds_sklearn):.2f} h")
    print(f"  - MSE: {mean_squared_error(y_real_flat, preds_sklearn):.2f}")
    print(f"  - R2 Score: {r2_score(y_real_flat, preds_sklearn):.4f}")
    print(f"  - Taxa de Acertos (Erro <= 10%): {taxa_acerto_sklearn:.1f}%")
    print(f"  - Taxa de Erros: {100 - taxa_acerto_sklearn:.1f}%")
    
    print("\nMétricas Sklearn Restricted (Exata arquitetura do NumPy):")
    print(f"  - MAE: {mean_absolute_error(y_real_flat, preds_sklearn_restricted):.2f} h")
    print(f"  - MSE: {mean_squared_error(y_real_flat, preds_sklearn_restricted):.2f}")
    print(f"  - R2 Score: {r2_score(y_real_flat, preds_sklearn_restricted):.4f}")
    print(f"  - Taxa de Acertos (Erro <= 10%): {taxa_acerto_sk_rest:.1f}%")
    print(f"  - Taxa de Erros: {100 - taxa_acerto_sk_rest:.1f}%")

    print("\nMétricas NumPy:")
    print(f"  - MAE: {mean_absolute_error(y_real_flat, preds_numpy):.2f} h")
    print(f"  - MSE: {mean_squared_error(y_real_flat, preds_numpy):.2f}")
    print(f"  - R2 Score: {r2_score(y_real_flat, preds_numpy):.4f}")
    print(f"  - Taxa de Acertos (Erro <= 10%): {taxa_acerto_numpy:.1f}%")
    print(f"  - Taxa de Erros: {100 - taxa_acerto_numpy:.1f}%")
    print(f"{'='*55}")
    print(f"Relatório salvo em: {output_csv}")

if __name__ == "__main__":
    evaluate_models()
