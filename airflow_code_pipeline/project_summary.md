# Airflow and AWS Code Pipeline Project Summary

## GitHub
- Fork the following github repo to connect with AWS CodePipeline: https://github.com/deacademy/airflow-dags
    - Forking the repository will allow you to use it for your own purposes, without modifying the original repo.
    - Forked repo: https://github.com/Calvinfr96/airflow-dags

## AWS S3
- Create a General Purpose bucket in the us-east-1 region. Disable 'Bucket key' and leave all other settings as default.
    - This bucket will be used to store the data that will be transferred from the github repo by AWS CodePipeline.
    - This bucket will also be used as a source for the managed apache workflow. The workflow is based on the files stored in the `dags` folder.
- Create a General Purpose bucket in the us-east-1 region. Disable 'Bucket key' and leave all other settings as default.
    - This bucket will be used to store Athena query results.
- Create a General Purpose bucket in the us-east-1 region. Disable 'Bucket key' and leave all other settings as default.
    - This bucket will be used as a destination for AWS Data Firehose.

## AWS CodePipeline
- Create a pipeline to link the forked github repo with S3:
    - Choose to build a custom pipeline.
    - Choose the Queued execution mode and create a new service role for the pipeline.
    - Choose the source as GitHub (via GitHub App). Ensure the GitHub App has permission to access the previously forked repo.
    - Choose the 'main' branch as the default branch.
    - Skip the build and test stages.
    - Choose the previously created CodePipeline S3 bucket for the Deploy stage.
    - Verify details and create the pipeline.
- After the pipeline is created and the deployment is finished, confirm the deployment succeeded by looking for the files from the repo in the CodePipeline S3 bucket.

## Amazon Kinesis Data Stream
- Create a new data stream to store the data from the apache workflow. Leave all settings as default.

## Amazon Data Firehose
- Create a new data firehose to transfer the data from the previously-created data stream to the firehose S3 bucket:
    - Choose Amazon Kinesis Data Streams as the source, specifying the previously-created data stream.
    - Choose Amazon S3 as the destination, specifying the previously-created firehose S3 bucket.
    - Specify `user-posts/` as the S3 bucket prefix.
    - Specify `user-posts-error/` as the S3 bucket error output prefix.
    - Ensure the associated IAM role has the permissions required to create the firehose.

## AWS Managed Apache Airflow
- Create a new Airflow environment:
    - Choose the second most up to date Airflow version.
    - Choose the previously created CodePipeline S3 bucket. Choose the `dags` folder within that bucket.
    - Create a new VPC for the workflow. Once the VPC is created, select it and ensure the subnets are automatically populated.
    - Enable public web server access.
    - Choose the `mw1.micro` Environment class.
    - Enable all of the logs under 'Airflow logging configuration'.
    - Create a new IAM role for the environment, if necessary.
- Once the environment is created, click on the link to navigate to the Airflow UI.
- Add the following policies to the execution role:
    - AmazonKinesisFullAccess

## Airflow
- Access the Airflow UI through the AWS MWAA Console.
- Confirm the DAGs from the github repo are present. These can be triggered manually in the UI. Alternatively, the DAGS can also be configured to trigger based on a defined schedule.

## Amazon Athena
- Create a new workgroup:
    - Choose Athena SQL as the query engine.
    - Choose the previously created Athena S3 bucket.
- Once the workgroup is created, navigate to the query editor, select the newly created workgroup, and create a table from data source, selecting 'S3 bucket data'.
    - Choose the `user-posts` folder from firehose S3 bucket.
    - Choose Apache Hive as the Table type and JSON as the file format.
    - Choose 'org.openx.data.jsonserde.JsonSerDe' as the SerDe library.
    - Add the following columns:
        - userid - string
        - id - string
        - title - string
        - body - string
- Once the table is created, you can click on it to preview its data.