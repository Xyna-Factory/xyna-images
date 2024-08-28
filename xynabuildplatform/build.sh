#!/bin/bash

. build.conf
docker build --no-cache --build-arg OS_IMAGE=${OS_IMAGE} --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg NODE_MAJOR_VERSION=${NODE_MAJOR_VERSION} -f ${DOCKER_FILE} -t ${XYNA_BUILD_PLATFORM_IMAGE} .

