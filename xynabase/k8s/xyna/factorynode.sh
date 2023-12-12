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


# example entry within factorynode.xml:
#
#  <factorynode>
#    <name>10.0.90.12</name>
#    <description>10.0.90.12</description>
#    <instanceId>1</instanceId>
#    <remoteAccessType>RMI</remoteAccessType>
#    <remoteAccessSpecificParams>hostname=10.0.90.12, port=1099, profiles=Monitoring</remoteAccessSpecificParams>
#  </factorynode>



# returns line number of first entry in factorynode tag for the given name
# if there is no factorynode with this name configured, a new tag is added
function f_determine_tag_position () {
  FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
  re='^[0-9]+$'
  if ! [[ $FROM =~ $re ]] ; then
    FROM=$(grep -n "</factorynodeTable>" "$XMLFILEPATH" | cut -d: -f1) # current position of closing factorynodeTable tag
        sed -i "$FROM i </factorynode>" "$XMLFILEPATH"
        sed -i "$FROM i <remoteAccessSpecificParams></remoteAccessSpecificParams>" "$XMLFILEPATH"
        sed -i "$FROM i <remoteAccessType></remoteAccessType>" "$XMLFILEPATH"
        sed -i "$FROM i <instanceId></instanceId>" "$XMLFILEPATH"
        sed -i "$FROM i <description></description>" "$XMLFILEPATH"
        sed -i "$FROM i <name>$PREFIX</name>" "$XMLFILEPATH"
        sed -i "$FROM i <factorynode>" "$XMLFILEPATH"
    # move past <factorynode> tag
    FROM=$((FROM + 1))
  fi
}

if [ "$FACTORYNODE_XMLFILEPATH" == "" ] || [ "$FACTORYNODE_MOUNTDIRECTORY" == "" ]; then
  echo "$0 environment variables FACTORYNODE_XMLFILEPATH and FACTORYNODE_MOUNTDIRECTORY have to be defined."
  echo "$0 FACTORYNODE_XMLFILEPATH: $FACTORYNODE_XMLFILEPATH"
  echo "$0 FACTORYNODE_MOUNTDIRECTORY: $FACTORYNODE_MOUNTDIRECTORY"
  exit 0
fi

XMLFILEPATH="${XYNA_PATH}/server/storage/$FACTORYNODE_XMLFILEPATH"
MOUNTDIRECTORY="$FACTORYNODE_MOUNTDIRECTORY/*"

# abort, if file does not exist
if [ ! -f "$XMLFILEPATH" ]; then
    echo "warning: $XMLFILEPATH not found! Creating it."
    touch $XMLFILEPATH
	echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' >> $XMLFILEPATH
	echo '<factorynodeTable transaction="0">' >> $XMLFILEPATH
	echo '</factorynodeTable>'>> $XMLFILEPATH
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
    KEY="name"
    #FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
    f_determine_tag_position
    TO=$((FROM + COUNT - 1))
    BLOCK=$(head -n $TO "$XMLFILEPATH" | tail -$COUNT)

    unset NAME NAMELINE NAMEINDEX

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

            if [[ $TAGKEY == "name" ]]; then
                NAME=$TAGVALUE
            fi


            IDX=$FROM
            REPLACED=false
            while IFS= read -r LINE; do

                # delay setting name
                if [[ $LINE =~ ^.*\<name\> ]]; then
                    NAMELINE=$LINE
                    NAMEINDEX=$IDX
                fi

                if [[ $LINE =~ ^.*\<$TAGKEY\> ]] && [[ $TARGETKEY != "name" ]]; then
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
    # replace name, if set
    if [ $NAME ] && [ $NAMELINE ] && [ $NAMEINDEX ]; then
        NEWLINE=$(echo "$NAMELINE" | sed "s#<name>.*</name>#<name>$NAME</name>#")
        sed -i "$NAMEINDEX s#.*#$NEWLINE#" "$XMLFILEPATH"
    fi


done
