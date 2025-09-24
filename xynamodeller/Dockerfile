# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copyright 2025 Xyna GmbH, Germany
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
ARG HTTPD_IMAGE=httpd:latest
FROM ${HTTPD_IMAGE}
ENV MODELLER_PORT=8000
ENV XYNA_HOSTNAME="xyna"

SHELL ["/bin/bash", "-c"]

COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf

RUN apt --no-install-recommends -y update \
    && apt-get -y install less zip unzip curl \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=bind,source=modeller.war,target=/tmp/modeller.war \    
    unzip /tmp/modeller.war -d /usr/local/apache2/htdocs/modeller