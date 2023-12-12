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

# example entry within triggerinstances.xml:
#
#  <triggerinstances>
#    <id>Http#1036</id>
#    <revision>1036</revision>
#    <triggerinstancename>Http</triggerinstancename>
#    <triggername>Http</triggername>
#    <startparameter>4245:</startparameter>
#    <state>DISABLED</state>
#  </triggerinstances>

# file name prefix is <revision>_triggerinstancename
# e.g. 50_Http
# configure startparameter: Filename: "50_Http.startparameter" content: "4245:"

if [ "$TRIGGERINSTANCE_XMLFILEPATH" == "" ] || [ "$TRIGGERINSTANCE_MOUNTDIRECTORY" == "" ]; then
  echo "$0 environment variables TRIGGERINSTANCE_XMLFILEPATH and TRIGGERINSTANCE_MOUNTDIRECTORY have to be defined."
  exit 0
fi

XMLFILEPATH="${XYNA_PATH}/server/storage/$TRIGGERINSTANCE_XMLFILEPATH"
MOUNTDIRECTORY="$TRIGGERINSTANCE_MOUNTDIRECTORY/*"

# abort, if file does not exist
if [ ! -f "$XMLFILEPATH" ]; then
    echo "warning: $XMLFILEPATH not found!"
    exit 0
fi

# function to check, whether an element ($0) is contained in array ($1)
contains () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 1; done
  return 0
}

NAMEREGEX='^([0-9]+)_(.+)'

# get unique prefixes from file names
PREFIXES=()
for FILEPATH in $MOUNTDIRECTORY; do
    TAGKEY=$(basename "$FILEPATH")
    TAGKEYREV=$(echo $TAGKEY | rev)
    SPLITREV=(${TAGKEYREV/./ })
    SPLIT0=$(echo ${SPLITREV[1]} | rev)
	
    #adjust to key
    [[ $SPLIT0 =~ $NAMEREGEX ]]
    SPLIT0="${BASH_REMATCH[2]}#${BASH_REMATCH[1]}"
	
    if $(contains "$SPLIT0" "${PREFIXES[@]}"); then		
        PREFIXES+=($SPLIT0)
    fi
done

# for each unique prefix
for PREFIX in "${PREFIXES[@]}"; do
    # extract sub-tags belonging to xml entry
    COUNT=7
    KEY="id"
    FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
    TO=$((FROM + COUNT - 1))
    BLOCK=$(head -n $TO "$XMLFILEPATH" | tail -$COUNT)

    # for each file in config directory
    for FILEPATH in $MOUNTDIRECTORY; do
        TAGKEY=$(basename "$FILEPATH")
        TAGKEYREV=$(echo $TAGKEY | rev)
        SPLITREV=(${TAGKEYREV/./ })
        SPLIT0=$(echo ${SPLITREV[1]} | rev)
        TAGKEY=$(echo ${SPLITREV[0]} | rev)
		
		#adjust to key
		[[ $SPLIT0 =~ $NAMEREGEX ]]
		SPLIT0="${BASH_REMATCH[2]}#${BASH_REMATCH[1]}"

        ## if file matches prefix
        if [ $SPLIT0 == $PREFIX ]; then
            TAGVALUE=$(cat "$FILEPATH")

            IDX=FROM
            REPLACED=false
            while IFS= read -r LINE; do
                if [[ $LINE =~ ^.*\<$TAGKEY\/?\> ]]; then
                    NEWLINE=$(echo "$LINE" | sed "s!<$TAGKEY.*!<$TAGKEY>$TAGVALUE</$TAGKEY>!")
                    sed -i "$IDX s!.*!$NEWLINE!" "$XMLFILEPATH"
                    REPLACED=true
                fi
                IDX=$((IDX + 1))
            done <<< "$BLOCK"

            if [ $REPLACED = false ]; then
                echo "warning: could not find <$TAGKEY> tag within $PREFIX"
            fi
        fi
    done
done

exit 0