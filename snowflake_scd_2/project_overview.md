# Snowflake ETL SCD 2 Project

## Overview
This project implements ETL SCD2 logic using DBT and Snowflake. Slowly Changing Dimensions (SCD) are dimensions (like Customer, Product, Employee) whose attributes change slowly over time, not every day like transactions. For example, a customer gets a new email address or a product gets a new or updated description. SCD2 logic overwrites old data by entering a new record into a table using the same primary key as the old record. Since the primary key is used more than once in the table, three columns can be used to keep track of the most active record: effect_start_date, effective_end_date, and is_active. For example, consider the following table:
  ```
  customer_id | name     | email_address    | effect_start_date | effect_start_date | is_active
  1           | John Doe | john@example.com | 01-12-2026        | Null              | 1
  ```
Changing John's email address would involve adding a new record with the new email address, instead of modifying the existing record:
  ```
  customer_id | name     | email_address        | effect_start_date | effect_start_date | is_active
  1           | John Doe | john@example.com     | 01-12-2026        | 03-12-2026        | 0
  1           | John Doe | john.new@example.com | 01-12-2026        | Null              | 1
  ```
SCD type 2 is useful in scenarios where historical data is either useful for data recovery purposes or required by law or regulation.

## Methodology
- Data Upload:
  - Data will be uploaded to an S3 bucket using a Python script running in an Anaconda notebook.
- Storage Integration:
  - AWS S3 and Snowflake are connected using a storage integration and external stage. The storage integration acts as a secure way for snowflake to read files from S3. The external stage defines the S3 location inside snowflake.
- Automated Data Upload With Snowpipe:
  - Snowpipe continuously monitors the S3 stage. When new files arrive (full or CDC), Snowpipe automatically copies the data into a source table.
  - Benefit: Fully automated, near real-time ingestion without manual loading.
- Change Processing With DBT:
  - Snowflake will be integrated with DBT to create Bronze, Silver, and Gold layers to transform the raw data into a state that is useful for analysis and reporting.
  - The SCD2 logic will be implemented using DBT snapshots. The snapshot feature uses a timestamp and a check. The timestamp is simply an `updated_at` row that records the time when a record in a table is updated. The check is a configuration that determines the primary and non-primary keys in a table. When a non-primary key is updated, a new record is added to the table with the same primary key and an `updated_at` column with the time the update was performed.