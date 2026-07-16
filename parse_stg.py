import re
import os

with open('scripts/02_staging.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

# Make the staging directory
os.makedirs('src/dbt/models/staging', exist_ok=True)

# Regex to match view creation blocks
# Using re.DOTALL to match across newlines
pattern = re.compile(r'CREATE OR REPLACE VIEW (STG_\w+) AS\s+(SELECT.*?FROM (RAW_\w+).*?);', re.DOTALL | re.IGNORECASE)

matches = pattern.findall(sql)
print(f"Found {len(matches)} views.")

for view_name, select_stmt, raw_table in matches:
    model_name = view_name.lower()
    source_table = raw_table.lower()
    
    # Replace the FROM clause
    # Note: we need to handle whitespace carefully
    from_pattern = re.compile(r'FROM\s+' + re.escape(raw_table), re.IGNORECASE)
    new_select = from_pattern.sub(f"FROM {{{{ source('munka_raw', '{source_table}') }}}}", select_stmt)
    
    file_path = f"src/dbt/models/staging/{model_name}.sql"
    with open(file_path, 'w', encoding='utf-8') as out_f:
        out_f.write(new_select.strip() + "\n")

print("Done generating dbt models.")
