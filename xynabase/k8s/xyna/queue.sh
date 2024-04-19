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

# if these environment variables are set, modify queue.xml entries acordingly:
#  QUEUE_XMLFILEPATH - queue.xml file location relative to the storage folder
#  QUEUE_MOUNTDIRECTORY - directory containing files with the following naming scheme:
#    <uniqueName>.<key> where key can be externalName, connectData or queueType
#
#
# example entry within queue.xml:
#
#  <queue>
#    <uniqueName>uni</uniqueName>
#    <externalName>ex</externalName>
#    <connectData>bUEsDBBQACAgIAFVGClUAA...</connectData>
#    <queueType>bUEsDBBQACAgIAEFGClUAAAA...</queueType>
#  </queue>

echo "$0 INFO: $0: modify queue.xml entries"
echo "$0 INFO: env: QUEUE_XMLFILEPATH: $QUEUE_XMLFILEPATH"
echo "$0 INFO: env: QUEUE_MOUNTDIRECTORY: $QUEUE_MOUNTDIRECTORY"
if [ "$QUEUE_XMLFILEPATH" == "" ] || [ "$QUEUE_MOUNTDIRECTORY" == "" ]; then
  echo "$0 INFO: environment variables QUEUE_XMLFILEPATH and QUEUE_MOUNTDIRECTORY have to be defined."
  echo "$0 INFO: done"
  exit 0
fi

XMLFILEPATH="${XYNA_PATH}/server/storage/$QUEUE_XMLFILEPATH"
MOUNTDIRECTORY="$QUEUE_MOUNTDIRECTORY/*"

# abort, if file does not exist
if [ ! -f "$XMLFILEPATH" ]; then
    echo "$0 WARN: $XMLFILEPATH not found!"
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
    COUNT=4
    KEY="uniqueName"
    FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)

    if [[ $FROM == ""  ]]; then
      echo "$0 WARN: Could not find queue '$PREFIX'"
      continue
    fi

    TO=$((FROM + COUNT - 1))
    BLOCK=$(head -n $TO "$XMLFILEPATH" | tail -$COUNT)

    unset CONNECTDATA CONNECTDATALINE CONNECTDATAIDX
    unset QUEUETYPE QUEUETYPELINE QUEUETYPEIDX

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

            if [ $TAGKEY == "connectData" ]; then
                CONNECTDATA=$TAGVALUE
            fi
            if [ $TAGKEY == "queueType" ]; then
                QUEUETYPE=$TAGVALUE
            fi

            IDX=FROM
            REPLACED=false
            while IFS= read -r LINE; do
                if [[ $LINE =~ ^.*\<$TAGKEY\> ]]; then
                    NEWLINE=$(echo "$LINE" | sed "s#<$TAGKEY>.*</$TAGKEY>#<$TAGKEY>$TAGVALUE</$TAGKEY>#")
                    sed -i "$IDX s#.*#$NEWLINE#" "$XMLFILEPATH"
                    REPLACED=true
                    echo "$0 INFO: set $TAGKEY for queue $PREFIX"
                fi
                if [[ $LINE =~ ^.*\<connectData\> ]]; then
                    CONNECTDATALINE=$LINE
                    CONNECTDATAIDX=$IDX
                fi
                if [[ $LINE =~ ^.*\<queueType\> ]]; then
                    QUEUETYPELINE=$LINE
                    QUEUETYPEIDX=$IDX
                fi
                IDX=$((IDX + 1))
            done <<< "$BLOCK"

            if [ $REPLACED = false ]; then
                echo "$0 WARN: could not find tag <$TAGKEY> within $PREFIX"
            fi
        fi
    done

    # replace connect data with processed connect data, if set
    if  [ "$CONNECTDATA" ] && [ "$CONNECTDATALINE" ] ; then
        # get classpath value with server libs
        SERVERLIBS=""
        SERVERLIBDIR="${XYNA_PATH}/server/lib/*.jar"
        for SERVERLIBFILEPATH in $SERVERLIBDIR; do
            SERVERLIBS+=$SERVERLIBFILEPATH":"
        done
        # process and set CONNECTDATA
        PROCESSEDCONNECTDATA=$(java -classpath $SERVERLIBS com.gip.xyna.xmcp.xfcli.scriptentry.CreateBlobbedQueueData $QUEUETYPE $CONNECTDATA )
        if [ $? != 0 ] ; then
          echo "$0 ERROR: Could not process connectdata."
          echo "$0        QueueType: $QUEUETYPE"
          echo "$0        ConnectData: $CONNECTDATA"
          continue
        fi
        NEWLINE=$(echo "$CONNECTDATALINE" | sed "s#<connectData>.*</connectData>#<connectData>$PROCESSEDCONNECTDATA</connectData>#")
        sed -i "$CONNECTDATAIDX s#.*#$NEWLINE#" "$XMLFILEPATH"
        echo "$0 INFO: set connectdata for queue $PREFIX"
    fi

    # replace queueType with processed queueType, if set
    if [ $QUEUETYPE ] && [ $QUEUETYPELINE ] ; then
        # get classpath value with server libs
        SERVERLIBS=""
        SERVERLIBDIR="${XYNA_PATH}/server/lib/*.jar"
        for SERVERLIBFILEPATH in $SERVERLIBDIR; do
            SERVERLIBS+=$SERVERLIBFILEPATH":"
        done
        # process and set QUEUETYPE
        PROCESSEDQUEUETYPE=$(java -classpath $SERVERLIBS com.gip.xyna.xmcp.xfcli.scriptentry.CreateBlobbedQueueData $QUEUETYPE)
        NEWLINE=$(echo "$QUEUETYPELINE" | sed "s#<queueData>.*</queueData>#<queueData>$PROCESSEDQUEUETYPE</queueData>#")
        sed -i "$QUEUETYPEIDX s#.*#$NEWLINE#" "$XMLFILEPATH"
        echo "$0 INFO: set queuetype for queue $PREFIX"
    fi
done

echo "$0 INFO: done"
exit 0