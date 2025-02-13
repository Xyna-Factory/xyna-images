# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copyright 2023 Xyna GmbH, Germany
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# syntax=docker/dockerfile:1
ARG OS_IMAGE=ubuntu:24.04
FROM ${OS_IMAGE}
ARG OS_IMAGE
ARG JAVA_VERSION
ARG NVM_VERSION

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

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash

RUN mkdir -p /xyna
COPY xyna /xyna
