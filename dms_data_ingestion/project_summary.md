# DMS Data Ingestion Project Summary

## AWS RDS
- Create a database instance to store project data:
    - Use the standard create method.
    - Choose the MySQL database engine.
    - Choose the most recent stable version (second-most recent version).
    - Choose the Sandbox template, which is free and allows for deployment in a single AZ.
    - Choose self-managed credentials and auto-generate a password (sUvLLBr4shSFI8b6LLbO).
    - Ensure the database is publicly available.
    - Under 'Additional configuration', provide a unique name for the actual database. Also set the backup retention period to at least 1 day.
- Create a Custom Parameter Group for the recently created database:
    - The custom parameter group ensures the database is capable of performing CDC for incremental changes.
    - Provide a meaningful name and description for the parameter group.
    - Select the `MySQL Community` Engine Type and `mysql8.4` for the parameter group family. This coincides with the engine version used to create the database.
- Modify the following parameters (under Configuration) in the newly created parameter group:
    - `binlog_format`: ROW
    - `binlog_row_image`: full
    - `binlog_checksum`: NONE
- After modifying the parameter group, change the DB parameter group in the MySQL database to the newly created parameter group. This can be found under Configuration. After modifying the settings, reboot the DB instance.

### MySQL Workbench
- In MySQL Workbench, create a new SQL connection for the recently created database:
    - The Hostname of the connection should be the Endpoint name (under Connectivity and security).
    - The Username should be the Master username of the database (**Should be recorded and saved after database creation**).
    - Test the connection after specifying the above details.
    - Use the code from `data_ingestion.sql` to create the `retail` database and necessary tables, as well as insert test data into those tables.

## AWS DMS
- DMS tasks use provisioned instances (compute) and endpoints (source and destination) to perform data migration. To create a task, you must first create a provisioned instance and create an endpoint for the source and destination.
- Create a replication instance in the source region, which will provide the compute power necessary to perform the data migration:
    - Select the smallest instance class, as the task won't be migrating a lot of data.
    - Choose 'Dev or test workload (Single-AZ)' in instance configuration.
    - Leave other settings as default.
- Create a Source endpoint for the 'us-east-1' RDS database:
    - Select the previously created RDS database instance.
    - Select MySQL as the Source engine.
    - Provide access information manually and retrieve the username and password from the RDS instance. You can also manually create a secret in Secrets Manager and use that instead. This helps to avoid manually typing credentials. **Note that an IAM role with permissions to access the secret is required for this.**
    - Choose 'none' for the Secure Socket Layer (SSL) mode.
    - Leave other settings as default.
    - Test the connection before creating the endpoint.
- Create a Target endpoint for the 'us-east-1' S3 bucket:
    - Choose S3 as the Target engine.
    - Choose the previously created S3 bucket.
    - Choose the previously created IAM role created for AWS DMS.
    - Add the following endpoint settings:
        - CdcPath: `cdc/`
        - DatePartitionEnabled: `true`
        - DataFormat: `parquet`
    - Test the connection before creating the endpoint.
- Create a task in the source region:
    - Select the previously created source and target endpoints.
    - Select a provisioned task (serverless tasks are for high workloads). Choose the previously created replication instance.
    - Select 'Migrate and replicate' for the task type. This ensures a full load of the original source data, as well as CDC for incremental changes. Choose to load incremental changes indefinitely.
    - Specify the table mappings using the JSON from `table_mappings.json`. This determines how the data is transformed when it is migrated from source to target.
    - Disable premigration assessments for this task.
- When changes are made to the source data in RDS, DMS keeps track of all of the changes made (inserts, updates, and deletes) under table statistics in the DMS console.

## AWS S3
- Create a General Purpose bucket (using the default settings) in the same region as the RDS database.

## AWS IAM
- Create an IAM role that grants DMS the permissions needed to perform the data migration from RDS to S3:
    - Trusted Entity Type: AWS Service
    - Service or use case: AWS DMS
    - Permissions Policies:
        - AmazonRDSFullAccess
        - AmazonS3FullAccess
        - AmazonDMSCloudWatchLogsRole