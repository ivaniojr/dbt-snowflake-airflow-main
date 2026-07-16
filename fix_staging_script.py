with open('scripts/02_staging.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

sql = sql.replace("USE SCHEMA MUNKA_RAW;", "USE SCHEMA MUNKA_STG;")
sql = sql.replace("FROM RAW_", "FROM MUNKA_RAW.RAW_")

with open('scripts/02_staging.sql', 'w', encoding='utf-8') as f:
    f.write(sql)
