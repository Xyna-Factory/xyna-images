# syntax=docker/dockerfile:1
ARG OS_IMAGE 
FROM ${OS_IMAGE} as xyna-install
ARG JAVA_VERSION

ARG PREREQ_INSTALL_PARAMS
ARG XYNA_USER
ARG XYNA_PATH

ENV XYNA_USER=${XYNA_USER:-xyna}
ENV XYNA_PATH=${XYNA_PATH:-/opt/xyna/xyna_001}
ENV PREREQ_INSTALL_PARAMSANCE_NO=1
ENV JAVA_HOME=/usr/lib/jvm/zulu${JAVA_VERSION}

RUN yum install -y https://cdn.azul.com/zulu/bin/zulu-repo-1.0.0-1.noarch.rpm \
    && yum -y update && yum -y upgrade \
    && yum install -y zip unzip patch wget openssl nc which xinetd net-tools passwd rsyslog bind-utils vim less telnet \
    && yum install -y zulu${JAVA_VERSION}-jdk-headless \
    && yum clean all \
    && groupadd -g 4242 $XYNA_USER \ 
    && useradd -m -u 4242 -g 4242 -s /bin/bash $XYNA_USER

COPY --chown=${XYNA_USER}:${XYNA_USER} XynaFactory_v*.zip /tmp/

ENV HOSTNAME xynaContainer
ENV PREREQ_INSTALL_PARAMS ${PREREQ_INSTALL_PARAMS:-"\n\n\n\n\n\n\n\n\nfalse\n\nchangeMe\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nxyna\n\n\n\n\n\n\n\n\nxyna\n\n\n\n\n\n"}

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
    && printf $PREREQ_INSTALL_PARAMS | XBE_Prerequisites/install_prerequisites.sh -x \
    && unzip XynaBlackEdition.zip \
    && rm XynaBlackEdition.zip \
	&& ls \
    && mv XynaFactory_* XynaBlackEdition \
    && chown ${XYNA_USER}:${XYNA_USER} XynaBlackEdition \
    && chown -R ${XYNA_USER}:${XYNA_USER} /etc/opt/xyna/environment/ \
    && chown -R ${XYNA_USER}:${XYNA_USER} /opt/	\
    && chown -R ${XYNA_USER}:${XYNA_USER} XynaBlackEdition \
    && chmod 777 XynaBlackEdition/install_black_edition.sh


# install Blackedition
USER ${XYNA_USER}:4242
ENV HOSTNAME xynaContainer
RUN /tmp/XynaBlackEdition/install_black_edition.sh -v -b -c xynafactory -x GlobalApplicationMgmt \
    && ${XYNA_PATH}/server/xynafactory.sh stop \
    && rm -rf ${XYNA_PATH}/backup \
    && rm -rf ${XYNA_PATH}/server/webservices/XynaTop*


USER root

COPY --chown=${XYNA_USER}:${XYNA_USER} k8s /k8s
RUN chmod -R +x /k8s \
    && chmod 777 /run \
    && chmod 777 /var/log/messages \
    && rm -rf /tmp/XBE_Prerequisites_*.zip \
    && rm -rf /tmp/XynaBlackEdition_v*.zip



###
### create smaller image
###

##azul/zulu-openjdk-alpine:JAVA_VERSION
FROM azul/zulu-openjdk-centos:${JAVA_VERSION} 
ENV XYNA_USER=${XYNA_USER:-xyna}
ENV XYNA_PATH=${XYNA_PATH:-/opt/xyna/xyna_001}
COPY --from=xyna-install --chown=4242:4242 /etc/opt/xyna /etc/opt/xyna
COPY --from=xyna-install --chown=4242:4242 /opt/xyna /opt/xyna
COPY --from=xyna-install --chown=4242:4242 /var/log /var/log
COPY --from=xyna-install --chown=4242:4242 /tmp /tmp
COPY --from=xyna-install --chown=4242:4242 /k8s /k8s


# install additional dependencies (alpine only)
RUN apk add --no-cache bash gawk

#install additional dependencies (centos)
RUN sed 's/en_US.utf8/de_DE.utf8,en_US.utf8/' /etc/yum.conf > /etc/yum2.conf \
    && mv /etc/yum2.conf /etc/yum.conf \
    && yum -y update && yum -y upgrade \
    && yum install -y zip unzip patch nc which perl less rsync \
    && yum reinstall -y glibc-common \
    && yum clean all \
    && groupadd -g 4242 $XYNA_USER \ 
    && useradd -m -u 4242 -g 4242 -s /bin/bash $XYNA_USER



WORKDIR ${XYNA_PATH}/server
COPY --chown=${XYNA_USER}:${XYNA_USER} configlog.sh /tmp/
RUN chmod 777 /tmp/configlog.sh \
    && /tmp/configlog.sh init \
    && /tmp/configlog.sh stdout_nonblock \
    && sed -ri 's# <AppenderRef ref="SYSLOG"/># <AppenderRef ref="STDOUT"/>#' ${XYNA_PATH}/server/log4j2.xml \
    && sed -ri 's#  <Root level="[a-z]*">#  <Root level="warn">#' ${XYNA_PATH}/server/log4j2.xml 
	
	

RUN ${XYNA_PATH}/server/xynafactory.sh start \
    && ./xynafactory.sh version | head -1 | awk '{print $5}' > ${XYNA_PATH}/server/version.txt \
    && ${XYNA_PATH}/server/xynafactory.sh stop

USER 4242:4242
ENV HOSTNAME xynaContainer
CMD /k8s/xyna/factory.sh
