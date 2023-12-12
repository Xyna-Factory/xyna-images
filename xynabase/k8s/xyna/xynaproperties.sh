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


# example entry within xynaproperties.xml:
#
# <xynaproperties>
#     <propertykey>TestProperty</propertykey>
#     <propertyvalue>TestValue</propertyvalue>
#     <propertydocumentation/>
#     <factorycomponent>false</factorycomponent>
#     <binding>0</binding>
# </xynaproperties>

# returns line number of first entry in xynaproperties tag for the given name
# if there is no xynaproperties tag with this name configured, a new tag is added
function f_determine_tag_position () {
  FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
  re='^[0-9]+$'
  if ! [[ $FROM =~ $re ]] ; then
    FROM=$(grep -n "</xynapropertiesTable>" "$XMLFILEPATH" | cut -d: -f1) # current position of closing xynapropertiesTable tag
	sed -i "$FROM i </xynaproperties>" "$XMLFILEPATH"
	sed -i "$FROM i <binding>0</binding>" "$XMLFILEPATH"
	sed -i "$FROM i <remoteAccessSpecificParams></remoteAccessSpecificParams>" "$XMLFILEPATH"
	sed -i "$FROM i <factorycomponent>false</factorycomponent>" "$XMLFILEPATH"
	sed -i "$FROM i <propertydocumentation/>" "$XMLFILEPATH"
	sed -i "$FROM i <propertyvalue></propertyvalue>" "$XMLFILEPATH"
	sed -i "$FROM i <propertykey>$PREFIX</propertykey>" "$XMLFILEPATH"
	sed -i "$FROM i <xynaproperties>" "$XMLFILEPATH"
  fi
}

if [ "$XYNAPROPERTIES_XMLFILEPATH" == "" ] || [ "$XYNAPROPERTIES_MOUNTDIRECTORY" == "" ]; then
  echo "$0 environment variables XYNAPROPERTIES_XMLFILEPATH and XYNAPROPERTIES_MOUNTDIRECTORY have to be defined."
  exit 0
fi

XMLFILEPATH="${XYNA_PATH}/server/storage/$XYNAPROPERTIES_XMLFILEPATH"
MOUNTDIRECTORY="$XYNAPROPERTIES_MOUNTDIRECTORY/*"

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

# get unique prefixes from file names
PREFIXES=()
for FILEPATH in $MOUNTDIRECTORY; do
    TAGKEY=$(basename "$FILEPATH")
    TAGKEYREV=$(echo $TAGKEY | rev)
    SPLITREV=(${TAGKEYREV/./ })
    SPLIT0=$(echo ${SPLITREV[1]} | rev)
    if $(contains "$SPLIT0" "${PREFIXES[@]}"); then
        PREFIXES+=($SPLIT0)
    fi
done

# for each unique prefix
for PREFIX in "${PREFIXES[@]}"; do
    # extract sub-tags belonging to xml entry
    COUNT=5
    KEY="propertykey"
    #FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
    f_determine_tag_position
	TO=$((FROM + COUNT - 1))
    BLOCK=$(head -n $TO "$XMLFILEPATH" | tail -$COUNT)

    # for each file in config directory
    for FILEPATH in $MOUNTDIRECTORY; do
        TAGKEY=$(basename "$FILEPATH")
        TAGKEYREV=$(echo $TAGKEY | rev)
        SPLITREV=(${TAGKEYREV/./ })
        SPLIT0=$(echo ${SPLITREV[1]} | rev)
        TAGKEY=$(echo ${SPLITREV[0]} | rev)

        ## if file matches prefix
        if [ $SPLIT0 == $PREFIX ]; then

            TAGVALUE=$(cat "$FILEPATH")

            # tag key might end with _ENV
            if [[ $TAGKEY == *_ENV ]]; then
                TAGKEY=${TAGKEY::-4}
                TAGVALUE=${!TAGVALUE}
            fi

            IDX=FROM
            REPLACED=false
            while IFS= read -r LINE; do
                if [[ $LINE =~ ^.*\<$TAGKEY\> ]]; then
                    NEWLINE=$(echo "$LINE" | sed "s#<$TAGKEY>.*</$TAGKEY>#<$TAGKEY>$TAGVALUE</$TAGKEY>#")
                    sed -i "$IDX s#.*#$NEWLINE#" "$XMLFILEPATH"
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
