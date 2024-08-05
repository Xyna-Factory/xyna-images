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
ARG OS_IMAGE
FROM ${OS_IMAGE} AS xyna-install
ARG OS_IMAGE
ARG JAVA_VERSION

ARG PREREQ_INSTALL_PARAMS
ARG XYNA_USER
ARG XYNA_PATH

ENV XYNA_USER=${XYNA_USER:-xyna}
ENV XYNA_PATH=${XYNA_PATH:-/opt/xyna/xyna_001}
ENV PREREQ_INSTALL_PARAMSANCE_NO=1
ENV JAVA_HOME=/usr/lib/jvm/zulu${JAVA_VERSION}
ENV PATH="$JAVA_HOME/bin:$PATH"

COPY os /tmp/os
RUN ls -l /tmp/os
RUN /tmp/os/install_os_packages.sh -o ${OS_IMAGE} -j ${JAVA_VERSION}

RUN groupadd -g 4242 $XYNA_USER
RUN useradd -m -u 4242 -g 4242 -s /bin/bash $XYNA_USER

COPY --chown=${XYNA_USER}:${XYNA_USER} XynaFactory_v*.zip /tmp/

ENV HOSTNAME=xynaContainer
ENV PREREQ_INSTALL_PARAMS=${PREREQ_INSTALL_PARAMS:-"\n\n\n\n\n\n\n\n\nfalse\n\nchangeMe\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nxyna\n\n\n\n\n\n\n\n\nxyna\n\n\n\n\n\n"}

RUN mkdir /var/log/xyna
RUN chown -R ${XYNA_USER}:${XYNA_USER} /var/log/xyna

# install prerequisites
# create files in /etc/opt/xyna/environment: xynaContainer.properties  black_edition_001.properties and xynaContainer.component.properties
RUN cd /tmp \
    #
    && unzip XynaFactory* \
    && rm XynaFactory*.zip \
    && mv XynaFactory* XynaFactoryBundle \
    && cp XynaFactoryBundle/XynaFactory_* XynaBlackEdition.zip \
    && cp XynaFactoryBundle/XBE_Pre* XBE_Prerequisites.zip \
    #
    && unzip XBE_Prerequisites* \
    && rm XBE_Prerequisites.zip \
    && mv XBE_Prerequisites* XBE_Prerequisites \
    && chown -R ${XYNA_USER}:${XYNA_USER} XBE_Prerequisites \
    && chmod 777 XBE_Prerequisites/install_prerequisites.sh \
    && printf $PREREQ_INSTALL_PARAMS | XBE_Prerequisites/install_prerequisites.sh -x

RUN /tmp/os/adjust_blackedition_properties.sh -j ${JAVA_VERSION}

RUN cd /tmp \
    && unzip XynaBlackEdition.zip \
    && rm XynaBlackEdition.zip \
        && ls \
    && mv XynaFactory_* XynaBlackEdition \
    && chown ${XYNA_USER}:${XYNA_USER} XynaBlackEdition \
    && chown -R ${XYNA_USER}:${XYNA_USER} /etc/opt/xyna/environment/ \
    && chown -R ${XYNA_USER}:${XYNA_USER} /opt/ \
    && chown -R ${XYNA_USER}:${XYNA_USER} XynaBlackEdition \
    && chmod 777 XynaBlackEdition/install_black_edition.sh


# install Blackedition
USER ${XYNA_USER}:4242
ENV HOSTNAME=xynaContainer
RUN /tmp/XynaBlackEdition/install_black_edition.sh -v -b -c xynafactory -x GlobalApplicationMgmt \
    && ${XYNA_PATH}/server/xynafactory.sh stop \
    && rm -rf ${XYNA_PATH}/backup \
    && rm -rf ${XYNA_PATH}/server/webservices/XynaTop*


USER root

COPY --chown=${XYNA_USER}:${XYNA_USER} k8s /k8s
RUN chmod -R +x /k8s \
    && rm -rf /tmp/XBE_Prerequisites_*.zip \
    && rm -rf /tmp/XynaBlackEdition_v*.zip \
    && rm -rf /tmp/os


RUN ${XYNA_PATH}/server/xynafactory.sh start \
    && until ${XYNA_PATH}/server/xynafactory.sh -q status; do echo "########## $? waiting..."; sleep 10; done \
    && ${XYNA_PATH}/server/xynafactory.sh version | head -1 | awk '{print $5}' > ${XYNA_PATH}/server/version.txt \
    && ${XYNA_PATH}/server/xynafactory.sh stop \
    && until ${XYNA_PATH}/server/xynafactory.sh status | grep -q "Not running"; do echo "########## $? waiting..."; sleep 10; done

WORKDIR ${XYNA_PATH}/server
COPY --chown=${XYNA_USER}:${XYNA_USER} configlog.sh /tmp/
RUN chmod 777 /tmp/configlog.sh \
&& /tmp/configlog.sh init \
&& /tmp/configlog.sh stdout_nonblock \
&& sed -ri 's# <AppenderRef ref="SYSLOG"/># <AppenderRef ref="STDOUT"/>#' ${XYNA_PATH}/server/log4j2.xml \
&& sed -ri 's#  <Root level="[a-z]*">#  <Root level="warn">#' ${XYNA_PATH}/server/log4j2.xml

USER 4242:4242
ENV HOSTNAME=xynaContainer
CMD ["/k8s/xyna/factory.sh"]
