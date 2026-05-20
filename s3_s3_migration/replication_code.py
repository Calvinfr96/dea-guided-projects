import boto3
import json

 
# Get the S3 client

s3 = boto3.client('s3')


def lambda_handler(event, context):

    # Get the list of records from the event

    print(event)

    records = event['Records']


    # Iterate through the records and copy the files from the source bucket to the destination bucket

    for record in records:

        di = record['body']

        result = json.loads(di)

        message=json.loads(result['Message'])

        source_bucket = message['Records'][0]['s3']['bucket']['name']

        key = message['Records'][0]['s3']['object']['key']

        print('key',key)

        copy_source = {'Bucket': source_bucket, 'Key': key}

        s3.copy_object(Bucket='dms-retail-mysql-region-2a', CopySource=copy_source, Key=key) # Replace with your destination bucket name

        print('File moved successfully')