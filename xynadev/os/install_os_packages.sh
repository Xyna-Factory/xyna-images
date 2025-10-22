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


### awk block begin
read -r -d '' AWK_SRC <<'EOF'
{
  if ($1 == propname) { printf "%s=%s\n", propname, propval; count++ }
  else { print }
}
END {
  if (count == 0) { printf "%s=%s\n", propname, propval }
}
EOF
### awk block end


adapt_env_props() {
  awk '-F=' -v "propname=$1" -v "propval=$2" "${AWK_SRC}" /etc/opt/xyna/environment/black_edition_001.properties > /tmp/tmp.env.props
  mv /tmp/tmp.env.props /etc/opt/xyna/environment/black_edition_001.properties
}


if [[ ${OS_IMAGE} == oraclelinux:* ]]; then
    echo "No additional package installation needed"
elif [[ ${OS_IMAGE} == redhat/ubi*:* ]]; then
    echo "No additional package installation needed"
elif [[ ${OS_IMAGE} == ubuntu:* ]]; then
    echo "Going to install additional packages"
    apt --no-install-recommends -y update
    apt -y upgrade
    apt-get -y install wget xinetd net-tools bind9utils vim-tiny less libxml2-utils gnupg ca-certificates curl gcc python3-dev python3-venv python3-pip systemd uuid-runtime

    su ${XYNA_USER}
    echo "Going to install pip3 jep for python"
    VENV_PATH="/etc/opt/xyna/environment/venv"
    python3 -m venv "${VENV_PATH}"
    source "${VENV_PATH}/bin/activate"
    pip3 install --upgrade pip
    pip3 install jep
    pip3 uninstall -y setuptools
    deactivate
    rm -rf ~/.cache/pip
    JEP_PATH=$( find "${VENV_PATH}" -name 'libjep.so' )
    sed -i "s#//permission java.lang.RuntimePermission \"loadLibrary.TOKEN_PATH_TO_LIB\";#permission java.lang.RuntimePermission \"loadLibrary.${JEP_PATH}\";#" ${XYNA_PATH}/server/server.policy
    adapt_env_props "jep.module.path" "${JEP_PATH}"
    adapt_env_props "python.venv.path" "${VENV_PATH}"
    exit

    apt-get -y remove python3-pip
    apt-get -y autoremove
    apt-get clean
    rm -rf /var/lib/apt/lists/*
else
    echo "Warning: unsupported OS_IMAGE=${OS_IMAGE}"
fi
