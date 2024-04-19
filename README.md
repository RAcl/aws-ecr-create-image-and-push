# aws-ecr-create-image-and-push

This is a GitHub Docker Action. 
- Login to AWS ECR
- Build docker image
- Push image in AWS ECR

## USE:

```yaml

```

Please, define next env vars:

| env var | description |default|
|--|--|--|
|AWS_ACCESS_KEY_ID| AWS ACCESS KEY ID|
|AWS_SECRET_ACCESS_KEY| AWS SECRET ACCESS KEY|
|AWS_REPOSITORY | Name from AWS ECR REPOSITORY | ${{ github.repository }} |
|AWS_DEFAULT_REGION | AWS respository region | us-east-1 |
|LATEST|latest generic image repo tag, example: latest-staging|latest|
|IMAGE_TAG|uniq image repo tag|first 7 characters from sha|

