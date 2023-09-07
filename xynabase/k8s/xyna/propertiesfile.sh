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

echo "Running: $0"

if (( $# < 2 )); then
  echo "  two arguments required: path to the directory containing the data to inject without tailing /, path to the properties-file to inject data into"
  exit 1
fi

MOUNTDIRECTORY=$1
TARGETFILE=$2

echo "  MOUNTDIRECTORY: $MOUNTDIRECTORY"
echo "  TARGETFILE: $TARGETFILE"

if [[ ! -d $MOUNTDIRECTORY ]]; then
  echo "  \"$MOUNTDIRECTORY\" is not a directory!"
  exit 1
fi

if [[ ! -f $TARGETFILE ]]; then
  echo "  \"$TARGETFILE\" is not a file!"
  exit 1
fi

for FILEPATH in $MOUNTDIRECTORY/*; do
  if [[ ! -f $FILEPATH ]]; then
    echo "  skip: \"$FILEPATH\" - not a file."
    continue
  fi

  KEY=$(basename "$FILEPATH")
  if (( $(cat $TARGETFILE | grep "^$KEY=" | wc -l) == 1 )); then
    # update value for existing key
	ESCAPED=$(cat "$FILEPATH" | sed "s#/#\\\/#")
    SEDLINE="/^$KEY=.*$/c$KEY=$ESCAPED"
    sed -i "${SEDLINE}" $TARGETFILE
  else
    # add entry
    sed -i "$ a $KEY=$(cat $FILEPATH)" $TARGETFILE
  fi
done

echo "Finished: $0"

exit 0