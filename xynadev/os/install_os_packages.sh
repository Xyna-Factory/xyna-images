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
XYNA_PATH=""

usage() {
    echo "Usage: $0 -o <OS-Image> -u <Xyna-User-Name> -p <Xyna-Path>"
    exit 1
}

HERE=$(dirname "$0")
source "${HERE}"/func_lib_images.sh


while getopts ":o:u:p:" option; do
    case "${option}" in
        o)
            OS_IMAGE=${OPTARG}
            ;;
        u)
            XYNA_USER=${OPTARG}
            ;;
        p)
            XYNA_PATH=${OPTARG}
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
if [[ -z ${XYNA_PATH} ]]; then
    usage
fi


if [[ ${OS_IMAGE} == oraclelinux:* ]]; then
    echo "No additional package installation needed"
elif [[ ${OS_IMAGE} == redhat/ubi*:* ]]; then
    echo "No additional package installation needed"
elif [[ ${OS_IMAGE} == ubuntu:* ]]; then
    ubuntu_prepare_apt_install
    echo "Going to install additional packages"

    apt-get -y install wget xinetd net-tools bind9utils vim-tiny less libxml2-utils gnupg ca-certificates curl gcc systemd uuid-runtime
    apt-get -y install python3-dev python3-venv python3-pip

    echo "Going to install local venv for python"
    ubuntu_install_python_venv "${XYNA_USER}" "${XYNA_PATH}"
    ubuntu_finish_apt_install
else
    echo "Warning: unsupported OS_IMAGE=${OS_IMAGE}"
fi
