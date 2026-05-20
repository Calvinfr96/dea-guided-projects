# S3 S3 Cross Region Replication Project Summary

## AWS RDS
- Create a MySQL database that will be used to perform CRUD operations on data before storing it in S3. The database should be created in the same region as the primary S3 bucket.
    - Select the `MySQL` Engine Type. Choose the second most up to date MySQL version to ensure complete feature support.
    - The Free Tier database can only be created in one availability zone. Use AWS Secrets Manager to manage database credentials instead of manually creating a username and password.
    - Ensure the database is publicly available outside of the VPC.
    - Choose a retention period of at least one day to ensure data can be successfully migrated.
- Create a Custom Parameter Group for the recently created database.
    - Select the `MySQL Community` Engine Type.
    - Select the `mysql8.4` parameter group family. This coincides with the engine version used to create the database.
    - Select the `DB Parameter Group` type.
- Modify the following parameters (under Configuration) in the newly created parameter group:
    - `binlog_format`: ROW
    - `binlog_row_image`: full
    - `binlog_checksum`: NONE
- After modifying the parameter group, change the DB parameter group in the MySQL database to the newly created parameter group. After modifying the settings, reboot the DB instance.
- Modify the inbound and outbound rules of the DB security group (under Connectivity and security) to allow for public access:
    - Create a new inbound and outbound rule, selecting the type as `MySQL/Aurora` and the source as `My IP`.

### MySQL Workbench
- In MySQL Workbench, create a new SQL connection for the recently created database:
    - The Hostname of the connection should be the Endpoint name (under Connectivity and security).
    - The Username should be the Master username of the database (Under Connectivity and security).
    - The Password should be the one created by Secrets Manager during the creation of the database (under Connectivity and security).
    - Test the connection after specifying the above details.
    - Use the code from `create_database.sql` to create the `retail` database and necessary tables, as well as insert test data into those tables.

## AWS DMS
- DMS tasks use provisioned instances (compute) and endpoints (source and destination) to perform data migration. To create a task, you must first create a provisioned instance and create an endpoint for the source and destination S3 buckets.
- Create a replication instance in the source region, which will provide the compute power necessary to perform the data migration:
    - Select the smallest instance class, as the task won't be migrating a lot of data.
    - Choose 'Dev or test workload (Single-AZ)' in instance configuration.
    - Leave other settings as default.
- Create a Source endpoint for the 'us-east-1' DMS database:
    - Select the previously created RDS database instance.
    - Select MySQL as the Source engine.
    - Provide access information manually and retrieve the username and password from the RDS instance.
    - Choose 'none' for the Secure Socket Layer (SSL) mode.
    - Leave other settings as default.
    - Test the connection before creating the endpoint.
- Create a Target endpoint for the 'us-east-1' S3 bucket:
    - Choose S3 as the Target engine.
    - Choose the S3 bucket from the source region.
    - Choose the previously created IAM role created for AWS DMS.
    - Test the connection before creating the endpoint.
- Create a task in the source region:
    - Select the previously created source and target endpoints.
    - Select a provisioned task (serverless tasks are for high workloads). Choose the previously created replication instance.
    - Select 'Migrate and replicate' for the task type. This ensures a full load of the original source data, as well as CDC for incremental changes. Choose to load incremental changes indefinitely.
    - Specify the table mappings using the JSON from `table_mappings.json`. This determines how the data is transformed when it is migrated from source to target.
    - Choose the DMS-S3 replication IAM role to grant permissions for the premigration assessment. It is not necessary that all premigration assessments succeed before the task is started.
- When changes are made to the source data in RDS, DMS keeps track of all of the changes made (inserts, updates, and deletes) under table statistics in the DMS console.

## AWS S3
- Create an General Purpose S3 bucket in the same region (us-east-1) as the RDS database. Use the default parameters to create the bucket.
- Create a second General Purpose S3 bucket in the secondary region (us-west-1). Use the default parameters to create that bucket as well.
- Create an Event Notification in the source region that sends a message to the SNS topic. An SQS queue is subscribed to this topic and triggers a lambda function that performs the cross-region replication.
    - There is no need to provide a prefix (for a specific bucket folder) or suffix (for a specific file type).
    - Specify 'All object create events' under Event types.
    - Specify the destination as the SNS topic in the source region.

## AWS IAM
- Create an IAM role that will be used to perform the AWS DMS tasks:
    - Trusted Entity Type: AWS Service
    - Service or use case: AWS DMS
    - Permissions Policies:
        - AmazonRDSFullAccess
        - AmazonS3FullAccess
        - CloudWatchFullAccess (Allows DMS to write data to monitoring logs)
        - SecretsManagerReadWrite (Read data from RDS using the database credentials)
- Create an IAM role that will be used to execute the Lambda function that performs the cross-region replication.
    - Trusted Entity Type: AWS Service
    - Service or use case: AWS Lambda
    - Permissions Policies:
        - AmazonS3FullAccess
        - AmazonSQSFullAccess
        - AmazonSNSFullAccess
        - CloudWatchFullAccess

## AWS SNS
- Create an SNS topic for the S3 source bucket (us-east-1). This will be used to create an event notification in S3. Use the following settings to create the topic:
    - Create a Standard topic.
    - Under Access Policy, ensure everyone can subscribe and publish messages to the topic.

## AWS SQS
- Create an SQS queue for the target region (us-west-1). This will be used to trigger a Lambda function that performs the cross-region replication in S3. Use the following settings to create the queue:
    - Create a standard queue (message order is not important).
    - Under Access Policy, ensure only the queue owner can send and receive messages.
- After creating the SQS queue, subscribe to the previously-created SNS topic in the source region. The subscription can be confirmed in both the SQS and SNS console in AWS.

## AWS Lambda
- Create a Lambda function in the target region (us-west-1). This will perform the cross-region data migration in S3.
    - Choose 'Author from scratch' and provide a meaningful name.
    - Choose a Python runtime.
    - Use the previously created Lambda (cross-region replication) IAM role for the execution role.
    - Populate the function with the code from `replication_code.py`.
- Once the Lambda function is created and deployed, add a trigger to function using the previously created SQS queue.
- Modify the function timeout from 3 seconds to 5 minutes to ensure it will execute properly.