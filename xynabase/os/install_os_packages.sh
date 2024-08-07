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

OS_IMAGE=""
JAVA_VERSION=""

usage() {
    echo "Usage: $0 -o <OS-Image> -j <JAVA-Version>"
    exit 1
}

while getopts ":o:j:" option; do
    case "${option}" in
        o)
            OS_IMAGE=${OPTARG}
            ;;
        j)
            JAVA_VERSION=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z ${OS_IMAGE} ]]; then
    usage
fi
if [[ -z ${JAVA_VERSION} ]]; then
    usage
fi


if [[ ${OS_IMAGE} == oraclelinux:* ]]; then
    yum install -y https://cdn.azul.com/zulu/bin/zulu-repo-1.0.0-1.noarch.rpm
    yum -y update
    yum -y upgrade
    yum install -y zip unzip patch wget openssl nc which net-tools passwd rsyslog bind-utils vim less telnet procps bc diffutils hostname perl gcc python3-devel
    if [[ ${OS_IMAGE} == oraclelinux:7* ]]; then
        yum install -y xinetd
    fi
    yum install -y zulu${JAVA_VERSION}-jdk-headless
    yum clean all
elif [[ ${OS_IMAGE} == redhat/ubi*:* ]]; then
    yum install -y https://cdn.azul.com/zulu/bin/zulu-repo-1.0.0-1.noarch.rpm
    yum -y update
    yum -y upgrade
    yum install -y zip unzip patch wget openssl nc which net-tools passwd rsyslog bind-utils vim less procps bc diffutils hostname perl
    yum install -y zulu${JAVA_VERSION}-jdk-headless
    yum clean all
    dnf install -y gcc python3-devel
elif [[ ${OS_IMAGE} == ubuntu:* ]]; then
    apt -y update
    apt -y upgrade
    apt-get -y install zip unzip patch wget netcat-traditional xinetd net-tools bind9utils vim less dc libxml2-utils gnupg ca-certificates curl gcc python3-dev python3-venv systemd
    curl -s https://repos.azul.com/azul-repo.key | gpg --dearmor -o /usr/share/keyrings/azul.gpg
    echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | tee /etc/apt/sources.list.d/zulu.list
    apt -y update
    apt -y install zulu${JAVA_VERSION}-jdk-headless
else
   echo "Warning: unsupported OS_IMAGE=${OS_IMAGE}"
fi
