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



# return codes:
# 0 = No update required.
# 1 = Downgrade. Abort! / Error
# 2 => Update.
# 3 => No old version. New Environment.

if [ $# -le 1 ]
then
  echo "required: path to old version file, path to new version file"
  exit 1
fi


# ./xynafactory.sh version | awk '{print $5}' | head -n 1
#8.2.11.17

if [[ ! -f $1 ]];
then
  # no old version. New environment
  echo "no old version. New environment"
  exit 3
fi

OLDVERSION=$(cat $1)
NEWVERSION=$(cat $2)

echo "oldversion: $OLDVERSION"
echo "newversion: $NEWVERSION"


#if they are equal, skip everything. no update required.
if [ "$OLDVERSION" = "$NEWVERSION" ];
then
  echo "versions are the same. No update required!"
  exit 0
fi


IFS='.' read -ra OLDVERSIONARRAY <<< "$OLDVERSION"
IFS='.' read -ra NEWVERSIONARRAY <<< "$NEWVERSION"
LENOLD=${#OLDVERSIONARRAY[@]}
LENNEW=${#NEWVERSIONARRAY[@]}

if [ $LENOLD -ne $LENNEW ];
then
  echo "version part count should be equal."
  echo "old version has $LENOLD parts"
  echo "new version has $LENNEW parts"
  exit 1
fi

for (( i=0; i<$LENOLD; i++ )); do
  if (( ${OLDVERSIONARRAY[$i]} > ${NEWVERSIONARRAY[$i]} ));
  then
    echo "old version is greater. prevent downgrade!"
    exit 1
  fi
  if (( ${OLDVERSIONARRAY[$i]} < ${NEWVERSIONARRAY[$i]} ));
  then
    echo "new version is greater. Update required!"
	exit 2
  fi
  #if both are equal, proceed to next version part
done
#if fore some reason we decide to add leading 0s or something
echo "version are equal. No update required!"
exit 0