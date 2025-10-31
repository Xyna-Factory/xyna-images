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


install_full() {
    cd /tmp
    unzip XynaFactory*
    rm XynaFactory*.zip
    mv XynaFactory* XynaFactoryBundle
    cp XynaFactoryBundle/XynaFactory_* XynaBlackEdition.zip
    cp XynaFactoryBundle/XBE_Pre* XBE_Prerequisites.zip
    unzip XBE_Prerequisites*
    rm XBE_Prerequisites.zip
    mv XBE_Prerequisites* XBE_Prerequisites
    chown -R ${XYNA_USER}:${XYNA_USER} XBE_Prerequisites
    chmod 777 XBE_Prerequisites/install_prerequisites.sh
    source /etc/opt/xyna/environment/venv/bin/activate
    printf $PREREQ_INSTALL_PARAMS | XBE_Prerequisites/install_prerequisites.sh -x
    deactivate
}


install_without_python() {
    cd /tmp
    unzip XynaFactory*
    rm XynaFactory*.zip
    mv XynaFactory* XynaFactoryBundle
    cp XynaFactoryBundle/XynaFactory_* XynaBlackEdition.zip
    cp XynaFactoryBundle/XBE_Pre* XBE_Prerequisites.zip
    unzip XBE_Prerequisites*
    rm XBE_Prerequisites.zip
    mv XBE_Prerequisites* XBE_Prerequisites
    chown -R ${XYNA_USER}:${XYNA_USER} XBE_Prerequisites
    chmod 777 XBE_Prerequisites/install_prerequisites.sh
    printf $PREREQ_INSTALL_PARAMS | XBE_Prerequisites/install_prerequisites.sh -x
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
    install_without_python
elif [[ ${OS_IMAGE} == redhat/ubi*:* ]]; then
    install_without_python
elif [[ ${OS_IMAGE} == ubuntu:* ]]; then
    install_without_python
else
   echo "Warning: unsupported OS_IMAGE=${OS_IMAGE}"
fi
