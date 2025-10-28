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

# syntax=docker/dockerfile:1
ARG XYNABASE=xynafactory/xynabase:latest
FROM ${XYNABASE}

ARG OS_IMAGE

USER root

RUN mkdir -p /tmp/os2
COPY os/*.sh /tmp/os2
RUN chmod ug+x /tmp/os2/*.sh && \
    chown ${XYNA_USER}:4242 /tmp/os2/install_python_venv.sh && \
    ls -l /tmp/os2 && \
    /tmp/os2/install_os_packages.sh -o ${OS_IMAGE}
USER ${XYNA_USER}:4242
RUN /tmp/os2/install_python_venv.sh -o ${OS_IMAGE} -p ${XYNA_PATH}
USER root
RUN /tmp/os2/postprocess_os_packages.sh -o ${OS_IMAGE}

USER ${XYNA_USER}:4242

# Init script
COPY --chown=${XYNA_USER}:${XYNA_USER} init.sh /tmp/
RUN chmod +x /tmp/init.sh  

# Prepare Database Connector
RUN  cd /tmp/XynaFactoryBundle/ \
  && ./prepare_db_connector_jars.sh 

# Set up persistence layer, install applications
ARG XYNAFACTORY_SH=/opt/xyna/xyna_001/server/xynafactory.sh
ARG XMOMREPOSITORY=/opt/xyna/xyna_001/xmomrepository
ARG INSTALL_BLACKEDITION=/tmp/XynaBlackEdition/install_black_edition.sh
RUN <<-EOF
/tmp/configlog.sh log_nonblock
${XYNAFACTORY_SH} start
printf "0\n" |${INSTALL_BLACKEDITION} -x FileMgmt
printf "0\n" |${INSTALL_BLACKEDITION} -x SNMPStatistics
printf "0\n" |${INSTALL_BLACKEDITION} -x UserSessionMgmt
printf "0\n" |${INSTALL_BLACKEDITION} -x GitIntegration
${INSTALL_BLACKEDITION} -x ActiveMQ,BatchProcessMgmt,CSV,CapacityMgmt,Connection,Crypto,GuiHttp,Http,IOSDevice,IOSXEDevice,IOSXRDevice,Json,JunOSDevice,LDAP,Mail,Net,Node,OAS_Base,OneOSDevice,Queue,RegExp,SNMP,SOAP,SSH,SSHFile,SSHServer,SSHTools,ScriptExecutor,StorableOperations,Telnet,Timeseries,UserRoleManagement,XynaPropertyMgmt,YangAppGenerator,YangBase
${XYNAFACTORY_SH} addconnectionpool -connectstring jdbc:mariadb://placeholder/xyna -name Xyna-Infra-Pool -size 10 -type Mock_MySQL -user placeholder -password placeholder
${XYNAFACTORY_SH} instantiatepersistencelayer -persistenceLayerName mysql -department xyna -connectionType DEFAULT -persistenceLayerInstanceName Xyna-Infra-Default-Inst -persistenceLayerSpecifics Xyna-Infra-Pool 4000 zippedBlobs=true
${XYNAFACTORY_SH} instantiatepersistencelayer -persistenceLayerName mysql -department xyna -connectionType HISTORY -persistenceLayerInstanceName Xyna-Infra-History-Inst -persistenceLayerSpecifics Xyna-Infra-Pool 4000 zippedBlobs=true
${XYNAFACTORY_SH} set xyna.xprc.xprcods.orderarchive.auditxml.binary true
${XYNAFACTORY_SH} registertable -persistenceLayerInstanceName Xyna-Infra-History-Inst -tableName orderinfo
${XYNAFACTORY_SH} registertable -persistenceLayerInstanceName Xyna-Infra-History-Inst -tableName orderarchive
${XYNAFACTORY_SH} registertable -persistenceLayerInstanceName Xyna-Infra-Default-Inst -tableName orderbackup
${XYNAFACTORY_SH} registertable -persistenceLayerInstanceName Xyna-Infra-Default-Inst -tableName codegroup
${XYNAFACTORY_SH} registertable -persistenceLayerInstanceName Xyna-Infra-Default-Inst -tableName codepattern
${XYNAFACTORY_SH} registertable -persistenceLayerInstanceName Xyna-Infra-Default-Inst -tableName idgeneration
${XYNAFACTORY_SH} registertable -persistenceLayerInstanceName Xyna-Infra-Default-Inst -tableName cronlikeorders
${XYNAFACTORY_SH} registertable -persistenceLayerInstanceName Xyna-Infra-History-Inst -tableName cronlikeorders
${XYNAFACTORY_SH} set xnwh.persistence.xmom.defaultpersistencelayerid $(${XYNAFACTORY_SH} listpersistencelayerinstances | grep Xyna-Infra-Default-Inst | awk '{ print $2 }')
${XYNAFACTORY_SH} set xnwh.persistence.xmom.defaulthistorypersistencelayerid $(${XYNAFACTORY_SH} listpersistencelayerinstances | grep Xyna-Infra-History-Inst | awk '{ print $2 }')
${XYNAFACTORY_SH} set xyna.default.monitoringlevel 20
${XYNAFACTORY_SH} set xmcp.guihttp.sts false
${XYNAFACTORY_SH} set xmcp.guihttp.csrf false
${XYNAFACTORY_SH} stop
/tmp/configlog.sh stdout_nonblock
find /opt/xyna/xyna_001/storage -name "*.journal" | xargs --no-run-if-empty rm
/k8s/xyna/xmomrepository_adjust_revision.sh ${XMOMREPOSITORY}
/k8s/xyna/xmomrepository_adjust_revision_history.sh ${XMOMREPOSITORY}
EOF

RUN cat ${XYNA_PATH}/server/server.policy && cat /etc/opt/xyna/environment/black_edition_001.properties

## avoid timestamp collision of log file
RUN sleep 2s

ENV SYNC_CONTAINER_LIFECYCLE_TO_FACTORY=true
CMD /tmp/init.sh
