# ECR Code Build Continuous Deployment Project Summary

## AWS ECR
- Create a private repository that will be used to publish changes to a Dockerfile. This Dockerfile is used in ECR to build a Docker image that can be used to create a Lambda function.
    - Provide a meaningful name and keep all other settings as default.

## Build Specifications
- The `buildspec.yml` file is an important part of building a continuous deployment pipeline in AWS. The YAML file consists of phases and artifacts. Phases are the different steps that are executed during the deployment. Artifacts are files that are created after the deployment is complete.

## GitHub
- Create a repository that will hold the files needed to create the pipeline, such as the `buildspec.yml` file.
    - https://github.com/Calvinfr96/dea-ecr-codebuild-project.git

## AWS CodeBuild
- Create a CodeBuild project:
    - Provide a meaningful name.
    - Create a default project.
    - Choose GitHub as the source provider.
        - Set up a connection between AWS and the previously created github repository using a github app (preferred) or personal access token.
        - Select 'Repository in my GitHub account' and then choose the previously created repo.
    - Under Environment, choose the following settings:
        - Provisioning mode: On-demand
        - Environment image: Managed image
        - Compute: EC2
        - Running mode: Container
        - Operating system: Linux
        - Runtime: Standard
        - Image: latest image (default selected)
        - Service role: New service role
    - Under Buildspec, choose to use the `buildspec.yml` file from the github repo. The file must be the root directory of the repo, not a subfolder.
    - Create the project.
- After the project is created, make the following updates to the project settings:
    - Under 'Primary source webhook events', enable 'Rebuild every time a code change is pushed to this repository' and choose Single build as the build type.
    - Under 'Webhook event filter groups', enable `PUSH` and `PULL_REQUEST_MERGED`.
    - Click 'Update project'.
    - Confirm a Webhook was automatically created in the github repo settings. This is what establishes a line of communication between github and the AWS CodeBuild project.
- Test the pipeline by making an update in the github repo, then checking for a build record associated with that change. The test may fail due to AWS Service quotas.

## AWS IAM
- Update the permissions of the auto-generated IAM role that was created with the CodeBuild project. Add the following permissions:
    - AWSCodePipeline_FullAccess
    - AWSCodeBuildAdminAccess
    - AmazonEC2ContainerRegistryFullAccess