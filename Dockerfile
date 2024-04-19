FROM redalvagui/debian11:latest

RUN apt-get update \
    && apt-get install ca-certificates curl \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    && chmod a+r /etc/apt/keyrings/docker.asc

RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update &&
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

COPY entrypoint.sh /
ENV AWS_ACCESS_KEY_ID=
ENV AWS_SECRET_ACCESS_KEY=
ENV AWS_DEFAULT_REGION=us-east-1
ENV AWS_DEFAULT_OUTPUT=json
ENV AWS_REPOSITORY=
ENV LATEST=
ENV IMAGE_TAG=
ENTRYPOINT ["/entrypoint.sh"]
