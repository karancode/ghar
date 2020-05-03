FROM ubuntu:18.04

ARG GITHUB_RUNNER_VERSION="2.169.1"
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_NAME "runner"

## passing on runtime form k8s config
# ENV GITHUB_PAT "githubprivateaccesstoken"
# ENV GITHUB_OWNER "karancode"
# ENV GITHUB_REPOSITORY "runner-k8s-test"

RUN apt-get update \
    && apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        gnupg2 \
        systemd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get install -y apt-transport-https \
    && apt-get update \
    && apt-cache policy docker-ce \
    && apt-get install -y docker-ce


RUN curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

RUN mkdir -p .ssh 
COPY ssh-config .ssh/config

COPY entrypoint.sh entrypoint.sh
RUN sudo chmod u+x ./entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
