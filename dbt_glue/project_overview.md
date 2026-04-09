## DBT Glue Project

## Objective
- Create a scalable and automated data pipeline using AWS Glue, S3, dbt, and Snowflake, with a focus on ETL processes, data modeling, and cloud-based data storage.
- Utilize AWS Glue to extract data from an external API and store it in JSON format within an S3 bucket.
- After the data has been loaded into the S3 bucket, use DBT to transfer the data from the S3 bucket into a staging table in Snowflake, using DBT macros for automation.
- Use DBT's modeling capabilities to create the necessary tables in Snowflake across different layers: raw, transform, and mart.

## Project Steps
- Create an AWS IAM Role for Glue Job Access:
  - Set up an IAM role specifically for the AWS Glue job. This role will grant the necessary permissions for the Glue job to read and write data to the designated S3 bucket.
- Set Up an S3 Bucket for Data Storage:
  - Create an S3 bucket within our AWS account. This bucket will serve as the storage location for data extracted from an external API via AWS Glue. The S3 bucket will act as the intermediary where the API data is temporarily stored before being processed further.
- Create an AWS Glue Job for Data Extraction and Writing:
  - Create an AWS Glue job that will execute a Python script designed to pull data from the external API. This script will automate the extraction process, and the data will be written directly into the S3 bucket we previously created.
- Set Up IAM Role and Storage Integration for Snowflake:
  - Create an AWS IAM role and a Storage Integration in Snowflake. This integration will establish a secure connection between the Snowflake environment and the AWS account, allowing Snowflake to read from the S3 bucket where the Glue job has stored the extracted data.
- Create a DBT Cloud Account via Snowflake Partner Connect:
  - Create a DBT Cloud account through the Partner Connect feature within Snowflake. This integration allows us to leverage DBT’s capabilities for transforming and managing data models within the Snowflake environment.
- Set Up DBT Models for Raw, Transform, and Mart Layers:
  - Configure the different layers of data models using DBT. Start by setting up the raw layer to store unprocessed data, followed by the transform layer for cleaning and transforming the data. Finally, Create the mart layer, where the final, business-ready datasets will reside for consumption and analysis.
- Set up a deployment environment in dbt:
  - Configure a deployment environment in dbt to run the models and generate the corresponding schema and tables in the Snowflake production database.