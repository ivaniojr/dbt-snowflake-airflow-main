import os
import re
import yaml

MARTS_DIR = '/home/ivanio/IFG/Trabalho_Modulo2/dbt-snowflake-airflow-main/dbt-snowflake-airflow-main/src/dbt/models/marts/gold/'
SCHEMA_PATH = os.path.join(MARTS_DIR, 'schema.yml')

models = []

for filename in sorted(os.listdir(MARTS_DIR)):
    if filename.endswith('.sql'):
        model_name = filename[:-4]
        file_path = os.path.join(MARTS_DIR, filename)
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Try to find the first SK_ column or ID_ column to use as unique key for testing
        primary_key = None
        
        # Look for AS SK_...
        sk_match = re.search(r'AS\s+(SK_[A-Z0-9_]+)', content, re.IGNORECASE)
        if sk_match:
            primary_key = sk_match.group(1).upper()
        else:
            # Look for AS ID_...
            id_match = re.search(r'AS\s+(ID_[A-Z0-9_]+)', content, re.IGNORECASE)
            if id_match:
                primary_key = id_match.group(1).upper()
                
        model_dict = {
            'name': model_name,
            'description': f'Modelo dimensional {model_name} criado automaticamente a partir do legado.'
        }
        
        if primary_key:
            model_dict['columns'] = [
                {
                    'name': primary_key,
                    'description': 'Chave primária da tabela.',
                    'tests': ['unique', 'not_null']
                }
            ]
            
        models.append(model_dict)

schema_data = {
    'version': 2,
    'models': models
}

with open(SCHEMA_PATH, 'w', encoding='utf-8') as f:
    yaml.dump(schema_data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print(f"Generated {SCHEMA_PATH} with {len(models)} models.")
