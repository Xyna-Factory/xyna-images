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

. $NVM_DIR/nvm.sh

. build.conf

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GIT_BRANCH_XYNA_FACTORY=""
GIT_BRANCH_XYNA_MODELLER=""


usage() {
    echo "Usage: $0 -f <GIT_BRANCH_XYNA_FACTORY> -m <GIT_BRANCH_XYNA_MODELLER>"
    exit 1
}

while getopts ":f:m:" option; do
    case "${option}" in
        f)
            GIT_BRANCH_XYNA_FACTORY=${OPTARG}
            ;;
        m)
            GIT_BRANCH_XYNA_MODELLER=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z ${GIT_BRANCH_XYNA_FACTORY} ]]; then
    usage
fi
if [[ -z ${GIT_BRANCH_XYNA_MODELLER} ]]; then
    usage
fi

echo "GIT_BRANCH_XYNA_FACTORY=${GIT_BRANCH_XYNA_FACTORY}"
echo "GIT_BRANCH_XYNA_MODELLER=${GIT_BRANCH_XYNA_MODELLER}"

rm -rf xyna-factory
rm -rf xyna-modeller
git clone --branch ${GIT_BRANCH_XYNA_FACTORY} ${GITHUB_REPOSITORY_XYNA_FACTORY}
git clone --branch ${GIT_BRANCH_XYNA_MODELLER} --recurse-submodules ${GITHUB_REPOSITORY_XYNA_MODELLER}

NODEJS_VERSION=$(python3 get_nodejs_version.py --package_jsonfile ${PACKAGE_JSONFILE})
echo "nvm install ${NODEJS_VERSION}"
nvm install ${NODEJS_VERSION}
echo "nvm use ${NODEJS_VERSION}"
nvm use ${NODEJS_VERSION}

cd ${SCRIPT_DIR}/xyna-factory/installation/build
python3 checkAppVersions.py
cd ${SCRIPT_DIR}/xyna-factory/installation
./build.sh install_libs
./build.sh all -b ${GIT_BRANCH_XYNA_MODELLER}
cp ${SCRIPT_DIR}/xyna-factory/*.zip ${SCRIPT_DIR}
ls -l
