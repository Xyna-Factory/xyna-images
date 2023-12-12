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



SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

$SCRIPT_DIR/prepareenvironment.sh

$SCRIPT_DIR/validateversion.sh $PVPATH/storage/version.txt ${XYNA_PATH}/server/version.txt
RESULT=$?

echo "result from validateversion (0=no update, 1=error, 2=update, 3=new environment): $RESULT"
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
  echo "Update detected. Copy files from persistent volume to server/storage."
  for FILE in $PVPATH/storage/*; do
    FILENAME=$(basename $FILE)
	
	#skip version.txt
	if [ -f $PVPATH/storage/$FILENAME ]; then
	  continue
	fi
	
	mkdir -p ${XYNA_PATH}/server/storage/$FILENAME
    cp -r  $PVPATH/storage/$FILENAME/* ${XYNA_PATH}/server/storage/$FILENAME
  done
  
  # prepare factory start
  echo "call factoryprestart.sh"
  $SCRIPT_DIR/factoryprestart.sh
  
  echo "start xynafactory"
  ${XYNA_PATH}/server/xynafactory.sh start
  
  STATE=$(${XYNA_PATH}/server/xynafactory.sh status)
  if [ "$STATE" == "Status: 'Not running'" ]; then
    echo "ERROR factory could not apply update!"
	exit 1
  fi
  
  NEWVERSION=$(${XYNA_PATH}/server/xynafactory.sh version | awk '{print $5}' | head -n 1)
  VERSIONLINES=$(./xynafactory.sh version | wc -l)
  
  echo "stop xynafactory"
  ${XYNA_PATH}/server/xynafactory.sh stop
  #check if update was successful
  if (( $VERSIONLINES == 2 )); then
    echo "update was successful."
    for FILE in $PVPATH/next/*; do
	  FILENAME=$(basename $FILE)
      rm -rf $PVPATH/storage/$FILENAME
      cp -r  $PVPATH/next/$FILENAME $PVPATH/storage/$FILENAME
    done
    rm $PVPATH/storage/version.txt
    echo "$NEWVERSION" >> $PVPATH/storage/version.txt
    echo "update to $NEWVERSION finished."
	exit 0
  else
    echo "update failed."
	echo $NEWVERSION
	exit 1
  fi
fi

if (( $RESULT == 0 )); then
  # new environment => should not happen, becuase even in that usecase, the first init countainer should have created files in $PVPATH/storage
  echo "Error: New environment detected. First init counter should have created $PVPATH/storage"
  exit 1
fi