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

### install packages not yet present in xynabase-image

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
    echo "No additional packages needed"
elif [[ ${OS_IMAGE} == redhat/ubi*:* ]]; then
    echo "No additional packages needed"
elif [[ ${OS_IMAGE} == ubuntu:* ]]; then
    echo "Going to install additional packages (no python)"
    apt --no-install-recommends -y update
    apt -y upgrade
    #apt-get -y install wget xinetd net-tools bind9utils vim-tiny less libxml2-utils gnupg ca-certificates curl gcc systemd uuid-runtime
    #apt-get -y install net-tools
else
    echo "Warning: unsupported OS_IMAGE=${OS_IMAGE}"
fi
