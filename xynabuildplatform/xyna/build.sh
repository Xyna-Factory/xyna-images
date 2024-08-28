#!/bin/bash

set -e # enable errexit option
set -u # enable nounset option
set -o pipefail

GIT_BRANCH_XYNA_FACTORY=""
GIT_BRANCH_XYNA_MODELLER=""

. build.conf

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
echo "NODEJS_VERSION=${NODEJS_VERSION}"
source $HOME/.nvm/nvm.sh
nvm install ${NODEJS_VERSION}
nvm use ${NODEJS_VERSION}

cd xyna-factory/installation/build
python3 checkAppVersions.py
cd -
cd xyna-factory/installation
./build.sh all -b ${GIT_BRANCH_XYNA_MODELLER}
cd -
cp xyna-factory/*.zip .
ls -l
