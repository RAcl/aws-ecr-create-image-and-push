# aws-ecr-create-image-and-push

This is a GitHub Docker Action. 
- Login to AWS ECR
- Build docker image
- Push image in AWS ECR

## USE:


Please, you need to define next env vars:

| env var | description |default|
|--|--|--|
|AWS_ACCESS_KEY_ID| AWS ACCESS KEY ID|
|AWS_SECRET_ACCESS_KEY| AWS SECRET ACCESS KEY|
|AWS_REPOSITORY | Name from AWS ECR REPOSITORY | ${{ github.repository }} |
|AWS_DEFAULT_REGION | AWS respository region | us-east-1 |
|LATEST|latest generic image repo tag, example: latest-staging|latest|
|IMAGE_TAG|uniq image repo tag|first 7 characters from sha|

See the "build-image" part in the example.

```yaml
name: example

env:
    repo: repository_url
    AWS_REGION: us-west-1
    DEPLOY: test
    NS: test

on:
  push:
    tags:
        - 'v-*'
    branches:
        - staging

jobs:
    check:
        name: check
        runs-on: ubuntu-latest
        outputs:
            TAG: ${{ steps.check-ref.outputs.TAG }}
            LATEST: ${{ steps.check-ref.outputs.LATEST }}
            ENV: ${{ steps.check-ref.outputs.ENVIRON }}
            RUN_CI: ${{ steps.check-ref.outputs.RUN_CI }}
            RUN_CD: ${{ steps.check-ref.outputs.RUN_CD }}
        steps:
          - name: Checkout
            uses: actions/checkout@v4

          - name: test git ref
            id: check-ref
            uses: RAcl/tag-latest-environ-autodeploy@v1
            with:
                validPush: "branch-staging/staging/auto tag-v/production/manual"

    integration:
        if: ${{ needs.check.outputs.RUN_CI == 'true' }}
        needs: check
        name: integration
        runs-on: ubuntu-latest
        outputs:
            IMAGE: ${{ steps.build-image.outputs.IMAGE }}
        steps:
          - name: build-image
            id: build-image
            uses: RAcl/aws-ecr-create-image-and-push@v1
            env:
                AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
                AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
                AWS_DEFAULT_REGION: ${{ env.AWS_REGION }}
                AWS_REPOSITORY: ${{ env.repo }}
                LATEST: ${{ needs.check.outputs.LATEST }}
                IMAGE_TAG: ${{ needs.check.outputs.TAG }}
            with:
                params: --build-arg="ENV=${{ needs.check.outputs.ENV }}"
```


