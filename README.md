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
    repo: repository_name
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
            uses: RAcl/tag-latest-environ-autodeploy@v2
            with:
                validPush: "branch:staging/staging/auto tag:v/production/manual"

    integration:
        if: ${{ needs.check.outputs.RUN_CI == 'true' }}
        needs: check
        name: CI
        runs-on: ubuntu-latest
        outputs:
            IMAGE: ${{ steps.build-image.outputs.IMAGE }}
            RUN_CD: ${{ needs.check.outputs.RUN_CD }}
        steps:
          - name: Checkout
            uses: actions/checkout@v4
          - name: build-image
            id: build-image
            env:
                AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
                AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
                AWS_DEFAULT_REGION: ${{ env.AWS_REGION }}
                AWS_REPOSITORY: ${{ env.repo }}
                LATEST: ${{ needs.check.outputs.LATEST }}
                IMAGE_TAG: ${{ needs.check.outputs.TAG }}
            run: |
                curl -fsSL https://raw.githubusercontent.com/RAcl/aws-ecr-create-image-and-push/main/entrypoint.sh -o build.sh
                sh build.sh --build-arg="ENVIRON=${{needs.check.outputs.ENV}}"

    deployment:
        if: ${{ needs.integracion.outputs.RUN_CD == 'true' }}
        name: CD
        needs: [integracion]
        runs-on: ubuntu-latest
        steps:
          - name: Deploy to EKS
            uses: RAcl/kube@main
            env:
                KUBE_CONFIG: ${{ secrets.KUBE_CONFIG_DATA }}
                AWS_ACCESS_KEY_ID: ${{ vars.AWS_ACCESS_KEY_ID }}
                AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
                AWS_DEFAULT_REGION: ${{ env.AWS_REGION }}
                K8S_DEPLOY: ${{ env.DEPLOY }}
                K8S_NS: ${{ env.NS }}
            with:
                args: set image deployment.apps/${K8S_DEPLOY} ${K8S_DEPLOY}=${{ needs.integracion.outputs.IMAGE }} -n ${K8S_NS}

          - name: Verify deploy on EKS
            uses: RAcl/kube@main
            env:
                KUBE_CONFIG: ${{ secrets.KUBE_CONFIG_DATA }}
                AWS_ACCESS_KEY_ID: ${{ vars.AWS_ACCESS_KEY_ID }}
                AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
                AWS_DEFAULT_REGION: ${{ env.AWS_REGION }}
                K8S_DEPLOY: ${{ env.DEPLOY }}
                K8S_NS: ${{ env.NS }}
            with:
                args: rollout status deployment.apps/${K8S_DEPLOY} -n ${K8S_NS}
```


