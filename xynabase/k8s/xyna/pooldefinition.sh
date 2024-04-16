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

# if these environment variables are set, modify pooldefinition.xml entries acordingly:
#  POOLDEFINITION_XMLFILEPATH - pooldefinition.xml file location relative to the storage folder
#  POOLDEFINITION_MOUNTDIRECTORY - directory containing files with the following naming scheme:
#    <poolname>.<key> where key can be type, size, user, password, retries, params, validationinterval, connectstring
#    the file content will be used to set the value in pooldefinition.xml. The password will be encrypted.
#
# 
# example entry within pooldefinition.xml:
#
# <pooldefinition>
#     <name>Xyna-Infra-Pool</name>
#     <type>MySQL</type>
#     <size>7</size>
#     <user>xyna</user>
#     <password>jXGyRlXEphjW6Hl1W8gQrOkqZx...</password>
#     <retries>2</retries>
#     <params/>
#     <validationinterval>10000</validationinterval>
#     <connectstring>jdbc:mysql://10.0.10.131/xyna</connectstring>
#     <version>3</version>
#     <uuid>55ebd1fe-2cb3-4224-b354-84c8f60ff0f8</uuid>
# </pooldefinition>

echo "$0 INFO: $0: modify pooldefinition.xml entries"
echo "$0 INFO: env: POOLDEFINITION_XMLFILEPATH: $POOLDEFINITION_XMLFILEPATH"
echo "$0 INFO: env: POOLDEFINITION_MOUNTDIRECTORY: $POOLDEFINITION_MOUNTDIRECTORY"
if [ "$POOLDEFINITION_XMLFILEPATH" == "" ] || [ "$POOLDEFINITION_MOUNTDIRECTORY" == "" ]; then
  echo "$0 INFO: environment variables POOLDEFINITION_XMLFILEPATH and POOLDEFINITION_MOUNTDIRECTORY have to be defined."
  echo "$0 INFO: done"
  exit 0
fi

XMLFILEPATH="${XYNA_PATH}/server/storage/$POOLDEFINITION_XMLFILEPATH"
MOUNTDIRECTORY="$POOLDEFINITION_MOUNTDIRECTORY/*"

# abort, if file does not exist
if [ ! -f "$XMLFILEPATH" ]; then
    echo "$0: WARN: $XMLFILEPATH not found!"
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
    COUNT=11
    KEY="name"
    FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
    if [[ $FROM == ""  ]]; then
      echo "$0 WARN: Could not find pool '$PREFIX'"
      continue
    fi

    TO=$((FROM + COUNT - 1))
    BLOCK=$(head -n $TO "$XMLFILEPATH" | tail -$COUNT)

    unset PASSWORD PASSWORDLINE PASSWORDIDX
    unset UUID UUIDLINE UUIDIDX

    # for each file in config directory
    for FILEPATH in $MOUNTDIRECTORY; do
        TAGKEY=$(basename "$FILEPATH")
        TAGKEYREV=$(echo $TAGKEY | rev)
        SPLITREV=(${TAGKEYREV/./ })
        SPLIT0=$(echo ${SPLITREV[1]} | rev)
        TAGKEY=$(echo ${SPLITREV[0]} | rev)

        ## if file matches prefix
        if [[ $SPLIT0 == $PREFIX ]]; then
            TAGVALUE=$(cat "$FILEPATH")

            if [[ $TAGKEY == "password" ]]; then
                PASSWORD=$TAGVALUE
            fi
            if [[ $TAGKEY == "uuid" ]]; then
                UUID=$TAGVALUE
            fi

            IDX=FROM
            REPLACED=false
            while IFS= read -r LINE; do
                if [[ $LINE =~ ^.*\<$TAGKEY\> ]]; then
                    NEWLINE=$(echo "$LINE" | sed "s#<$TAGKEY>.*</$TAGKEY>#<$TAGKEY>$TAGVALUE</$TAGKEY>#")
                    sed -i "$IDX s#.*#$NEWLINE#" "$XMLFILEPATH"
                    REPLACED=true
                    echo "$0 INFO: set <$TAGKEY> for pool $PREFIX"
                fi
                if [[ $LINE =~ ^.*\<password\> ]]; then
                    PASSWORDLINE=$LINE
                    PASSWORDIDX=$IDX
                fi
                if [[ $LINE =~ ^.*\<uuid\> ]]; then
                    UUIDLINE=$LINE
                    UUIDIDX=$IDX
                fi
                IDX=$((IDX + 1))
            done <<< "$BLOCK"

            if [ $REPLACED = false ]; then
                echo "$0 WARN: could not find tag <$TAGKEY> within pool $PREFIX"
            fi
        fi
    done

    # replace password with encrypted password, if set
    if [ $PASSWORD ] && [ $PASSWORDLINE ] && [ $UUIDLINE ]; then
        # replace uuid with generated uuid, if not set
        if [ !$UUID ]; then
            UUID=$(uuidgen)
            NEWLINE=$(echo "$UUIDLINE" | sed "s#<uuid>.*</uuid>#<uuid>${UUID,,}</uuid>#")
            sed -i "$UUIDIDX s#.*#$NEWLINE#" "$XMLFILEPATH"
        fi
        # get classpath value with server libs
        SERVERLIBS=""
        SERVERLIBDIR="${XYNA_PATH}/server/lib/*.jar"
        for SERVERLIBFILEPATH in $SERVERLIBDIR; do
            SERVERLIBS+=$SERVERLIBFILEPATH":"
        done
        # encrypt and set password
        ENCRYPTEDPASSWORD=$(java -classpath $SERVERLIBS com.gip.xyna.xmcp.xfcli.scriptentry.EncryptPoolDefinitionPassword "$PASSWORD" $UUID)
        NEWLINE=$(echo "$PASSWORDLINE" | sed "s#<password>.*</password>#<password>$ENCRYPTEDPASSWORD</password>#")
        sed -i "$PASSWORDIDX s#.*#$NEWLINE#" "$XMLFILEPATH"
    fi
done

echo "$0 INFO: done" 
exit 0