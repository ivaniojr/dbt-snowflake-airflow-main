"""
config.py — Central de Parametrizações de Machine Learning (Projeto MUNKA)
===========================================================================
Este arquivo centraliza TODOS os parâmetros de amostragem, particionamento,
treinamento, otimização (HPO), validação e inferência do módulo de Machine Learning.

Qualquer alteração feita aqui reflete automaticamente em todos os scripts:
- dataset.py
- hpo.py
- train.py
- train_best.py
- batch_inference.py
- export_evaluation_dataset.py

Você pode alterar os valores diretamente nas variáveis Python abaixo ou
definir variáveis de ambiente com os mesmos nomes no arquivo .env.
===========================================================================
"""

import os

# ===========================================================================
# 1. VOLUME DE DADOS & EXTRAÇÃO DO SNOWFLAKE (dataset.py)
# ===========================================================================

# Quantidade de tarefas com HORAS_EXECUTADAS a extrair do Snowflake para Treino/ML.
# - Defina um número inteiro (ex: 5000, 10000, 50000) para amostragem controlada.
# - Defina None para extrair TODAS as 157.873 tarefas executadas da base completa.
# Variável de ambiente correspondente: ML_DATASET_SAMPLE_SIZE
_sample_env = os.getenv("ML_DATASET_SAMPLE_SIZE", "50000")
DATASET_SAMPLE_SIZE = int(_sample_env) if _sample_env and _sample_env.upper() != "NONE" else None

# Quantidade de tarefas sintéticas geradas no modo offline/fallback local.
# Usado quando não há conexão ativa com o Snowflake.
DATASET_MOCK_SIZE = int(os.getenv("ML_MOCK_SAMPLE_SIZE", "5000"))


# ===========================================================================
# 2. PARTICIONAMENTO DE DADOS (dataset.py & hpo.py)
# ===========================================================================

# Proporção do conjunto de Teste Cego (Holdout) intocado para avaliação final.
# Exemplo: 0.2 = 20% para teste final e 80% para treinamento/validação.
TEST_SPLIT_SIZE = float(os.getenv("ML_TEST_SIZE", "0.2"))

# Semente pseudo-aleatória global para reprodutibilidade científica exata.
RANDOM_STATE = int(os.getenv("ML_RANDOM_STATE", "42"))

# Proporção de Validação Interna usada durante o HPO (Optuna).
# Exemplo: 0.2 = 20% dos dados de treino são reservados para medir o MSE a cada trial.
HPO_VAL_SPLIT_SIZE = float(os.getenv("ML_HPO_VAL_SIZE", "0.2"))


# ===========================================================================
# 3. VALIDAÇÃO CRUZADA (train.py & train_best.py)
# ===========================================================================

# Número de dobras (folds) para o K-Fold Cross Validation.
# Exemplo: 5 = 5-Fold CV (80% treino / 20% validação em cada fold).
KFOLD_N_SPLITS = int(os.getenv("ML_KFOLD_SPLITS", "5"))


# ===========================================================================
# 4. OTIMIZAÇÃO DE HIPERPARÂMETROS — HPO / OPTUNA (hpo.py)
# ===========================================================================

# Quantidade de épocas máximas de treinamento por trial durante o HPO.
HPO_EPOCHS = int(os.getenv("ML_HPO_EPOCHS", "150"))

# Quantidade de tentativas (trials) executadas pelo Optuna para o Scikit-Learn.
HPO_N_TRIALS_SKLEARN = int(os.getenv("ML_HPO_TRIALS_SKLEARN", "10"))

# Quantidade de tentativas (trials) executadas pelo Optuna para o NumPy.
HPO_N_TRIALS_NUMPY = int(os.getenv("ML_HPO_TRIALS_NUMPY", "10"))

# Tempo limite máximo (em segundos) para a busca do Optuna (1800s = 30 minutos).
HPO_TIMEOUT_SECONDS = int(os.getenv("ML_HPO_TIMEOUT", "1800"))


# ===========================================================================
# 5. INFERÊNCIA RETROSPECTIVA EM LOTE — PASSO 6 (batch_inference.py)
# ===========================================================================

# Quantidade de tarefas executadas a serem extraídas do Snowflake para a
# análise retrospectiva em lote (Passo 6), gerando analise_retrospectiva.csv.
# - Defina um número (ex: 100, 500, 1000) para auditoria em lote.
# - Defina None para processar todas as tarefas executadas.
_batch_env = os.getenv("ML_BATCH_INFERENCE_SAMPLE_SIZE", "1000")
BATCH_INFERENCE_SAMPLE_SIZE = int(_batch_env) if _batch_env and _batch_env.upper() != "NONE" else None

# Quantidade de tarefas geradas no fallback sintético do Passo 6.
BATCH_INFERENCE_MOCK_SIZE = int(os.getenv("ML_BATCH_INFERENCE_MOCK_SIZE", "1000"))


# ===========================================================================
# 6. AUDITORIA QUALITATIVA DE HOMOLOGAÇÃO (export_evaluation_dataset.py)
# ===========================================================================

# Quantidade de amostras do teste Holdout exportadas no CSV de auditoria de erros.
AUDIT_SAMPLE_SIZE = int(os.getenv("ML_AUDIT_SAMPLE_SIZE", "150"))
