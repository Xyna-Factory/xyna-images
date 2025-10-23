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
ARG XYNABASE_IMAGE=xynabase:xynamain-imagemain-java11-ubuntu24.04

FROM ${XYNABASE_IMAGE}

ARG OS_IMAGE

USER root

RUN mkdir -p /tmp/os2
COPY os/*.sh /tmp/os2
RUN chmod ug+x /tmp/os2/*.sh && \
    ls -l /tmp/os2 && \
    /tmp/os2/install_os_packages.sh -o ${OS_IMAGE}
USER ${XYNA_USER}:4242
RUN /tmp/os2/install_python_venv.sh -o ${OS_IMAGE} -p ${XYNA_PATH}
USER root
RUN /tmp/os2/postprocess_os_packages.sh -o ${OS_IMAGE}

USER ${XYNA_USER}:4242

ARG HTTP_TRIGGER_INTERFACE_CHOICE="0\n"

COPY --chown=${XYNA_USER}:${XYNA_USER} GitIntegration*.app /tmp/

RUN mkdir ${XYNA_PATH}/tmp \
    && sed -i 's/pid\.folder=.*/pid.folder=\/tmp/' /etc/opt/xyna/environment/black_edition_001.properties

# import guihttp
RUN ${XYNA_PATH}/server/xynafactory.sh start \
  && printf ${HTTP_TRIGGER_INTERFACE_CHOICE} | /tmp/XynaBlackEdition/install_black_edition.sh -x GuiHttp,GitIntegration \
  && /k8s/xyna/startapplication.sh GuiHttp \
  && ${XYNA_PATH}/server/xynafactory.sh set xmcp.guihttp.sts false \
  && ${XYNA_PATH}/server/xynafactory.sh set xmcp.guihttp.csrf false \
  && ${XYNA_PATH}/server/xynafactory.sh stop


# prepare revisions, server and xmomrepository folder - mount persistent volume on ${XYNA_PATH}
RUN cp -r ${XYNA_PATH} ${XYNA_PATH}/../xyna_image

#RUN cat ${XYNA_PATH}/server/server.policy && cat /etc/opt/xyna/environment/black_edition_001.properties

USER 4242:4242
ENV HOSTNAME=xynaContainer
CMD ["/k8s/xyna/factory.sh"]
