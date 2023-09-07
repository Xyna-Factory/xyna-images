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
 
#!/bin/bash
#does not support version names containing spaces!

if [ $# -eq 0 ]
then
  echo "required: application name"
  exit 1
fi

APPNAME=$1
echo "searching for application '$APPNAME'."
SPACES=$(echo "$APPNAME" | tr -cd ' ' | wc -c)
echo "application name contains $SPACES spaces."
VERSION=$(${XYNA_PATH}/server/xynafactory.sh listapplications -t | grep "^$APPNAME\s*│" | awk "{print \$$((3+$SPACES))}")
echo "version: $VERSION"
${XYNA_PATH}/server/xynafactory.sh stopapplication -versionName "$VERSION" -applicationName "$APPNAME"  ${@:2}