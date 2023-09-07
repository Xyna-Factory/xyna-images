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
  echo "Recursively renames all files of format <NAME>.xml_<VERSION> to <NAME>.xml_0"
  echo "Usage: xmomrepository_adjust_revision.sh [OPTION] DIRECTORY"
  echo "  -d Debug-mode: Only prints mv-statements, but does not do any renaming"
  exit
fi

if [ $# -eq 1 ]
then
  find $1 -type f | grep -v "/runtimecontexts$" | grep -v "/history$" | sed 's/\(.*\)\(\_[0-9]*\)/mv \"\1\2\" \"\1_0"/' | sh
elif [ $# -eq 2 ] && [ $1 == "-d" ]
then
  find $2 -type f | grep -v "/runtimecontexts$" | grep -v "/history$" | sed 's/\(.*\)\(\_[0-9]*\)/mv \"\1\2\" \"\1_0"/'
else
  echo "Invalid option, use --help for more information"
fi
