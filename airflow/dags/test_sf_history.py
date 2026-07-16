from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
import json

def check_history():
    hook = SnowflakeHook('snowflake_munka')
    with hook.get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
            SELECT FILE_NAME, STATUS, ROW_COUNT, ROW_PARSED, FIRST_ERROR_MESSAGE 
            FROM TABLE(DRAGON_DB.INFORMATION_SCHEMA.COPY_HISTORY(TABLE_NAME=>'DRAGON_DB.MUNKA.RAW_UNIDADE_ADM_SUPERIOR', START_TIME=> DATEADD(hours, -1, CURRENT_TIMESTAMP())))
            """)
            rows = cur.fetchall()
            print("COPY HISTORY:")
            for r in rows:
                print(r)

check_history()
