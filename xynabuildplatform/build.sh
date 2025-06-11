#!/bin/bash

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

# https://github.com/nvm-sh/nvm/releases
NVM_VERSION="v0.40.2"

# https://maven.apache.org/docs/history.html
MAVEN_VERSION="3.9.10"

# https://mvnrepository.com/artifact/org.apache.maven.resolver/maven-resolver-ant-tasks
MAVEN_RESOLVER_ANT_TASKS_VERSION="1.5.2"

# https://mvnrepository.com/artifact/ant-contrib/ant-contrib
ANT_CONTRIB_TASKS_VERSION="1.0b3"

JAVA_VERSION=""
OS_IMAGE=""
XYNA_BUILDPLATFORM_IMAGE=""
DOCKER_FILE="Dockerfile"

usage() {
    echo "Usage: $0 -j <JAVA-VERSION> -o <OS-IMAGE> -x <XYNA_BUILDPLATFORM_IMAGE>"
    exit 1
}

while getopts ":j:o:x:" option; do
    case "${option}" in
        j)
            JAVA_VERSION=${OPTARG}
            ;;
        o)
            OS_IMAGE=${OPTARG}
            ;;
        x)
            XYNA_BUILDPLATFORM_IMAGE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

docker build --build-arg OS_IMAGE=${OS_IMAGE} --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg MAVEN_VERSION=${MAVEN_VERSION} --build-arg MAVEN_RESOLVER_ANT_TASKS_VERSION=${MAVEN_RESOLVER_ANT_TASKS_VERSION} --build-arg= ANT_CONTRIB_TASKS_VERSION=${ANT_CONTRIB_TASKS_VERSION} --build-arg NVM_VERSION=${NVM_VERSION} -f ${DOCKER_FILE} -t ${XYNA_BUILDPLATFORM_IMAGE} .

