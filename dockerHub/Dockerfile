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
ARG XYNABASE_IMAGE
FROM ${XYNABASE_IMAGE}

COPY --chown=${XYNA_USER}:${XYNA_USER} GitIntegration*.app /tmp/


RUN mkdir ${XYNA_PATH}/tmp \
    && sed -i 's/pid\.folder=.*/pid.folder=\/tmp/' /etc/opt/xyna/environment/black_edition_001.properties

# import guihttp
RUN ${XYNA_PATH}/server/xynafactory.sh start \
  && printf '0\n' | /tmp/XynaBlackEdition/install_black_edition.sh -x GuiHttp \
  && /k8s/xyna/startapplication.sh GuiHttp \
  && ${XYNA_PATH}/server/xynafactory.sh importapplication /tmp/GitIntegration* \
  && ${XYNA_PATH}/server/xynafactory.sh stop

# prepare revisions, server and xmomrepository folder - mount persistent volume on ${XYNA_PATH}
RUN cp -r ${XYNA_PATH} ${XYNA_PATH}/../xyna_image


#Prepare Database Connector and Conector Pool
RUN  cd /tmp/XynaFactoryBundle/ \
  && ./prepare_db_connector_jars.sh 

COPY --chown=${XYNA_USER}:${XYNA_USER} init.sh /tmp/

RUN chmod +x /tmp/init.sh

USER 4242:4242
ENV HOSTNAME=xynaContainer

CMD /tmp/init.sh
