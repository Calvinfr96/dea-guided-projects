# DBT Glue Project Summary

## AWS IAM
- Purpose: Grant necessary permissions to various AWS/External services/entities.
- Create a `dbt-glue-project-role` IAM Role with the following Trust Policy JSON:
  ```
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sts:AssumeRole"
        ],
        "Principal": {
          "Service": [
            "glue.amazonaws.com"
          ]
        }
      }
    ]
  }
  ```
  - Grant the role the following permissions:
    - `AmazonS3FullAccess`
    - `CloudWatchFullAccess`
- Create a `dbt-glue-snowpipe-role` IAM role with an external ID of '12345'.
  - Grant the role the following permissions:
    - `AmazonS3FullAccess`

## AWS S3
- Purpose: Store incoming data from external API.
- Create a `dbt-glue-project-bucket-calvinfr1` S3 bucket with the default settings.
  - Within that bucket, create a `data` folder to store the data coming from AWS Glue.

## AWS Glue
- Purpose: Extract data from external API and send to internal S3 bucket.
- Create a `dbt-glue-project-api-s3-job` Glue job to process the data from the external API.
  - Select the Python shell script and paste the following code:
    ```
    import boto3
    import requests
    import base64
    from botocore.exceptions import NoCredentialsError, PartialCredentialsError

    # Example usage
    github_url = "https://raw.githubusercontent.com/deacademygit/project-data/refs/heads/main/country_details.json"  # Raw file URL from GitHub
    bucket_name = "dbt-glue-project-bucket-calvinfr1"  # The S3 bucket where the file will be uploaded
    s3_key = "data/country_details.json"  # The key (path) in the S3 bucket

    def fetch_data_from_github_and_upload_to_s3(github_url, bucket_name, s3_key):
      try:
        # Fetch the file content from GitHub (raw URL or GitHub API URL)
        response = requests.get(github_url)

        # Check if the request was successful
        if response.status_code == 200:
          # Get the content from the response (for raw URL, it's already plain text or binary)
          file_content = response.content

          # Initialize the S3 client
          s3_client = boto3.client('s3')

          # Upload the file content to S3
          s3_client.put_object(Bucket=bucket_name, Key=s3_key, Body=file_content)
          print(f"File uploaded successfully to s3://{bucket_name}/{s3_key}")
        else:
          print(f"Error: Failed to fetch file from GitHub. Status code {response.status_code}")

      except (NoCredentialsError, PartialCredentialsError) as e:
        print(f"Error: AWS credentials are missing or incomplete. {e}")
      except requests.exceptions.RequestException as e:
        print(f"Error fetching the file from GitHub: {e}")
      except Exception as e:
        print(f"Error uploading file to S3: {e}")

    fetch_data_from_github_and_upload_to_s3(github_url, bucket_name, s3_key)
    ```
  - Select the `dbt-glue-project-role` IAM Role under Job details.
- Run the job and wait for it to succeed. Check the S3 bucket to confirm the data was uploaded.

## Snowflake
- Purpose: Auto-ingest data from S3 bucket into a Snowflake table for analytical purposes.
- Create a snowpipe in snowflake.
  - Use the `notification_channel` property to create an S3 event notification. Specify `data/` as the prefix and notify on all object create events. Specify the destination as the SQS queue (`notification_channel`) associated with the snowpipe. This will allow the snowpipe to automatically ingest data as it lands in the S3 bucket.

## DBT
- Purpose: Ingest and transform data uploaded to to S3 from AWS Glue. Data will be transformed using DBT models to create raw, transform, and mart layers. A DBT Job will be created to automatically run data through these models as it is ingested.
- Create a `development` branch to make these changes. This is standard procedure when working in production environments.

