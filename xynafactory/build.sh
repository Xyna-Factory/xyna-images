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

HERE=$(dirname "$0")
cd "${HERE}"
HERE=$(pwd)


OS_IMAGE=""
BASE_IMAGE=""
NEW_IMAGE=""

usage() {
    echo "Usage: $0 -o <OS-IMAGE> -b <BASE-IMAGE> -n <NEW-IMAGE>"
    exit 1
}

while getopts ":b:n:o:" option; do
    case "${option}" in
        o)
            OS_IMAGE=${OPTARG}
            ;;
        b)
            BASE_IMAGE=${OPTARG}
            ;;
        n)
            NEW_IMAGE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z ${BASE_IMAGE} ]]; then
    usage
fi
if [[ -z ${OS_IMAGE} ]]; then
    usage
fi
if [[ -z ${NEW_IMAGE} ]]; then
    usage
fi

mkdir -p "${HERE}/os"
cp "${HERE}/../lib_scripts/os/"*.sh "${HERE}/os"

# Build new image based on xyna base image
docker build --build-arg XYNABASE_IMAGE=${BASE_IMAGE} --build-arg OS_IMAGE=${OS_IMAGE} -t ${NEW_IMAGE} .


