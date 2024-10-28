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

# syntax=docker/dockerfile:1
ARG XYNADEV_IMAGE=xynafactory/xynadev:latest
FROM ${XYNADEV_IMAGE}

#Prepare Database Connector and Conector Pool
RUN  cd /tmp/XynaFactoryBundle/ \
  && ./prepare_db_connector_jars.sh 

# set up persistence layer
ARG MYSQL_DATABASE="placeholder"
ARG MYSQL_USER="placeholder"
ARG MYSQL_PASSWORD="placeholder"
ARG MYSQL_IPADDRESS="placeholder"
ARG CONNECT_STRING="placeholder"
ARG SIZE=10
ARG XYNAFACTORY_SH=/opt/xyna/xyna_001/server/xynafactory.sh
RUN <<-EOF
${XYNAFACTORY_SH} start
${XYNAFACTORY_SH} addconnectionpool -connectstring ${CONNECT_STRING} -name Xyna-Infra-Pool -size ${SIZE} -type Mock_MySQL -user ${MYSQL_USER} -password ${MYSQL_PASSWORD}
${XYNAFACTORY_SH} instantiatepersistencelayer -persistenceLayerName mysql -department xyna -connectionType DEFAULT -persistenceLayerInstanceName Xyna-Infra-Default-Inst -persistenceLayerSpecifics Xyna-Infra-Pool 4000 
${XYNAFACTORY_SH} instantiatepersistencelayer -persistenceLayerName mysql -department xyna -connectionType HISTORY -persistenceLayerInstanceName Xyna-Infra-History-Inst -persistenceLayerSpecifics Xyna-Infra-Pool 4000 
${XYNAFACTORY_SH} registertable -c -persistenceLayerInstanceName Xyna-Infra-History-Inst -tableName orderinfo 
${XYNAFACTORY_SH} registertable -c -persistenceLayerInstanceName Xyna-Infra-History-Inst -tableName orderarchive 
${XYNAFACTORY_SH} set xnwh.persistence.xmom.defaultpersistencelayerid $(${XYNAFACTORY_SH} listpersistencelayerinstances | grep Xyna-Infra-Default-Inst | awk '{ print $2 }') 
${XYNAFACTORY_SH} set xnwh.persistence.xmom.defaulthistorypersistencelayerid $(${XYNAFACTORY_SH} listpersistencelayerinstances | grep Xyna-Infra-History-Inst | awk '{ print $2 }')
${XYNAFACTORY_SH} stop
EOF

COPY --chown=${XYNA_USER}:${XYNA_USER} init.sh /tmp/

RUN chmod +x /tmp/init.sh \
  && rm -rf /opt/xyna/xyna_image   

ARG SYNC_CONTAINER_LIFECYCLE_TO_FACTORY=true
ENV ENV_SYNC_CONTAINER_LIFECYCLE_TO_FACTORY=${SYNC_CONTAINER_LIFECYCLE_TO_FACTORY}
CMD /tmp/init.sh
