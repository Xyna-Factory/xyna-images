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

XYNAFACTORY_SH="${XYNA_PATH}/server/xynafactory.sh"
STATE=$($XYNAFACTORY_SH status)
if [ "$STATE" == "Status: 'Up and running'" ]
then
  # prepare a variable that contains one command for all running apps to stop them
  STOP_RUNNING_APPS=$($XYNAFACTORY_SH listapplications | grep RUNNING | awk -v xyna="$XYNAFACTORY_SH" 'BEGIN {FS="'\''"} {print xyna " stopapplication -applicationName \"" $2 "\" -versionName \"" $4 "\" ;"} ')
  STOP_RUNNING_APPS=$(echo $STOP_RUNNING_APPS| sed "s/'//g")
  echo $STOP_RUNNING_APPS
  # stopping the apps
  eval "$STOP_RUNNING_APPS"

  # stopping xyna itself
  $XYNAFACTORY_SH stop
fi
exit 0
