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



# return codes:
# 0 = No update required.
# 1 = Downgrade. Abort! / Error
# 2 => Update.
# 3 => No old version. New Environment.

if [ $# -le 1 ]
then
  echo "$0 ERROR: required: path to old version file, path to new version file"
  exit 1
fi


# ./xynafactory.sh version | awk '{print $5}' | head -n 1
#9.1.0.1

if [[ ! -f $1 ]];
then
  # no old version. New environment
  echo "$0 INFO: no old version. New environment"
  exit 3
fi

OLDVERSION=$(cat $1)
NEWVERSION=$(cat $2)

echo "$0 INFO: oldversion: $OLDVERSION (read from $1)"
echo "$0 INFO: newversion: $NEWVERSION (read from $2)"


#if they are equal, skip everything. no update required.
if [ "$OLDVERSION" = "$NEWVERSION" ];
then
  echo "$0 INFO: versions are the same. No update required!"
  exit 0
fi


IFS='.' read -ra OLDVERSIONARRAY <<< "$OLDVERSION"
IFS='.' read -ra NEWVERSIONARRAY <<< "$NEWVERSION"
LENOLD=${#OLDVERSIONARRAY[@]}
LENNEW=${#NEWVERSIONARRAY[@]}

if [ $LENOLD -ne $LENNEW ];
then
  echo "$0 ERROR: version part count should be equal."
  echo "$0 ERROR: old version has $LENOLD parts"
  echo "$0 ERROR: new version has $LENNEW parts"
  exit 1
fi

for (( i=0; i<$LENOLD; i++ )); do
  if (( ${OLDVERSIONARRAY[$i]} > ${NEWVERSIONARRAY[$i]} ));
  then
    echo "$0 INFO: old version is greater. prevent downgrade!"
    exit 1
  fi
  if (( ${OLDVERSIONARRAY[$i]} < ${NEWVERSIONARRAY[$i]} ));
  then
    echo "$0 INFO: new version is greater. Update required!"
    exit 2
  fi
  #if both are equal, proceed to next version part
done
#if fore some reason we decide to add leading 0s or something
echo "$0 INFO: version are equal. No update required!"
exit 0