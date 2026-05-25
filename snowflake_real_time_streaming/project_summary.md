# Real Time Streaming Project Summary

## AWS IAM
- Purpose: Grant necessary permissions to various AWS/External services/entities.
- Create `real-time-streaming-project-role` IAM Role with the following Custom Trust Policy JSON:
  ```
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "sts:AssumeRole"
              ],
              "Principal": {
                  "Service": [
                      "apigateway.amazonaws.com","lambda.amazonaws.com"
                  ]
              }
          }
      ]
  }
  ```
  - This allows AWS API Gateway and Lambda to assume this role.
  - The role will be granted the following permissions:
    - `AWSLambda_FullAccess` - Used by API Gateway to invoke the lambda function.
    - `AmazonKinesisFullAccess` - Used by the lambda function to write data to the kinesis data stream.
    - `AmazonS3FullAccess` - Used by the lambda function to write data to the S3 bucket.
    - `CloudWatchLogsFullAccess` - Used by Lambda and Kinesis to write logs to CloudWatch.

## AWS S3
- Purpose: Store incoming data.
- This project requires two S3 buckets. One bucket will store the data coming through API Gateway, Lambda, Kinesis Data Stream, and Kinesis Firehose. The second bucket will store erroneous data that flows through this path.
- Create a `real-time-streaming-data-bucket` with default settings.
  - Create a `data` folder to store the data flowing in from API Gateway, Lambda, Kinesis Data Stream, and Kinesis Firehose.
- Create a `real-time-streaming-error-bucket` with default settings.

## AWS Kinesis
- Purpose (Kinesis Data Stream): Collect, process, and analyze data streams **in real time**. In this project, the data will be collected from the Lambda function.
- Purpose (Kinesis Firehose): Capture, transform, and deliver data to S3 buckets.
- Create a `real-time-streaming-data-stream` Kinesis data stream with default settings.
- Create a Kinesis Firehose, using the auto-generated name.
  - Name: `KDS-S3-91aBT`
  - Select the source as Amazon Kinesis Data Streams, specifying the `real-time-streaming-data-stream` data stream.
  - Select the the destination as Amazon S3, specifying the `real-time-streaming-data-bucket` bucket.
  - Specify the S3 bucket prefix as `data/`, referring to the `data` folder created within the bucket.
- Specify the buffer size and interval as 1 MB and 5 seconds, respectively.
- Specify the file extension format as `.json`.

## Lambda
- Purpose: Receive data from API Gateway and write it to the `real-time-streaming-data-stream` Kinesis data stream.
- Create a `real-time-streaming-project-lambda` Lambda function using the 'Author from scratch mode'.
  - For Runtime, select the latest version of Python.
  - For Architecture, use x86_64.
  - Use the `real-time-streaming-project-role` as the execution role.
- Replace the default code in the lambda function with the following code:
  ```
  import json
  import boto3 
  import sys
  from datetime import datetime

  streamname = 'real-time-streaming-data-stream'
  errorbucketname = 'real-time-streaming-error-bucket'

  # Initialize clients
  s3_client = boto3.client('s3')
  kinesis_client = boto3.client('kinesis')
  timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

  def lambda_handler(event, context):
      try:
          # Example code logic to process API Gateway event
          # Assuming API Gateway passes JSON data in the event
          data = json.loads(event['body'])     

          # Check if 'Id' column exists and is blank    
          if 'Id' in data and (data['Id'] is None or data['Id'] == ''): 
              # Include the timestamp in the object key
              object_key = f'error/error_{timestamp}.json'

              # Write data to S3 bucket for error handling
              s3_client.put_object(Bucket=errorbucketname,Key=object_key,Body=json.dumps(data))

              response = {'statusCode': 200,'body': json.dumps({'message': 'Error JSON Data loaded successfully'}),'headers': {'Content-Type': 'application/json'}}

              return response
          else:
              print('Writing to Amazon Kinesis stream')
              kinesis_client.put_record(StreamName=streamname, Data=json.dumps(data), PartitionKey='1' )

              response = {'statusCode': 200,'body': json.dumps({'message': 'JSON Data loaded successfully'}),'headers': {'Content-Type': 'application/json'}}

              return response

      except Exception as e:
          print(f'Error processing event: {e}')

          error_response = {'statusCode': 500,'body': json.dumps(f'Error processing event: {e}'),'headers': {'Content-Type': 'application/json'}}

          return error_response
  ```
- Once the code is updated, deploy it for the changes to take effect.

## API Gateway
- Purpose: Receive data from external API tool (Postman) and send it to the Lambda function.
- Create a new `real-time-streaming-project-api` REST API using a regional endpoint type.
- Create a proxy resource within the `real-time-streaming-project-api` API. Specify the resource name as `{proxy+}`.
- Edit the `ANY` method integration specified under the `{proxy+}` resource.
  - Specify the integration type as Lambda.
  - Enable Lambda proxy integration. Specify the `real-time-streaming-project-lambda` Lambda function and the `real-time-streaming-project-role` role ARN.
  - Create a `deployment` stage and deploy the API to that stage.

## Snowflake
- Purpose: Auto-ingest data from S3 bucket into a Snowflake table for analytical purposes.
- Create a `real-time-streaming-snowpipe-role` IAM role to grant permission for the Snowpipe to gather data from S3.
  - Select AWS account as the trusted entity type and choose the current AWS account.
  - Enable external ID requirement (best practice for roles that are assumed by third parties).
  - Provide a temporary external ID of '12345'.
  - Add AmazonS3FullAccess to the role's permissions policies.
- Create a snowpipe in snowflake.
  - Use the `notification_channel` property to create an S3 event notification. Specify `data/` as the prefix and notify on all object create events. Specify the destination as the SQS queue (`notification_channel`) associated with the snowpipe. This will allow the snowpipe to automatically ingest data as it lands in the S3 bucket.

## Postman
- Purpose: Test the flow of data to the tables created in Snowflake by sending POST requests to the API Gateway endpoint. The endpoint is the invoke URL for the stage that was created during the API Gateway setup.
  - Under this stage, the `{proxy+}` method will have endpoints for each HTTP method, which may all be the same or unique. Use the invoke URL for the POST method.
  - Under Authorization, select 'No Auth'.
  - Under Headers, specify a key of 'Content-Type' and a value of 'application/json'.
  - Under Body, specify 'raw' and paste the JSON payload:
    ```
    {
      "Id":"1",
      "Name":"John",
      "Age":"10",
      "Sex":"Male"
    }
    ```