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

#input: sourcedir file targetdir script

if [[ $# < 4 ]] ;
then
  echo "four arguments required: sourcedir file targetdir script ($#)"
  exit 1
fi

sourcedir=$1
file=$2
targetdir=$3
script=$4
md5sumFile="md5sum.txt"

echo "sourcedir: $1"
echo "file: $2"
echo "targetdir: $3"
echo "script: $4"

CURSUM=$(find ${sourcedir} -type f -exec md5sum {} \; | sort | awk '{print $1}' | md5sum)
OLDSUM=""
if [ -f "${targetdir}/$md5sumFile" ]; 
then
  echo "$FILE exists."
  OLDSUM=$(cat ${targetdir}/$md5sumFile)
fi

echo "CURSUM: $CURSUM"
echo "OLDSUM: $OLDSUM"
if [[ $CURSUM == $OLDSUM ]] ;
then
  echo "nothing to be done"
  exit 0
fi
echo "check sums are not equal. call script: $script"
$script
mkdir -p $targetdir
cp "$file" "$targetdir"
echo "$CURSUM" > "${targetdir}/$md5sumFile"

echo "DEBUG: md5ofFile @ xyna: $(md5sum $file)"
exit 0
