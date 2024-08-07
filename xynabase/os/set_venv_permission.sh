#!/bin/bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copyright 2024 Xyna GmbH, Germany
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

set -e

JEPLINE=$(grep "jep.module.path=" /etc/opt/xyna/environment/black_edition_001.properties)
JEP_PATH=${JEPLINE#*=}
sed -i "s#//permission java.lang.RuntimePermission \"loadLibrary.TOKEN_PATH_TO_LIB\";#permission java.lang.RuntimePermission \"loadLibrary.${JEP_PATH}\";#" ${XYNA_PATH}/server/server.policy