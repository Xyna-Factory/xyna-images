#!/bin/bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copyright 2025 Xyna GmbH, Germany
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
XYNA_USER=""

usage() {
    echo "Usage: $0 -o <OS-Image> -u <Xyna-User-Name>"
    exit 1
}

while getopts ":o:u:" option; do
    case "${option}" in
        o)
            OS_IMAGE=${OPTARG}
            ;;
        u)
            XYNA_USER=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z ${OS_IMAGE} ]]; then
    usage
fi
if [[ -z ${XYNA_USER} ]]; then
    usage
fi

if [[ ${OS_IMAGE} == oraclelinux:* ]]; then
    echo "No additional package installation needed"
elif [[ ${OS_IMAGE} == redhat/ubi*:* ]]; then
    echo "No additional package installation needed"
elif [[ ${OS_IMAGE} == ubuntu:* ]]; then
    echo "Going to install additional packages"
    apt --no-install-recommends -y update
    apt -y upgrade
    apt-get -y install wget xinetd net-tools bind9utils vim-tiny less libxml2-utils gnupg ca-certificates curl gcc python3-dev python3-venv python3-pip systemd uuid-runtime
    su ${XYNA_USER}
    echo "Going to install pip3 jep for python"
    python3 -m venv /etc/opt/xyna/environment/venv
    source /etc/opt/xyna/environment/venv/bin/activate
    pip3 install --upgrade pip
    pip3 install jep
    pip3 uninstall -y setuptools
    deactivate
    rm -rf ~/.cache/pip
    su
    apt-get -y remove python3-pip
    apt-get -y autoremove
    apt-get clean
    rm -rf /var/lib/apt/lists/*
else
   echo "Warning: unsupported OS_IMAGE=${OS_IMAGE}"
fi
