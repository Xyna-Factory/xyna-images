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
 
MOUNTDIRECTORY="/black-edition-properties/*"
TARGETFILE="/etc/opt/xyna/environment/black_edition_001.properties"

for FILEPATH in $MOUNTDIRECTORY; do
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
