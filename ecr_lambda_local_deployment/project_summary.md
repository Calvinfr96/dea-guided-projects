# ECR Lambda Local Deployment Project Summary

## AWS IAM
- Create a user with admin privileges for use with the AWS CLI (save username and password of user access key).

## AWS Secrets Manager
- Create a secret to store the Calendly personal access token. This will be used by the python script to access the Calendly API.

## AWS S3
- Create an S3 bucket to store the data from the Calendly API calls. Within the bucket, create a 'calendly' folder.

## Docker
- Create a Dockerfile that executes specific commands needed to execute the lambda function. The Dockerfile acts as a template that builds a virtual machine where the python script runs. In the case of this project the virtual machine is a lambda function.

## AWS ECR
- Create a repository, which acts as a container that will store the Docker image. This can be done with the AWS CLI using the following command: `aws ecr create-repository --repository-name calendly`.
- In the terminal ensure the current directory is the one that contains the Dockerfile, then run the following commands:
    - `docker build -t calendly .` builds the docker image.
    - set the platform of the docker image:
        ```
        docker buildx build \
            --platform linux/amd64 \
            --provenance=false \
            --output type=image,oci-mediatypes=false \
            -t calendly .
        ```
    - `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 515424600331.dkr.ecr.us-east-1.amazonaws.com` logs into the AWS ECR repository.
    - `docker push 515424600331.dkr.ecr.us-east-1.amazonaws.com/calendly:latest` pushes the latest docker image to ECR.

## AWS Lambda
- Create a Lambda function using the Docker image pushed to ECR and use an IAM role with the permissions needed to execute the python script:
    - AmazonEC2ContainerRegistryFullAccess
    - AmazonS3FullAccess
    - AWSLambda_FullAccess
    - CloudWatchFullAccess
    - SecretsManagerReadWrite
- Increase the timeout of the Lambda function to 5 minutes.