### Raw Layer
- Create a `generate_schema_name` macro in the `macros` folder. This macro will be used to create schemas for each transformation layer created in DBT.
- Create a `copy_json` macro in the `macros` folder. This macro will be used to copy new data into the table within the target database and schema. The data will come from the snowflake stage used to pull JSON data from S3.
- Create a `country_details_raw` model in the `models/raw` folder. This model will be materialized as a table. It takes the data from the `COUNTRY_DETAILS_CP` table (loaded from S3) and loads it into a `COUNTRY_DETAILS_RAW` table created under a `RAW` schema.
  - This transformation takes each JSON value in the `COUNTRY_DETAILS_CP` (single-row table) and puts it in its own row under a `SOURCE_DATA` column. It also creates a `INSERT_DTS` column with the current timestamp.

### Transform Layer
- Create a `country_details_transform` model in the `models/transform` folder. This model will be materialized as a table. It takes data from the raw layer and loads it into a `COUNTRY_DETAILS_TRANSFORM` table created under the `TRANSFORM` schema.
  - This transformation takes the JSON data in `COUNTRY_DETAILS_RAW` and performs additional flattening and formatting.

### Mart Layer
- Create a `country_details_antarctica` model in the `models/mart` folder. This model will be materialized as a table. It takes data from the transform layer and loads it into a `COUNTRY_DETAILS_ANTARCTICA` table created under the `MART` schema.
  - This transformation takes the data from `COUNTRY_DETAILS_TRANSFORM` and filters it based on `COUNTRY_CONTINENT_NAME = 'ANTARCTICA'`, then loads it into a `COUNTRY_DETAILS_ANTARCTICA` table.
- Create a `country_details_north_america` model in the `models/mart` folder. This model will be materialized as a table. It takes data from the transform layer and loads it into a `COUNTRY_DETAILS_NORTH_AMERICA` table created under the `MART` schema.
  - This transformation takes the data from `COUNTRY_DETAILS_TRANSFORM` and filters it based on `COUNTRY_CONTINENT_NAME = 'NORTH AMERICA'`, then loads it into a `COUNTRY_DETAILS_NORTH_AMERICA` table.
- Create a `country_details_south_america` model in the `models/mart` folder. This model will be materialized as a table. It takes data from the transform layer and loads it into a `COUNTRY_DETAILS_SOUTH_AMERICA` table created under the `MART` schema.
  - This transformation takes the data from `COUNTRY_DETAILS_TRANSFORM` and filters it based on `COUNTRY_CONTINENT_NAME = 'SOUTH AMERICA'`, then loads it into a `COUNTRY_DETAILS_SOUTH_AMERICA` table.
- Create a `country_details_europe` model in the `models/mart` folder. This model will be materialized as a table. It takes data from the transform layer and loads it into a `COUNTRY_DETAILS_EUROPE` table created under the `MART` schema.
  - This transformation takes the data from `COUNTRY_DETAILS_TRANSFORM` and filters it based on `COUNTRY_CONTINENT_NAME = 'EUROPE'`, then loads it into a `COUNTRY_DETAILS_EUROPE` table.
- Create a `country_details_africa` model in the `models/mart` folder. This model will be materialized as a table. It takes data from the transform layer and loads it into a `COUNTRY_DETAILS_AFRICA` table created under the `MART` schema.
  - This transformation takes the data from `COUNTRY_DETAILS_TRANSFORM` and filters it based on `COUNTRY_CONTINENT_NAME = 'AFRICA'`, then loads it into a `COUNTRY_DETAILS_AFRICA` table.
- Create a `country_details_asia` model in the `models/mart` folder. This model will be materialized as a table. It takes data from the transform layer and loads it into a `COUNTRY_DETAILS_ASIA` table created under the `MART` schema.
  - This transformation takes the data from `COUNTRY_DETAILS_TRANSFORM` and filters it based on `COUNTRY_CONTINENT_NAME = 'ASIA'`, then loads it into a `COUNTRY_DETAILS_ASIA` table.
- Create a `country_details_oceania` model in the `models/mart` folder. This model will be materialized as a table. It takes data from the transform layer and loads it into a `COUNTRY_DETAILS_OCEANIA` table created under the `MART` schema.
  - This transformation takes the data from `COUNTRY_DETAILS_TRANSFORM` and filters it based on `COUNTRY_CONTINENT_NAME = 'OCEANIA'`, then loads it into a `COUNTRY_DETAILS_OCEANIA` table.