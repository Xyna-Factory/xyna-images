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

XYNA_USER=""

usage() {
    echo "Usage: $0 -u <Xyna-User-Name>"
    exit 1
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
    ## note: if prerequisites should configure python, execute source <venv/bin/activate> here
    printf $PREREQ_INSTALL_PARAMS | XBE_Prerequisites/install_prerequisites.sh -x
    ## note: if prerequisites should configure python, execute deactivate here
}


while getopts ":o:u:" option; do
    case "${option}" in
        u)
            XYNA_USER=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done


if [[ -z ${XYNA_USER} ]]; then
    usage
fi

install_without_python
