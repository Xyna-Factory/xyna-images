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
 
if [ $# -lt 3 ] || [ $# -gt 4 ] || [ $1 == "--help" ]
then
  echo "Merges entries from directory xmomrepository_readonly into xmomrepository and updates file runtimecontexts"
  echo "Usage: xmomrepository.sh [OPTION] DIR_READONLY DIR_XMOMREPOSITORY PATH_RUNTIMECONTEXTS"
  echo "  -d Debug-mode: Only lists changes to be made, without applying them"
  exit
fi

if [ $# -eq 3 ]
then
  rsync -ruvn $1 $2 | grep "^APP_[^/]*/$" | sed 's|\(APP_\)\(.*\)=\(.*\)/|\1\2=\3 \2/\3|' >> $3
  rsync -ruv $1 $2
elif [ $# -eq 4 ] && [ $1 == "-d" ]
then
  rsync -ruvn $2 $3 | grep "^APP_[^/]*/$"
else
  echo "Invalid option, use --help for more information"
fi
