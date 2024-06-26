#!/bin/bash

# show last AWS_ACCESS_KEY_ID
KEY_ID=$(echo ${AWS_ACCESS_KEY_ID} | sed 's/.\{16\}/****************/g')
echo "Use KEY_ID: ${KEY_ID}"

# getAccountID
AccountID=$(aws sts get-caller-identity | grep Account | awk -F'"' '{print $4}')
echo "Account ID: ", $AccountID

# login AWS ECR
DKR_SRV="${AccountID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin ${DKR_SRV}
if [ $? != 0 ]; then
    echo "Error Login to AWS ECR"
    exit 1
else
    echo "AWS ECR login OK"
fi

# initialize
TAG_SHA=$(echo $GITHUB_SHA | cut -c 1-7)
[ -n "${AWS_REPOSITORY}" ]&&ECR_REPO="${AWS_REPOSITORY}"||ECR_REPO="${GITHUB_REPOSITORY}"
[ -n "${LATEST}" ]||LATEST="latest"
[ -n "${IMAGE_TAG}" ]&&REPOTAG="${IMAGE_TAG}"||REPOTAG="${TAG_SHA}"

# build
sh -c "docker build -t ${ECR_REPO}:${TAG_SHA} $* ."
if [ $? != 0 ]; then
    echo "Error bad construction \"docker build -t ${ECR_REPO}:${TAG_SHA} $* .\""
    exit 1
fi

# publicar
docker tag $ECR_REPO:${TAG_SHA} $DKR_SRV/$ECR_REPO:$LATEST
docker tag $ECR_REPO:${TAG_SHA} $DKR_SRV/$ECR_REPO:$REPOTAG
docker push $DKR_SRV/$ECR_REPO:$LATEST
docker push $DKR_SRV/$ECR_REPO:$REPOTAG
echo "IMAGE=$DKR_SRV/$ECR_REPO:$REPOTAG" >> $GITHUB_OUTPUT

# informar
# echo "publish ${DKR_SRV}/${ECR_REPO}:${$LATEST}"
echo "export IMAGE=${DKR_SRV}/${ECR_REPO}:${REPOTAG}"
