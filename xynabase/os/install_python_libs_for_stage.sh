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
STAGE_NUM=""

usage() {
    echo "Usage: $0 -o <OS-Image> -u <Xyna-User-Name> -s <Stage-Num>"
    exit 1
}


do_install() {
    if [[ $1 -ne ${STAGE_NUM} ]]; then
        echo "No pip packages to install in installation stage ${STAGE_NUM} on ${OS_IMAGE}"
        exit 0
    fi
    su ${XYNA_USER}
    echo "Going to install pip3 jep for python"
    python3 -m venv /etc/opt/xyna/environment/venv
    source /etc/opt/xyna/environment/venv/bin/activate
    pip3 install --upgrade pip
    pip3 install jep
    pip3 uninstall -y setuptools
    deactivate
    rm -rf ~/.cache/pip
}


while getopts ":o:u:s:" option; do
    case "${option}" in
        o)
            OS_IMAGE=${OPTARG}
            ;;
        u)
            XYNA_USER=${OPTARG}
            ;;
        s)
            STAGE_NUM=${OPTARG}
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
if [[ -z ${STAGE_NUM} ]]; then
    usage
fi


if [[ ${OS_IMAGE} == oraclelinux:* ]]; then
    do_install 1
elif [[ ${OS_IMAGE} == redhat/ubi*:* ]]; then
    do_install 1
elif [[ ${OS_IMAGE} == ubuntu:* ]]; then
    do_install 2
else
   echo "Warning: unsupported OS_IMAGE=${OS_IMAGE}"
fi
