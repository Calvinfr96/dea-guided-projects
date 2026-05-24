# Airflow and AWS Code Pipeline Project

## Overview
This project demonstrates how to build an airflow data pipeline orchestration from scratch. AWS CodePipeline, which is used to integrate repositories in GitHub with AWS Services, will be used to transfer data from a github repo to an S3 bucket. AWS Managed Workflows from Apache Airflow (MWAA) will be used to orchestrate the data pipeline. AWS Kinesis Streams and Firehose will be used to ingest and transform the data, then upload it to another S3 bucket. From there AWS Athena will be used to query the data.

The Airflow DAG in this project will work as follows:
- Set up the API user ID to retrieve the necessary data.
- Extract user posts from the API.
- Process user posts by individually writing each post to the Kinesis data stream.

AWS Kinesis Data Stream will store the data that has been transformed by the Airflow DAG and Firehose will transfer that data to the second S3 bucket. Finally, AWS Athena will be used to query the transformed data.