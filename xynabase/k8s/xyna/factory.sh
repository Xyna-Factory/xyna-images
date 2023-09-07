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
 
#!/bin/bash
#nohup /usr/sbin/rsyslogd -n &

# execute sub scripts
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# everything that needs to happen immediately (even before factory-scripts)
# e.g. copy/modify of black_edition_001.properties
$SCRIPT_DIR/prepareenvironment.sh

# includes pre start script, implemented by projects
$SCRIPT_DIR/factoryprestart.sh


# start xyna factory
${XYNA_PATH}/server/xynafactory.sh start &

# loop checking for the status of the xyna factory
STARTUP=false
STOPPED=false
STARTUP=false

while [ $STOPPED = false ]; do
  sleep 5
  STATE=$(${XYNA_PATH}/server/xynafactory.sh status)
  # check, whether the status of the xyna factory is 'up and running' for the first time since its start
  if [ $STARTUP = false ] && [ "$STATE" == "Status: 'Up and running'" ]; then
    STARTUP=true
    # execute post start script, implemented by projects
    $SCRIPT_DIR/poststart.sh
  fi
  if [ "$STATE" == "Status: 'Starting'" ]; then
    STARTING=true
  fi
  # check, whether the status of the xyna factory is 'not running' anymore
  if [ "$STATE" == "Status: 'Not running'" ] && [ "$STARTING" == true ]; then
    # exit loop
    STOPPED=true
    echo "Factory not running"
  fi
done
echo "$0 - FINISHED"
