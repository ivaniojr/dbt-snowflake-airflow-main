from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

def run_copy():
    s3_hook = S3Hook(aws_conn_id='aws_default')
    credentials = s3_hook.get_credentials()
    
    hook = SnowflakeHook('snowflake_munka')
    with hook.get_conn() as conn:
        with conn.cursor() as cur:
            sql = f"""
            COPY INTO DRAGON_DB.MUNKA.RAW_UNIDADE_ADM_SUPERIOR
            FROM 's3://munka-dev-070980587239-us-east-2/unidade_adm_superior.csv'
            CREDENTIALS=(
                AWS_KEY_ID='{credentials.access_key}'
                AWS_SECRET_KEY='{credentials.secret_key}'
            )
            FILE_FORMAT=(
                TYPE='CSV'
                SKIP_HEADER=1
                FIELD_OPTIONALLY_ENCLOSED_BY='"'
                NULL_IF=('NULL', 'null', '')
            )
            """
            cur.execute(sql)
            rows = cur.fetchall()
            print("COPY RESULTS:")
            for r in rows:
                print(r)

run_copy()
