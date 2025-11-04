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

BLACK_ED_ETC_PROP_FILE_PATH="/etc/opt/xyna/environment/black_edition_001.properties"
_VENV_PATH="/etc/opt/xyna/environment/venv"


### awk block begin
read -r -d '' AWK_SRC_SET_PROP_IN_FILE <<'EOF'
{
  if ($1 == propname) { printf "%s=%s\n", propname, propval; count++ }
  else { print }
}
END {
  if (count == 0) { printf "%s=%s\n", propname, propval }
}
EOF
### awk block end


## parameters: property-name, property-value
adapt_env_property() {
  if [[ $# -ne 2 ]]; then
    echo "adapt_env_property(): Wrong number of parameters."
    exit 99
  fi
  awk '-F=' -v "propname=$1" -v "propval=$2" "${AWK_SRC_SET_PROP_IN_FILE}" "$BLACK_ED_ETC_PROP_FILE_PATH" > /tmp/tmp.env.props
  mv /tmp/tmp.env.props "$BLACK_ED_ETC_PROP_FILE_PATH"
}


## parameters: xyna-user, xyna-path
do_install_python_venv() {
  if [[ $# -ne 1 ]]; then
    echo "do_install_python_venv(): Wrong number of parameters."
    exit 99
  fi
  local _XYNA_PATH=$1
  echo "Going to install local venv for python"
  local JEP_VERSION=$( find "${_XYNA_PATH}/server/lib" -iname 'jep-*.jar' | awk -F- '{gsub("\.jar","",$NF); print $NF}' )
  echo "Found jep version=${JEP_VERSION}"
  python3 -m venv "${_VENV_PATH}"
  source "${_VENV_PATH}/bin/activate"
  pip3 install --upgrade pip
  pip3 install "jep==${JEP_VERSION}"
  pip3 uninstall -y setuptools
  deactivate
  rm -rf ~/.cache/pip
  local _JEP_PATH=$( find "${_VENV_PATH}" -name 'libjep.so' )
  cat "${_XYNA_PATH}/server/server.policy"
  cat "$BLACK_ED_ETC_PROP_FILE_PATH"
  ls -lat "$BLACK_ED_ETC_PROP_FILE_PATH"
  ls -lat "$_VENV_PATH"
  sed -i "s#//permission java.lang.RuntimePermission \"loadLibrary.TOKEN_PATH_TO_LIB\";#permission java.lang.RuntimePermission \"loadLibrary.${_JEP_PATH}\";#" ${_XYNA_PATH}/server/server.policy
  adapt_env_property "jep.module.path" "${_JEP_PATH}"
  adapt_env_property "python.venv.path" "${_VENV_PATH}"
  cat "${_XYNA_PATH}/server/server.policy"
  cat "$BLACK_ED_ETC_PROP_FILE_PATH"
  ls -lat "$BLACK_ED_ETC_PROP_FILE_PATH"
  ls -lat "$_VENV_PATH"
  find "$_VENV_PATH" -iname '*.jar'
}

XYNA_PATH=$( awk -F= '{ if ($1 == "installation.folder") print $2}' "$BLACK_ED_ETC_PROP_FILE_PATH" )
echo "XYNA_PATH=${XYNA_PATH}"
do_install_python_venv ${XYNA_PATH}
