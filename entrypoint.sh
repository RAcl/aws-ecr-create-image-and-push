#!/bin/bash

# Stop execute on error
# set -e

# show last AWS_ACCESS_KEY_ID
KEY_ID=$(echo ${AWS_ACCESS_KEY_ID} | sed 's/.\{16\}/****************/g')
echo "Use KEY_ID: ${KEY_ID}"

# create workdirs
mkdir -p ~/{.aws,.kube}

# create AWS's config files
cat > ~/.aws/credentials << EOF_CRED
[default]
aws_accesss_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_accesss_key = ${AWS_SECRET_ACCESS_KEY}
EOF_CRED

cat > ~/.aws/config << EOF_CFG
[default]
region = ${AWS_DEFAULT_REGION}
output = ${AWS_DEFAULT_OUTPUT}
EOF_CFG

AccountID=$(aws sts get-caller-identity | grep Account | awk -F'"' '{print $4}')

echo "Account ID: ", $AccountID

DKR_SRV="${AccountID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin ${DKR_SRV}
if [ $? != 0 ]; then
    echo "Error Login to AWS ECR"
    exit 1
fi

TAG_SHA=$(echo $GITHUB_SHA | cut -c 1-7)

[ -n "${AWS_REPOSITORY}" ]&&ECR_REPO="${AWS_REPOSITORY}"||ECR_REPO="${GITHUB_REPOSITORY}"
[ -n "${LATEST}" ]&&LATEST="latest"
[ -n "${IMAGE_TAG}" ]&&REPOTAG="${IMAGE_TAG}"||REPOTAG="${TAG_SHA}"

sudo -c "docker build -t ${ECR_REPO}:${TAG_SHA} $* ."
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
echo $DKR_SRV/$ECR_REPO:$REPOTAG

# delete workdirs
rm -rf ~/.aws
