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


#  <internetaddress>
#    <id>someIP</id>
#    <ip>1.1.1.1</ip>
#  </internetaddress>



function f_determine_tag_position () {
  FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
  echo "found <$KEY>$PREFIX</$KEY> at line '$FROM'"
  re='^[0-9]+$'
  if ! [[ $FROM =~ $re ]] ; then
    echo "adding internetaddress"
    FROM=$(grep -n "</internetaddressTable>" "$XMLFILEPATH" | cut -d: -f1) # current position of closing internetaddressTable tag
    sed -i "$FROM i </internetaddress>" "$XMLFILEPATH"
    sed -i "$FROM i <documentation></documentation>" "$XMLFILEPATH"
    sed -i "$FROM i <ip></ip>" "$XMLFILEPATH"
    sed -i "$FROM i <id>$PREFIX</id>" "$XMLFILEPATH"
    sed -i "$FROM i <internetaddress>" "$XMLFILEPATH"
    # move past <internetaddress> tag
    FROM=$((FROM + 1))
  fi
}

if [ "$IPADDRESS_XMLFILEPATH" == "" ] || [ "$IPADDRESS_MOUNTDIRECTORY" == "" ]; then
  echo "$0 environment variables IPADDRESS_XMLFILEPATH and IPADDRESS_MOUNTDIRECTORY have to be defined."
  echo "$0 IPADDRESS_XMLFILEPATH: $IPADDRESS_XMLFILEPATH"
  echo "$0 IPADDRESS_MOUNTDIRECTORY: $IPADDRESS_MOUNTDIRECTORY"
  exit 0
fi

XMLFILEPATH="${XYNA_PATH}/server/storage/$IPADDRESS_XMLFILEPATH"
MOUNTDIRECTORY="$IPADDRESS_MOUNTDIRECTORY/*"

# create file if it does not exist
if [ ! -f "$XMLFILEPATH" ]; then
    echo "warning: $XMLFILEPATH not found! Creating it."
    touch $XMLFILEPATH
    echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' >> $XMLFILEPATH
    echo '<internetaddressTable transaction="0">' >> $XMLFILEPATH
    echo '</internetaddressTable>'>> $XMLFILEPATH
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
    COUNT=4
    KEY="id"
    #FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
    f_determine_tag_position
    TO=$((FROM + COUNT - 1))
    BLOCK=$(head -n $TO "$XMLFILEPATH" | tail -$COUNT)

    unset ID IDLINE IDINDEX

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

            if [[ $TAGKEY == "id" ]]; then
                ID=$TAGVALUE
            fi


            IDX=$FROM
            REPLACED=false
            while IFS= read -r LINE; do

                # delay setting id
                if [[ $LINE =~ ^.*\<id\> ]]; then
                    IDLINE=$LINE
                    IDINDEX=$IDX
                fi

                if [[ $LINE =~ ^.*\<$TAGKEY\> ]] && [[ $TARGETKEY != "id" ]]; then
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
    # replace id, if set
    if [ $ID ] && [ $IDLINE ] && [ $IDINDEX ]; then
        NEWLINE=$(echo "$IDLINE" | sed "s#<id>.*</id>#<id>$ID</id>#")
        sed -i "$IDLINE s#.*#$NEWLINE#" "$XMLFILEPATH"
    fi


done
