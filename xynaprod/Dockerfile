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

#should have the form "xynabase:<tag>".
ARG XYNABASE_IMAGE=xynabase:xynamain-imagemain-java11-ubuntu24.04
FROM ${XYNABASE_IMAGE}

# configure pid file location
RUN mkdir ${XYNA_PATH}/tmp \
    && sed -i 's/pid\.folder=.*/pid.folder=\/tmp/' /etc/opt/xyna/environment/black_edition_001.properties \
#   && sed -i 's/pid\.folder=.*/pid.folder=\/opt\/xyna\/xyna_001\/tmp/' /etc/opt/xyna/environment/black_edition_001.properties \
    && rm -rf /k8s/xyna/dev

# configure persistence layers and table configuration
RUN ./xynafactory.sh start \
    && until ./xynafactory.sh -q status; do echo "########## $? waiting..."; sleep 10; done \
    && ./xynafactory.sh instantiatepersistencelayer -persistenceLayerName memory -department xyna -connectionType HISTORY -persistenceLayerInstanceName CacheForHISTORYwriteable -persistenceLayerSpecifics map \
    && ./xynafactory.sh instantiatepersistencelayer -persistenceLayerName xml -department xyna -connectionType HISTORY -persistenceLayerInstanceName HISTORYwriteable -persistenceLayerSpecifics HISTORYwriteable true true CacheForHISTORYwriteable true \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName xynaproperties \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName application \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName applicationentries \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName bootcount \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName configurationmodcount \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName orderstatistics \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName pooldefinition \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName monitoringdispatcher \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName capacitymappings \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName rolearchive \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName HISTORYwriteable -tableName userarchive \
    && ./xynafactory.sh instantiatepersistencelayer -persistenceLayerName memory -department xyna -connectionType DEFAULT -persistenceLayerInstanceName CacheForDEFAULTwriteable -persistenceLayerSpecifics map \
    && ./xynafactory.sh instantiatepersistencelayer -persistenceLayerName xml -department xyna -connectionType DEFAULT -persistenceLayerInstanceName DEFAULTwriteable -persistenceLayerSpecifics DEFAULTwriteable true true CacheForDEFAULTwriteable true \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName DEFAULTwriteable -tableName idgeneration \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName DEFAULTwriteable -tableName version \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName DEFAULTwriteable -tableName triggers \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName DEFAULTwriteable -tableName triggerinstances \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName DEFAULTwriteable -tableName filters \
    && ./xynafactory.sh registertable -c -persistenceLayerInstanceName DEFAULTwriteable -tableName filterinstances \
    && ./xynafactory.sh set xyna.rmi.interlink.port.communication 1098 \
    && ./xynafactory.sh stop \
    && until ./xynafactory.sh status | grep -q "Not running"; do echo "########## $? waiting..."; sleep 10; done \
    && rm ./storage/Configuration/xynaproperties.xml \
    && rm ./storage/defaultHISTORY/application.xml \
    && rm ./storage/defaultHISTORY/applicationentries.xml \
    && rm ./storage/defaultHISTORY/bootcount.xml \
    && rm ./storage/defaultHISTORY/configurationmodcount.xml \
    && rm ./storage/defaultHISTORY/orderstatistics.xml \
    && mv ./storage/defaultHISTORY/pooldefinition.xml ./storage/HISTORYwriteable/pooldefinition.xml \
    && mv ./storage/defaultHISTORY/userarchive.xml ./storage/HISTORYwriteable/userarchive.xml\
    && rm ./storage/defaultHISTORY/monitoringdispatcher.xml \
    && rm ./storage/defaultHISTORY/capacitymappings.xml \
    && rm ./storage/defaultHISTORY/rolearchive.xml \
    && rm ./storage/defaultDEFAULT/idgeneration.xml \
    && rm ./storage/defaultDEFAULT/version.xml \
    && mv ./storage/XynaActivation/* ./storage/HISTORYwriteable/ \
    && mkdir ./storage/HISTORYimage \
    && mkdir ./storage/DEFAULTimage \
    && cp ./storage/HISTORYwriteable/* ./storage/HISTORYimage/ \
    && cp ./storage/DEFAULTwriteable/* ./storage/DEFAULTimage/ \
    && find . -name "*.journal" | xargs rm \
    && touch /etc/opt/xyna/environment/black_edition_001_copy_to_writeable_pl.properties \
    && echo "DEFAULTimage=DEFAULTwriteable" >> /etc/opt/xyna/environment/black_edition_001_copy_to_writeable_pl.properties \
    && echo "HISTORYimage=HISTORYwriteable" >> /etc/opt/xyna/environment/black_edition_001_copy_to_writeable_pl.properties

USER 4242:4242
ENV HOSTNAME=xynaContainer
CMD ["/k8s/xyna/factory.sh"]