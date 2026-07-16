from airflow.providers.amazon.aws.hooks.s3 import S3Hook

def list_bucket():
    s3 = S3Hook(aws_conn_id='aws_default')
    keys = s3.list_keys(bucket_name='munka-dev-070980587239-us-east-2')
    print("Files in bucket:")
    if keys:
        for k in keys[:20]:
            print(k)
    else:
        print("Bucket is empty or no access.")

list_bucket()
