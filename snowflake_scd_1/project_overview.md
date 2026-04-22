# Snowflake ETL SCD 1 Project

## Overview
This project implements a pipeline to handle full data loads and change data capture (CDC) from a Python process, store the data in AWS S3, and use Snowflake’s native features — Snowpipe, Streams, Tasks, and Stored Procedures — to automatically load and update a Customer table with SCD Type 1 logic. Slowly Changing Dimensions (SCD) are dimensions (like Customer, Product, Employee) whose attributes change slowly over time, not every day like transactions. For example, a customer gets a new email address or a product gets a new or updated description. SCD type 1 simply overwrites the old data with the new data without holding historical records. For example, consider the following table:
  ```
  customer_id | name     | email_address
  1           | John Doe | john@example.com
  ```
Changing John's email address would involve modifying the record with customer_id 1, instead of adding a new record with the new email address:
  ```
  customer_id | name     | email_address
  1           | John Doe | john.new@example.com
  ```

## Methodology
- Data Upload:
  - A Python script (running in an Anaconda notebook) takes the downloaded full extracts and incremental change files from your local machine. These datasets are already shared as part of the project
  - The script then uploads these files to a designated S3 bucket.
- Storage integration:
  - AWS S3 and Snowflake are connected using a storage integration and external stage. The storage integration acts as a secure way for snowflake to read files from S3. The external stage defines the S3 location inside snowflake.
- Automated Data Upload With Snowpipe:
  - Snowpipe continuously monitors the S3 stage. When new files arrive (full or CDC), Snowpipe automatically copies the data into a Customer Source table (`CUSTOMER_SOURCE`).
  - Benefit: Fully automated, near real-time ingestion without manual loading.
- Change Processing With Streams:
  - A Stream is defined on the `CUSTOMER_SOURCE` table which tracks new or changed rows that were loaded by Snowpipe.
  - Benefit: Snowflake knows exactly which rows are new or updated, making incremental processing simple.
- Automated Processing With Tasks and Stored Procedures:
  - A Task runs on a schedule (or continuously) and calls a Stored Procedure.
  - The Stored Procedure performs the following tasks:
    - Reads the change data from the Stream.
    - Merges it into the target `CUSTOMER` table using SCD Type 1 logic:
      - If the customer ID exists → update the changed attributes (e.g., overwrite address or email).
      - If the customer ID is new → insert it.
      - This is typically done using a `MERGE` statement.
  - Benefit: The entire SCD1 flow is automated — no manual steps to merge data.

## Benefits
- Automated full & incremental loads
- Zero manual file handling — everything runs on Snowflake side once data lands in S3
- No duplicate work — Stream ensures only new/changed rows are processed
- SCD1 logic guarantees the CUSTOMER table always has the latest values — old data is overwritten as required