ARG OS_IMAGE=ubuntu:24.04
FROM ${OS_IMAGE}
ARG OS_IMAGE
ARG JAVA_VERSION
ARG NODE_MAJOR_VERSION
ARG NODEJS_VERSION

# install os packages
RUN apt-get update && \
    apt-get -yq install gnupg curl zip unzip git python3 vim

# Install java and ant and maven and nvm
RUN curl -s https://repos.azul.com/azul-repo.key | gpg --dearmor -o /usr/share/keyrings/azul.gpg  && \
    echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | tee /etc/apt/sources.list.d/zulu.list  && \
    apt -y update && \
    apt -y upgrade && \
    apt -y install zulu${JAVA_VERSION}-jdk-headless && \
    apt-get -y install ant && \
    apt-get -y install ant-contrib && \
    apt-get -y install maven

# Install nodejs and nvm
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get -y update && \
    apt-get -y install nodejs && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

RUN mkdir -p /xyna
COPY xyna /xyna
