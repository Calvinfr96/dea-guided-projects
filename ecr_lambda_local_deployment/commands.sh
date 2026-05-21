## command to create a repository in AWS ECR With name calendly

aws ecr create-repository --repository-name calendly

## command  to build the Docker Container Image (dont forget the dot at the end)
docker build -t calendly .

docker build --platform linux/amd64 -t calendly .


## Command to give the tag Latest to the Docker Image

docker tag calendly:latest 515424600331.dkr.ecr.us-east-1.amazonaws.com/calendly:latest ## {docker_repository_uri}:latest is the URI of your AWS ECR repository

##you can get above URI from AWS ECR console
## Command to connect to AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 515424600331.dkr.ecr.us-east-1.amazonaws.com

## replace this 515424600331.dkr.ecr.us-east-1.amazonaws.com with your URI from AWS ECR console
## Command to Push the latest Image to AWS ECR

docker push 515424600331.dkr.ecr.us-east-1.amazonaws.com/calendly:latest