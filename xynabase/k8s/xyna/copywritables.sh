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

FILE="/etc/opt/xyna/environment/black_edition_001_copy_to_writeable_pl.properties"

echo "$0: INFO: evaluate $FILE content - copy data stored in persistence layers to target location"

if [ ! -f "$FILE" ]; then
  echo "$0: INFO: No persistence layer config file ($FILE) found."
  echo "$0: INFO: done"
  exit 0
fi



for LINE in $(cat $FILE); do
  KEY=$(echo $LINE | cut -d'=' -f1)
  VALUE=$(echo $LINE | cut -d'=' -f2)

  # clear target directory to ensure a consistent state
  rm -rf ${XYNA_PATH}/server/storage/$VALUE/*
  cp -r ${XYNA_PATH}/server/storage/$KEY/* ${XYNA_PATH}/server/storage/$VALUE/
  echo "$0: INFO: copied $KEY to $VALUE in ${XYNA_PATH}/server/storage."
done
echo "$0: INFO: done"
exit 0