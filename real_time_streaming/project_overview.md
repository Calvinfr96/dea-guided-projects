# Real Time Streaming Project

## Objective
The objective of this project is to create a real-time data streaming pipeline that captures, processes, and stores data using AWS services and Snowflake. The pipeline will simulate data ingestion via Postman, process it through AWS services (API Gateway, Lambda, Kinesis, Firehose, and S3), and utilize Snowflake features such as Snowpipe for seamless data integration into the Snowflake environment.

## Architecture Overview
- Data Ingestion:
  - Simulate data generation using Postman to send HTTP POST requests to AWS API Gateway.
- Data Processing:
  - API Gateway acts as the entry point for the data, validating and routing the incoming requests.
  - API Gateway triggers an AWS Lambda function, which processes the data by checking if the format of the data is as expected and forwards it to Amazon Kinesis. Otherwise, it writes the incorrect data to error bucket.
- Data Streaming and Storage:
  - Amazon Kinesis Data Streams captures the real-time stream of data.
  - Kinesis Firehose delivers the data from the stream to an S3 data bucket for long-term storage in a structured format JSON
- Snowflake Integration:
  - Use Snowpipe, Snowflake’s data ingestion feature, to continuously ingest data from the S3 bucket into Snowflake tables.

## Deployment Steps
- Setup an IAM role and policy : Create an AWS IAM policy which will be used by API gateway and lambda to write the data to the respective AWS services
- Provision S3 Bucket: Create two S3 buckets(data and error) and define folder structures for data storage.
- Configure Kinesis Stream: Set up Kinesis Data Streams and Firehose for data streaming and delivery.
- Create Lambda Function: Write and deploy a Lambda function to process the incoming data to check the format of the data and process them accordingly to Kinesis or S3 error bucket
- Set up API Gateway: Configure an endpoint to accept HTTP POST requests.
- Enable Snowpipe in Snowflake: Configure Snowpipe to monitor the S3 bucket and ingest data automatically.
- Test with Postman: Simulate data ingestion by sending test payloads via Postman.
- Validate Data Flow: Ensure the data flows through all components and is queryable in Snowflake.