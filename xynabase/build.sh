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

JAVA_VERSION=""
OS_IMAGE=""
XYNA_IMAGE=""
DOCKER_FILE="Dockerfile"

usage() {
    echo "Usage: $0 -j <JAVA-VERSION> -o <OS-IMAGE> -x <XYNA-IMAGE>"
    exit 1
}

while getopts ":j:o:x:" option; do
    case "${option}" in
        j)
            JAVA_VERSION=${OPTARG}
            ;;
        o)
            OS_IMAGE=${OPTARG}
            ;;
        x)
            XYNA_IMAGE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z ${JAVA_VERSION} ]]; then
    usage
fi
if [[ -z ${OS_IMAGE} ]]; then
    usage
fi
if [[ -z ${XYNA_IMAGE} ]]; then
    usage
fi

ANT_FOLDER=""
BLACK_EDITION_INSTANCES=1
SYSTEM_VENDOR="xyna"
SYSTEM_TYPE="production"
NTP1_IPADDRESS=""
NTP2_IPADDRESS=""
CLUSTER=""
GERONIMO=""
SIPADAPTER=""
TOMCAT="false"
AS_USERID=""
AS_PASSWORD="password"
DEFAULT_MONITORINGLEVEL=""
INSTALLATION_FOLDER=""
JAVA_HOME=""
JEP_MODULE_PATH=""
JVM_MAXHEAP_SIZE=""
JVM_MINHEAP_SIZE=""
JVM_OPTION_ADDITIONAL=""
JVM_OPTION_DEBUG=""
JVM_OPTION_EXECPTION=""
JVM_OPTION_GC=""
JVM_OPTION_LOG4J=""
JVM_OPTION_PROFILING=""
JVM_OPTION_RMI=""
JVM_OPTION_XML_BACKUP=""
JVM_PERMGENSPACE_SIZE=""
OS_LOCALE=""
PID_FOLDER=""
PROJECT_PREFIX_UPPERCASE=""
PYTHON_VENV_PATH=""
SCHEDULER_STOP_TIMEOUT_OFFSET=""
SECURESTORAGE_SEED="ChangedAgain"
SVN_HOOKMANAGER_PORT=""
SVN_SERVER=""
TRIGGER_HTTP_PORT=""
TRIGGER_NSNHIX5600_PORT=""
TRIGGER_SNMP_PORT=""
VELOCITY_PARSER_POOL_SIZE=""
XYNA_GROUP=""
XYNA_INSTANCENAME=""
XYNA_PASSWORD="xyna"
XYNA_RMI_LOCAL_IPADDRESS="127.0.0.1"
XYNA_RMI_LOCAL_PORT=""
XYNA_SYSLOG_FILE=""
XYNA_SYSLOG_FACILITY=""
XYNA_USER=""
PREREQ_INSTALL_PARAMS="${ANT_FOLDER}\n${BLACK_EDITION_INSTANCES}\n${SYSTEM_VENDOR}\n${SYSTEM_TYPE}\n${NTP1_IPADDRESS}\n${NTP2_IPADDRESS}\n${CLUSTER}\n${GERONIMO}\n${SIPADAPTER}\n${TOMCAT}\n${AS_USERID}\n${AS_PASSWORD}\n${DEFAULT_MONITORINGLEVEL}\n${INSTALLATION_FOLDER}\n${JAVA_HOME}\n${JEP_MODULE_PATH}\n${JVM_MAXHEAP_SIZE}\n${JVM_MINHEAP_SIZE}\n${JVM_OPTION_ADDITIONAL}\n${JVM_OPTION_DEBUG}\n${JVM_OPTION_EXECPTION}\n${JVM_OPTION_GC}\n${JVM_OPTION_LOG4J}\n${JVM_OPTION_PROFILING}\n${JVM_OPTION_RMI}\n${JVM_OPTION_XML_BACKUP}\n${JVM_PERMGENSPACE_SIZE}\n${OS_LOCALE}\n${PID_FOLDER}\n${PROJECT_PREFIX_UPPERCASE}\n${PYTHON_VENV_PATH}\n${SCHEDULER_STOP_TIMEOUT_OFFSET}\n${SECURESTORAGE_SEED}\n${SVN_HOOKMANAGER_PORT}\n${SVN_SERVER}\n${TRIGGER_HTTP_PORT}\n${TRIGGER_NSNHIX5600_PORT}\n${TRIGGER_SNMP_PORT}\n${VELOCITY_PARSER_POOL_SIZE}\n${XYNA_GROUP}\n${XYNA_INSTANCENAME}\n${XYNA_PASSWORD}\n${XYNA_RMI_LOCAL_IPADDRESS}\n${XYNA_RMI_LOCAL_PORT}\n${XYNA_SYSLOG_FILE}\n${XYNA_SYSLOG_FACILITY}\n${XYNA_SYSLOG_FACILITY}\n"

docker build --build-arg PREREQ_INSTALL_PARAMS=${PREREQ_INSTALL_PARAMS} --build-arg OS_IMAGE=${OS_IMAGE} --build-arg JAVA_VERSION=${JAVA_VERSION} -f ${DOCKER_FILE} -t ${XYNA_IMAGE} .

