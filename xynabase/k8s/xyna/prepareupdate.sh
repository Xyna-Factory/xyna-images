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



if [[ $PVPATH == "" ]];then
  echo "ERROR: Environment variable PVPATH not set."
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

$SCRIPT_DIR/prepareenvironment.sh

$SCRIPT_DIR/validateversion.sh $PVPATH/storage/version.txt ${XYNA_PATH}/server/version.txt
RESULT=$?
echo "$0 INFO: result from validateversion (0=no update, 1=error, 2=update, 3=new environment): $RESULT"
if (( $RESULT == 0 )); then
  # no update required
  exit 0
fi

if (( $RESULT == 1 )); then
  # downgrade/error
  exit 1
fi

if (( $RESULT == 2 )); then
  # update
  rm -rf $PVPATH/next/
  mkdir $PVPATH/next
  for FILE in ${XYNA_PATH}/server/storage/*; do
    FILENAME=$(basename $FILE)
    cp -r ${XYNA_PATH}/server/storage/$FILENAME $PVPATH/next/$FILENAME
  done
  cp ${XYNA_PATH}/server/version.txt $PVPATH/next/version.txt
  echo "$0 INFO: files from ${XYNA_PATH}/server/storage copied to $PVPATH/next. Ready for update."
  exit 0
fi

if (( $RESULT == 3 )); then
  # new environment
  rm -rf $PVPATH/storage
  mkdir $PVPATH/storage
  for FILE in ${XYNA_PATH}/server/storage/*; do
    FILENAME=$(basename $FILE)
    cp -r ${XYNA_PATH}/server/storage/$FILENAME $PVPATH/storage/$FILENAME
  done
  cp ${XYNA_PATH}/server/version.txt $PVPATH/storage/version.txt
  echo "$0 INFO: files from ${XYNA_PATH}/server/storage copied to $PVPATH/storage. New Environment set."
  exit 0
fi

echo "$0 ERROR: Unexpected return code from validateversion.sh: $RESULT"
exit 1