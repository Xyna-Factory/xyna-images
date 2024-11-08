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
 
if [ $# -eq 0 ] || [ $1 == "--help" ]
then
  echo "Recursively changes all revisions in history-files to 0"
  echo "Usage: xmomrepository_adjust_revision_history.sh [OPTION] DIR_XMOMREPOSITORY"
  echo "  -d Debug-mode: Only lists changes to be made, without applying them"
  exit
fi

if [ $# -eq 1 ]
then
  find $1 -type f -name "history" -exec sed -i "s/^[0-9]* /0 /g" '{}' \;
elif [ $# -eq 2 ] && [ $1 == "-d" ]
then
  find $2 -type f -name "history" -exec echo sed -i "s/^[0-9]* /0 /g" '{}' \;
else
  echo "Invalid option, use --help for more information"
fi
