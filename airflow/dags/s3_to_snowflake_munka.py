from __future__ import annotations
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator


DAG_ID = "s3_to_snowflake_munka_raw"
SNOWFLAKE_CONN_ID = "snowflake_munka"
AWS_CONN_ID = "aws_default"

S3_BUCKET = "munka-dev-070980587239-us-east-2"
S3_REGION = "us-east-2"

DEFAULT_ARGS = {
    "owner": "engenharia_dados",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=1),
}

TABLES = [
    'RAW_AB_PERMISSION', 'RAW_AB_PERMISSION_VIEW', 'RAW_AB_PERMISSION_VIEW_ROLE', 
    'RAW_AB_REGISTER_USER', 'RAW_AB_ROLE', 'RAW_AB_USER', 'RAW_AB_USER_ROLE', 
    'RAW_AB_VIEW_MENU', 'RAW_AJUSTE', 'RAW_ALEMBIC_VERSION', 'RAW_ANEXOS', 
    'RAW_CARGO', 'RAW_CENARIO', 'RAW_COMENTARIO', 'RAW_COMPLEXIDADE', 
    'RAW_CONTRATO', 'RAW_CONTRATOS_USUARIOS', 'RAW_COORD_PROJETO', 'RAW_COORDENACAO', 
    'RAW_ETIQUETA', 'RAW_FATOR_COMPLEXIDADE_UST', 'RAW_FATURA', 'RAW_FICHA_INDICADOR', 
    'RAW_FICHAS_PROJETOS', 'RAW_LIDER_PROJETOS', 'RAW_NIVEL', 'RAW_NIVEL_SUPERIOR', 
    'RAW_OBJETIVO', 'RAW_ORIGEM', 'RAW_ORIGENS_PROJETO', 'RAW_PRODUTO', 'RAW_PROJETO', 
    'RAW_PROJETO_RESULTADO_CHAVE', 'RAW_REAJUSTE', 'RAW_REGRA', 'RAW_RENOVACAO', 
    'RAW_REQUISITO', 'RAW_RESULTADO_CHAVE', 'RAW_SERVICO', 'RAW_SPRINT', 'RAW_STATUS', 
    'RAW_TAREFA', 'RAW_TAREFAS_CENARIOS', 'RAW_TECNOLOGIA', 'RAW_TECNOLOGIAS_PROJETO', 
    'RAW_TIPO', 'RAW_TIPO_STATUS', 'RAW_UNIDADE_ADM', 'RAW_UNIDADE_ADM_SUPERIOR'
]

def get_copy_query(table_name: str) -> str:
    """Gera o comando COPY INTO com Jinja para injetar credenciais da AWS."""
    # O nome do arquivo no S3
    file_name = table_name.replace("RAW_", "").lower() + ".csv"
    
    # Monta a query usando Jinja template para as credenciais
    sql = f"""
    COPY INTO {table_name}
    FROM 's3://{S3_BUCKET}/{file_name}'
    CREDENTIALS=(
        AWS_KEY_ID='{{{{ conn.{AWS_CONN_ID}.login }}}}'
        AWS_SECRET_KEY='{{{{ conn.{AWS_CONN_ID}.password }}}}'
    )
    FILE_FORMAT=(
        TYPE='CSV'
        SKIP_HEADER=1
        FIELD_OPTIONALLY_ENCLOSED_BY='"'
        NULL_IF=('NULL', 'null', '')
        ERROR_ON_COLUMN_COUNT_MISMATCH=FALSE
    )
    ON_ERROR='CONTINUE';
    """
    return sql

with DAG(
    dag_id=DAG_ID,
    default_args=DEFAULT_ARGS,
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=["snowflake", "s3", "munka", "raw", "load"],
) as dag:

    for table in TABLES:
        load_task = SnowflakeOperator(
            task_id=f"load_{table.lower()}",
            snowflake_conn_id=SNOWFLAKE_CONN_ID,
            database="DRAGON_DB",
            schema="MUNKA",
            sql=get_copy_query(table),
            execution_timeout=timedelta(minutes=5),
        )
