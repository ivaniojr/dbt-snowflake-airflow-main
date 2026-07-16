from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

def check_data():
    hook = SnowflakeHook('snowflake_munka')
    with hook.get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM DRAGON_DB.MUNKA.RAW_UNIDADE_ADM_SUPERIOR")
            count = cur.fetchone()[0]
            print(f"Count for RAW_UNIDADE_ADM_SUPERIOR: {count}")
            
            if count > 0:
                cur.execute("SELECT * FROM DRAGON_DB.MUNKA.RAW_UNIDADE_ADM_SUPERIOR LIMIT 1")
                print("Sample data:", cur.fetchone())

check_data()
