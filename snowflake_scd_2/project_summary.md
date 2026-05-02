# Snowflake ETL SCD 2 Project Summary

## AWS IAM
- Create and configure an IAM Access Key to use in the local terminal.
- Create a `snowflake-scd2-project-snowpipe-role` IAM Role to establish the storage integration between Snowflake and S3.

## AWS S3
- Create and configure a `snowflake-scd2-project-bucket-calvinfr1` S3 bucket with default settings, other than a disabled bucket key.

## Snowflake
- Create an `SCD2_DB` database to store the data.
- Create an S3 storage integration using the `snowflake-scd2-project-snowpipe-role` IAM role and `s3://snowflake-scd2-project-bucket-calvinfr1/data/` S3 bucket URI.
- Create a CSV file format to parse the data that will be loaded from S3.
- Create a stage that uses the above storage integration and file format.
- Initialize a Partner Connect with DBT to perform the necessary transformations on the raw data. This requires creating a new DBT account or project.
- Grant the appropriate privileges to the `PC_DBT_ROLE`. After granting these permissions, recreate your stage, file format and new tables as you have just given access to `PC_DBT_ROLE` to use these.
- Create the `SCD2_DB.BRONZE.WORK_PRODUCT_COPY` table to store the raw data from S3.

## DBT
- Create a schemas for the silver and gold layers. The silver layer is materialized as a table while the gold layer is materialized as a view.
- Create a `generate_schema_name` macro.
- Create a `query_tag` macro. This macro creates a query tag in Snowflake. A query tag logs queries that are performed when `dbt run` is executed.
- Add the `dbt-labs/dbt_utils` package to the `packages.yml` file.
- Create a `copy_into_snowflake` macro that copies the raw data from S3 into the appropriate Snowflake database. This deletes data from the bronze table and adds it to the silver table.
  - The variables from this macro need to be added to the `dbt_project.yml` file so they are interpreted as global variables. Use the same stage name, file format, work schema, and other values that were used to create the S3 storage integration.
- Create the `transform_product_load` model to transform the raw data from the bronze layer into the data that will go in the silver layer.
- Create a snapshot which captures changes (new/updated records) from the silver layer table.
- Create the `product_view` model to load the changes captured by the snapshot into a table.