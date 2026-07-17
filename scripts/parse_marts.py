import re
import os

SCRIPTS = [
    '/home/ivanio/IFG/Trabalho_Modulo2/dbt-snowflake-airflow-main/dbt-snowflake-airflow-main/scripts/03_dimensions.sql',
    '/home/ivanio/IFG/Trabalho_Modulo2/dbt-snowflake-airflow-main/dbt-snowflake-airflow-main/scripts/04_facts.sql'
]

OUTPUT_DIR = '/home/ivanio/IFG/Trabalho_Modulo2/dbt-snowflake-airflow-main/dbt-snowflake-airflow-main/src/dbt/models/marts/gold/'

# Create directory if it doesn't exist
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Regex to find CREATE OR REPLACE TABLE blocks
table_pattern = re.compile(r'CREATE OR REPLACE TABLE\s+([A-Z0-9_]+)\s+AS\n(.*?)(?=CREATE OR REPLACE TABLE|;$)', re.DOTALL | re.IGNORECASE)

for script_path in SCRIPTS:
    with open(script_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split content by ';' so we can grab each statement reliably
    statements = content.split(';')
    
    for stmt in statements:
        stmt = stmt.strip()
        if not stmt:
            continue
            
        match = re.search(r'CREATE OR REPLACE TABLE\s+([A-Z0-9_]+)\s+AS(.*)', stmt, re.DOTALL | re.IGNORECASE)
        if match:
            table_name = match.group(1).lower()
            sql_body = match.group(2).strip()
            
            # Replace STG_[TABLE] with {{ ref('stg_[table]') }}
            # using regex that captures the table name case insensitively
            def replace_stg(m):
                stg_table = m.group(1).lower()
                return f"{{{{ ref('{stg_table}') }}}}"
            
            sql_body = re.sub(r'\b(STG_[A-Z0-9_]+)\b', replace_stg, sql_body, flags=re.IGNORECASE)
            
            file_path = os.path.join(OUTPUT_DIR, f"{table_name}.sql")
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(sql_body + "\n")
            
            print(f"Created {table_name}.sql")

print("All marts created successfully.")
