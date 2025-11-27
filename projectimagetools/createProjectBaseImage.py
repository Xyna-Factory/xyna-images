#!/usr/bin/python

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

import subprocess
import sys
import os
import configparser
import argparse

SCRIPT_VERSION='0.0.1'
TMP_CONTAINER_NAME='tmp.xyna.container.0'
PROP_NAME_BASE_IMAGE="BASE_IMAGE"
PROP_NAME_TARGET_IMAGE="TARGET_BASE_IMAGE"
PROP_VALUE_TARGET_IMAGE="my.project.image.1"
SECTION_NAME_HEADER="header"
SECTION_NAME_APPS="applications"
SECTION_NAME_APP_LIST="applications.list"

APP_LINE=r'    printf "0\n" | /tmp/XynaBlackEdition/install_black_edition.sh -x '

PROP_FILE_HEADER=f"""# Created by {os.path.basename(sys.argv[0])} version {SCRIPT_VERSION}
"""


PROP_FILE_APP_BLOCK_START="""# Xyna Applications - Select which Xyna Application should be included.
# Including an application automatically installs all dependent applications."""


CMDS_APPS_TEMPL=r"""
RUN ${XYNA_PATH}/server/xynafactory.sh start && \
###_APP_CMD_LIST_###
    ${XYNA_PATH}/server/xynafactory.sh stop
"""


DOCKER_TEMPLATE=r"""
ARG XYNABASE_IMAGE=###_BASE_IMAGE_###

FROM ${XYNABASE_IMAGE} AS xyna-install-stage-1

USER 4242:4242
RUN /tmp/configlog.sh log_nonblock

###_ALL_COMMANDS_###

USER root
RUN find ${XYNA_PATH}/server/storage/ -iname '*.journal' \
    && find ${XYNA_PATH}/server/storage/ -iname '*.journal' -print0 | xargs -0 rm

#####################

FROM ${XYNABASE_IMAGE} AS ###_TARGET_IMAGE_###

USER root

COPY --from=xyna-install-stage-1 --chown=${XYNA_USER}:4242 /opt/xyna /opt/xyna
COPY --from=xyna-install-stage-1 /etc/opt/xyna/var/ /etc/opt/xyna/var/
COPY --from=xyna-install-stage-1 --chown=${XYNA_USER}:4242 /etc/opt/xyna/environment /etc/opt/xyna/environment

RUN rm -rf /tmp/*

USER 4242:4242
ENV HOSTNAME=xynaContainer
CMD ["/k8s/xyna/factory.sh"]
"""


class Property:
  def __init__(self, key: str, value: str):
    self.valid = False
    self.key = ""
    self.value = ""
    if key is None:
      return
    key = key.strip()
    if len(key) < 1:
      return
    if value is None:
      return
    value = value.strip()
    if len(value) < 1:
      return
    self.key = key
    self.value = value
    self.valid = True
### end of class declaration


class XynaApp:
  def __init__(self, path: str = None, property: Property = None):
    self.valid = False
    self.name = ""
    self.path = ""
    self.install_flag = False
    if path is not None:
      self.init_by_path(path)
    elif property is not None and property.valid:
      self.init_by_property(property)

  def init_by_path(self, path_in: str):
    path = path_in.strip()
    if len(path) < 1:
      return
    if not path.endswith(".app"):
      return
    parts = path.split("/")
    filename = parts[-1]
    parts = filename.split(".")
    name = parts[0].strip()
    if len(name) < 1:
      return
    self.name = name
    self.path = filename
    self.valid = True

  def init_by_property(self, prop: Property):
    if not prop.key.lower().startswith("app_"):
      return
    if prop.value is None:
      return
    value = prop.value.strip()
    path = ""
    index = value.find("#")
    if index > 0 and index < len(value) - 1:
      path = value[index + 1:].strip()
      value = value[:index].strip()
    part0 = prop.key
    if not part0.lower().startswith("app_"):
      return
    name = part0[4:].strip()
    if len(name) < 1:
      return
    if value is None:
      return
    if len(value) < 1:
      return
    if value.lower() == "true":
      self.install_flag = True
    self.path = path
    self.name = name
    self.valid = True

  def to_dict_value(self) -> str:
    return str(self.install_flag) + "    #" + self.path

  def to_dict_key(self) -> str:
    return "APP_" + self.name

  def __str__(self) -> str:
    return "valid=" + str(self.valid) + ", name=" + self.name + ", path=" + self.path + ", install_flag=" + str(self.install_flag)
### end of class declaration


