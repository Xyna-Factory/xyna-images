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

usage() {
    echo "Usage: $0 -o <OS-Image>"
    exit 1
}

while getopts ":o:" option; do
    case "${option}" in
        o)
            OS_IMAGE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z ${OS_IMAGE} ]]; then
    usage
fi


if [[ ${OS_IMAGE} == oraclelinux:* ]]; then
    if [[ ${OS_IMAGE} == oraclelinux:8 ]]; then
        pip3 uninstall -y setuptools
    fi
elif [[ ${OS_IMAGE} == redhat/ubi*:* ]]; then
    pip3 uninstall -y setuptools
elif [[ ${OS_IMAGE} == ubuntu:* ]]; then
    apt-get -y remove python3-pip
else
   echo "Warning: unsupported OS_IMAGE=${OS_IMAGE}"
fi
