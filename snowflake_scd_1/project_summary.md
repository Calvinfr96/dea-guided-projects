# Snowflake ETL SCD 1 Project Summary

## Snowflake
- Transfer files from S3 and process data using SCD1 logic.
- A snowpipe is used to auto-ingest the data uploaded from local machine to S3 using a Python script running in an Anaconda notebook. The data is ingested into a `CUSTOMER_SOURCE` table.
  - A storage integration is created to establish a connection between AWS S3 and Snowflake.
  - An external stage is used as a temporary storage location for the data ingested from the snowpipe.
  - The snowpipe is configured to copy the data from the external stage to the `CUSTOMER_SOURCE` table.
  - An append-only stream is used to capture changes to the `CUSTOMER_SOURCE` table. Specifically, the stream captures rows that have been added by the S3 storage integration.
- A `CUSTOMER` target table is used to store data that has been transformed using SCD1 logic.
- A stored procedure (SP) is used to perform SCD1 logic in the target table. The SP will:
  - Read the data from the stream created for the customer table and create a work table.
  - Load the data into the customer table and perform the required SCD1 logic.
- A task is created to execute this stored procedure every 1 minute. The task is initialized in a 'suspended' state and must be manually started to perform the SCD1 logic.

## Anaconda
- Perform file upload to S3 using a Python script.

## AWS S3
- Store files uploaded from local machine using a Python script running in an Anaconda notebook.
- General Purpose Bucket: `snowflake-scd1-project-bucket`

## AWS IAM
- Create an IAM User with the permissions necessary to access S3 bucket where data will be stored. This will be used by the Python script running in the Anaconda notebook to upload the data from the local machine to S3.
  - IAM User: `snowflake-scd1-project-user`
- Create an IAM Role with the permissions necessary to access the S3 bucket where the data will be stored. This will be used in Snowflake to create a Snowpipe that will transfer the data from S3 to a Snowflake database, where it will be processed.
  - IAM Role: `snowflake-scd1-project-snowpipe-role`