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
ARG APACHE2_IMAGE=ubuntu/apache2:latest
FROM ${APACHE2_IMAGE}
ENV APACHE_LOG_DIR=/var/log/apache2
ENV MODELLER_PORT=8000
ENV XYNA_HOSTNAME="xyna"

SHELL ["/bin/bash", "-c"]

COPY modeller.war /tmp
COPY apache2/ports.conf /etc/apache2
COPY apache2/000-default.conf /etc/apache2/sites-available

RUN apt -y update \
    && apt-get -y install less zip unzip

RUN a2enmod proxy \
    && a2enmod proxy_http \
    && a2enmod rewrite

RUN unzip /tmp/modeller.war -d /var/www/html/modeller