class XynaAppList:
  def __init__(self, paths: str = None, config: configparser.ConfigParser = None):
    self.applist = []
    if paths is not None:
      self.init_by_paths(paths)
    elif config is not None:
      self.init_by_config(config)
    if len(self.applist) > 0:
      self.applist = sorted(self.applist, key=lambda elem: elem.name)

  def init_by_paths(self, paths: str):
    linelist = paths.splitlines()
    for line in linelist:
      app = XynaApp(path = line)
      if app.valid:
        self.applist.append(app)

  def init_by_config(self, config: configparser.ConfigParser):
    dict = config[SECTION_NAME_APP_LIST]
    for key in dict.keys():
      prop = Property(key=key, value=dict[key])
      app = XynaApp(property = prop)
      if app.valid:
        self.applist.append(app)

  def filter_apps(self, filter_app_names: list):
    ret = []
    for app in self.applist:
      if app.name in filter_app_names:
        continue
      ret.append(app)
    self.applist = ret

  def to_dict(self) -> dict:
    ret = {}
    for app in self.applist:
      ret[app.to_dict_key()] = app.to_dict_value()
    return ret

  def __str__(self) -> str:
    ret = ""
    for app in self.applist:
      ret += str(app) + "\n"
    return ret
### end of class declaration


class DockerContainer:
  def __init__(self, image_name: str):
    self.image_name = image_name
    self.container_name = TMP_CONTAINER_NAME

  def does_container_exist(self) -> bool:
    result = subprocess.run(["docker", "container", "inspect", self.container_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return result.returncode == 0


  def start_xyna_base_container(self):
    if self.does_container_exist():
      self.drop_xyna_base_container()
    result = subprocess.run(["docker", "run", "-d", "--name", self.container_name, self.image_name])
    result.check_returncode()

  def drop_xyna_base_container(self):
    result = subprocess.run(["docker", "stop", self.container_name])
    result = subprocess.run(["docker", "rm", self.container_name])
    result.check_returncode()

  def get_app_file_list_string(self) -> str:
    docker_cmd=['docker', 'exec', '-t', self.container_name, 'bash', '-c', "find /tmp/XynaBlackEdition/components -iname \\*.app "]
    app_paths=subprocess.check_output(docker_cmd, shell=True, text=True)
    return app_paths

  def get_installed_app_names(self) -> str:
    docker_cmd=['docker', 'exec', '-t', self.container_name, 'bash', '-c', """awk -F= '($1=="installation.folder") { print $2 }'  /etc/opt/xyna/environment/black_edition_001.properties"""]
    xyna_path = subprocess.check_output(docker_cmd, shell=True, text=True)
    xyna_path = xyna_path.strip()
    docker_cmd=['docker', 'exec', '-t', self.container_name, 'bash', '-c', "cd " + xyna_path + "/server; ./xynafactory.sh status; while [[ $? -ne 0 ]]; do sleep 1s; ./xynafactory.sh status; done"]
    subprocess.run(docker_cmd, shell=True, text=True, check=False)
    docker_cmd=['docker', 'exec', '-t', self.container_name, 'bash', '-c', xyna_path + "/server/xynafactory.sh listapplications | awk '(NR>1) { print $1 }'"]
    app_names_str = subprocess.check_output(docker_cmd, shell=True, text=True)
    app_names_str = app_names_str.replace("'", "")
    app_names = app_names_str.splitlines()
    return app_names
### end of class declaration


# !!!
# To add a new section of properties to the generated property-file,
# and correspondinly new command blocks to the generated Dockerfile:
# Create a new child class of this class (similar to the AppSection-class below),
# and add an instance of that new class in the Builder.init_sections()-method below
# !!!
class Section:
  def add_to_properties(self, config: configparser.ConfigParser):
    pass
  def build_dockerfile_commands(self, config: configparser.ConfigParser) -> str:
    pass
### end of class declaration


class AppSection(Section):
  def __init__(self, container: DockerContainer = None):
    self.container = container

  def add_to_properties(self, config: configparser.ConfigParser):
    if self.container is None:
      raise Exception("Docker container not found")
    config[SECTION_NAME_APPS] = {}
    config.set(SECTION_NAME_APPS, PROP_FILE_APP_BLOCK_START)
    pathstr = self.container.get_app_file_list_string()
    apps = self.build_app_dict_from_paths(pathstr)
    config[SECTION_NAME_APP_LIST] = apps

  def build_dockerfile_commands(self, config: configparser.ConfigParser) -> str:
    applist = XynaAppList(config = config)
    apps = self.build_apps_to_install_string(applist)
    return CMDS_APPS_TEMPL.replace("###_APP_CMD_LIST_###", apps)

  def build_app_dict_from_paths(self, app_paths: str) -> dict:
    applist = XynaAppList(paths = app_paths)
    filter_app_names = self.container.get_installed_app_names()
    applist.filter_apps(filter_app_names)
    return applist.to_dict()

  def build_apps_to_install_string(self, applist: XynaAppList) -> str:
    ret = ""
    isfirst = True
    for app in applist.applist:
      if not app.install_flag:
        continue
      if isfirst:
        isfirst = False
      else:
        ret += " && \\  \n"
      ret += APP_LINE + app.name
    if isfirst:
      ret += "    echo 'no apps to install'"
    ret += " && \\"
    return ret
### end of class declaration


class Builder:
  def __init__(self, container: DockerContainer = None):
    self.container = container
    self.sections = self.init_sections()

  def init_sections(self) -> list[Section]:
    ret = []
    ret.append(AppSection(self.container))
    # !!!
    # append new sections here
    # !!!
    return ret
### end of class declaration


class PropertyFileBuilder(Builder):
  def __init__(self, image_name: str):
    super().__init__(DockerContainer(image_name))
    self.image_name = image_name

  def execute(self, out_file: str):
    print("Loading xyna base docker image to determine applications list...", flush=True)
    self.container.start_xyna_base_container()
    try:
      content = self.gen_prop_content()
    except:
      print("Unexpected error:", sys.exc_info()[0])
      self.container.drop_xyna_base_container()
      raise
    self.container.drop_xyna_base_container()
    write_config_file(out_file, content)

  def gen_prop_content(self) -> configparser.ConfigParser:
    config = configparser.ConfigParser(allow_no_value=True)
    config.optionxform = lambda option: option
    firstline = PROP_FILE_HEADER.replace("###_BASE_IMAGE_###", self.image_name)
    config[SECTION_NAME_HEADER] = {}
    config.set(SECTION_NAME_HEADER, firstline)
    config.set(SECTION_NAME_HEADER, PROP_NAME_BASE_IMAGE, self.image_name)
    config.set(SECTION_NAME_HEADER, PROP_NAME_TARGET_IMAGE, PROP_VALUE_TARGET_IMAGE)
    for section in self.sections:
      section.add_to_properties(config)
    return config
### end of class declaration


class DockerfileBuilder(Builder):
  def __init__(self):
    super().__init__()

  def execute(self, prop_file: str, docker_file: str):
    content = self.gen_docker_file_content(prop_file)
    write_file(docker_file, content)

  def gen_docker_file_content(self, prop_file: str) -> str:
    config = configparser.ConfigParser(allow_no_value=True, comment_prefixes=(';'))
    config.optionxform = lambda option: option
    config.read(prop_file)
    header = config[SECTION_NAME_HEADER]
    base_image = header[PROP_NAME_BASE_IMAGE]
    target_image = header[PROP_NAME_TARGET_IMAGE]
    commands = self.gen_commands_string(config)
    ret = DOCKER_TEMPLATE
    ret = ret.replace("###_BASE_IMAGE_###", base_image)
    ret = ret.replace("###_TARGET_IMAGE_###", target_image)
    ret = ret.replace("###_ALL_COMMANDS_###", commands)
    return ret

  def gen_commands_string(self, config: configparser.ConfigParser) -> str:
    commands = ""
    for section in self.sections:
      cmd = section.build_dockerfile_commands(config)
      commands += cmd
    return commands
### end of class declaration


def read_file(name: str) -> str:
  with open(name) as f:
    return f.read()


def write_file(name: str, content: str):
  with open(name, "w") as f:
    f.write(content)


def write_config_file(name: str, config: configparser.ConfigParser):
  with open(name, "w") as f:
    config.write(f)


def main():
  parser = argparse.ArgumentParser()
  subparsers = parser.add_subparsers(dest='commands')
  parser_prop = subparsers.add_parser('createPropertiesFile')
  parser_prop.add_argument('-input', help='Name of existing docker image of xyna factory')
  parser_prop.add_argument('-output', help='Name of property file to create')

  parser_dock = subparsers.add_parser('createDockerfile')
  parser_dock.add_argument('-input', help='Name of existing property file')
  parser_dock.add_argument('-output', help='Name of docker file to create')

  args = parser.parse_args()
  if args.commands == "createPropertiesFile":
    builder = PropertyFileBuilder(args.input)
    builder.execute(args.output)
  elif args.commands == "createDockerfile":
    builder = DockerfileBuilder()
    builder.execute(args.input, args.output)


main()
