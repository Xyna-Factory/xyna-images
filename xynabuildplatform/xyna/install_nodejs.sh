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

set -e # enable errexit option
set -u # enable nounset option
set -o pipefail

. $HOME/.nvm/nvm.sh

NODEJS_VERSION=

usage() {
    echo "Usage: $0 -v <NODEJS_VESION>"
    exit 1
}

while getopts ":v:" option; do
    case "${option}" in
        v)
            NODEJS_VERSION=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z ${NODEJS_VERSION} ]]; then
    usage
fi


echo "nvm install ${NODEJS_VERSION}"
nvm install ${NODEJS_VERSION}
echo "nvm use ${NODEJS_VERSION}"
nvm use ${NODEJS_VERSION}
