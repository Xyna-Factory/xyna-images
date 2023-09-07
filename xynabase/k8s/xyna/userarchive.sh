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

# example entry within pooldefinition.xml:
#
# <userarchive>
#     <name>XYNAMODELLER</name>
#     <role>MODELLER</role>
#     <password>88d7f9526e66c8d1a0961ccb973c4481</password>
#     <creationDate>1628261972936</creationDate>
#     <locked>false</locked>
#     <domains>XYNA</domains>
#     <failedLogins>0</failedLogins>
#     <passwordChangeDate>1628261972936</passwordChangeDate>
#     <passwordChangeReason>NEW_USER</passwordChangeReason>
# </userarchive>


if [ "$USERARCHIVE_XMLFILEPATH" == "" ] || [ "$USERARCHIVE_MOUNTDIRECTORY" == "" ]; then
  echo "$0 environment variables USERARCHIVE_XMLFILEPATH and USERARCHIVE_MOUNTDIRECTORY have to be defined."
  exit 0
fi

XMLFILEPATH="$XYNA_PATH/server/storage/$USERARCHIVE_XMLFILEPATH"
MOUNTDIRECTORY="$USERARCHIVE_MOUNTDIRECTORY/*"

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
    COUNT=11
    KEY="name"
    FROM=$(grep -n "<$KEY>$PREFIX</$KEY>" "$XMLFILEPATH" | cut -d: -f1)
    TO=$((FROM + COUNT - 1))
    BLOCK=$(head -n $TO "$XMLFILEPATH" | tail -$COUNT)

    unset PASSWORD PASSWORDLINE PASSWORDIDX

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

            if [ $TAGKEY == "password" ]; then
                PASSWORD=$TAGVALUE
            fi

            IDX=FROM
            REPLACED=false
            while IFS= read -r LINE; do
                if [[ $LINE =~ ^.*\<$TAGKEY\> ]]; then
                    NEWLINE=$(echo "$LINE" | sed "s#<$TAGKEY>.*</$TAGKEY>#<$TAGKEY>$TAGVALUE</$TAGKEY>#")
                    sed -i "$IDX s#.*#$NEWLINE#" "$XMLFILEPATH"
                    REPLACED=true
                fi
                if [[ $LINE =~ ^.*\<password\> ]]; then
                    PASSWORDLINE=$LINE
                    PASSWORDIDX=$IDX
                fi
                IDX=$((IDX + 1))
            done <<< "$BLOCK"

            if [ $REPLACED = false ]; then
                echo "warning: could not find <$TAGKEY> tag within $PREFIX"
            fi
        fi
    done

    # replace password with encrypted password, if set
    if [ $PASSWORD ] && [ $PASSWORDLINE ]; then
        # get password algorithm parameters from xyna properties
        LOGIN_HASHALGORITHM="?"
        LOGIN_ROUNDS="?"
        LOGIN_STATICSALT="?"
        PERSISTENCE_HASHALGORITHM="?"
        PERSISTENCE_ROUNDS="?"
        PERSISTENCE_SALT_LENGTH="?"
        if [ -d "$XYNAPROPERTIES_MOUNTDIRECTORY" ]; then
            XYNAPROPERTY="$XYNAPROPERTIES_MOUNTDIRECTORY/xyna.xfmg.xopctrl.usermanagement.login.hashalgorithm.propertyvalue"
            [ -f "$XYNAPROPERTY" ] && LOGIN_HASHALGORITHM=$(cat "$XYNAPROPERTY")
            XYNAPROPERTY="$XYNAPROPERTIES_MOUNTDIRECTORY/xyna.xfmg.xopctrl.usermanagement.login.rounds.propertyvalue"
            [ -f "$XYNAPROPERTY" ] && LOGIN_ROUNDS=$(cat "$XYNAPROPERTY")
            XYNAPROPERTY="$XYNAPROPERTIES_MOUNTDIRECTORY/xyna.xfmg.xopctrl.usermanagement.login.staticsalt.propertyvalue"
            [ -f "$XYNAPROPERTY" ] && LOGIN_STATICSALT=$(cat "$XYNAPROPERTY")
            XYNAPROPERTY="$XYNAPROPERTIES_MOUNTDIRECTORY/xyna.xfmg.xopctrl.usermanagement.persistence.hashalgorithm.propertyvalue"
            [ -f "$XYNAPROPERTY" ] && PERSISTENCE_HASHALGORITHM=$(cat "$XYNAPROPERTY")
            XYNAPROPERTY="$XYNAPROPERTIES_MOUNTDIRECTORY/xyna.xfmg.xopctrl.usermanagement.persistence.rounds.propertyvalue"
            [ -f "$XYNAPROPERTY" ] && PERSISTENCE_ROUNDS=$(cat "$XYNAPROPERTY")
            XYNAPROPERTY="$XYNAPROPERTIES_MOUNTDIRECTORY/xyna.xfmg.xopctrl.usermanagement.persistence.salt.length.propertyvalue"
            [ -f "$XYNAPROPERTY" ] && PERSISTENCE_SALT_LENGTH=$(cat "$XYNAPROPERTY")
        fi
        # get classpath value with server libs
        SERVERLIBS=""
        SERVERLIBDIR="$XYNA_PATH/server/lib/*.jar"
        for SERVERLIBFILEPATH in $SERVERLIBDIR; do
            SERVERLIBS+=$SERVERLIBFILEPATH":"
        done
        # encrypt and set password
        ENCRYPTEDPASSWORD=$(java -classpath $SERVERLIBS com.gip.xyna.xmcp.xfcli.scriptentry.EncryptUserArchivePassword "$PASSWORD" "$LOGIN_HASHALGORITHM" "$LOGIN_ROUNDS" "$LOGIN_STATICSALT" "$PERSISTENCE_HASHALGORITHM" "$PERSISTENCE_ROUNDS" "$PERSISTENCE_SALT_LENGTH")
        NEWLINE=$(echo "$PASSWORDLINE" | sed "s#<password>.*</password>#<password>$ENCRYPTEDPASSWORD</password>#")
        sed -i "$PASSWORDIDX s#.*#$NEWLINE#" "$XMLFILEPATH"
    fi
done