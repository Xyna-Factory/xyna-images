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

SCRIPT_VERSION='0.0.1'
TMP_CONTAINER_NAME='tmp.xyna.container.0'
PROP_NAME_BASE_IMAGE="BASE_IMAGE"
PROP_NAME_TARGET_IMAGE="TARGET_BASE_IMAGE"


FILTERED_APPS=["Base", "FileMgmt", "GlobalApplicationMgmt", "Node", "Processing"]

APP_LINE=r'  && printf "0\n" | /tmp/XynaBlackEdition/install_black_edition.sh -x '


PROP_FILE_HEADER=f"""# Created by {os.path.basename(sys.argv[0])} version {SCRIPT_VERSION}

{PROP_NAME_BASE_IMAGE}=###_BASE_IMAGE_###
{PROP_NAME_TARGET_IMAGE}=my.project.image.1
"""


PROP_FILE_APP_BLOCK_START="""
# Xyna Applications - Select which Xyna Application should be included.
# Including an application automatically installs all dependent applications.
"""


DOCKER_TEMPLATE=r"""
ARG XYNABASE_IMAGE=###_BASE_IMAGE_###

FROM ${XYNABASE_IMAGE} AS xyna-install-stage-1

USER 4242:4242

RUN /tmp/configlog.sh log_nonblock \
  && ${XYNA_PATH}/server/xynafactory.sh start \
###_COMMANDS_###  && ${XYNA_PATH}/server/xynafactory.sh stop

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


class XynaAppList:
  def __init__(self, paths: str = None, properties: str = None):
    self.applist = []
    if paths is not None:
      self.init_by_paths(paths)
    elif properties is not None:
      self.init_by_properties(properties)
    if len(self.applist) > 0:
      self.applist = sorted(self.applist, key=lambda elem: elem.name)

  def init_by_paths(self, paths: str):
    linelist = paths.splitlines()
    for line in linelist:
      app = XynaApp(path = line)
      if app.valid:
        self.applist.append(app)

  def init_by_properties(self, props: str):
    linelist = props.splitlines()
    for line in linelist:
      app = XynaApp(prop_line = line)
      if app.valid:
        self.applist.append(app)

  def __str__(self) -> str:
    ret = ""
    for app in self.applist:
      ret += str(app) + "\n"
    return ret
### end of class declaration


class XynaApp:
  def __init__(self, path: str = None, prop_line: str = None):
    self.valid = False
    self.name = ""
    self.path = ""
    self.install_flag = False
    if path is not None:
      self.init_by_path(path)
    elif prop_line is not None:
      self.init_by_prop_line(prop_line)

  def init_by_path(self, path_in: str):
    path = path_in.strip()
    if len(path) < 1:
      return
    if not path.endswith(".app"):
      return
    parts = path.split("/")
    parts = parts[-1].split(".")
    name = parts[0].strip()
    if len(name) < 1:
      return
    self.name = name
    self.path = path
    self.valid = True

  def init_by_prop_line(self, line_in: str):
    line = line_in.strip()
    if not line_in.startswith("APP_"):
      return
    index = line.find("#")
    if index < 0:
      return
    if line.endswith("#"):
      return
    path = line[index + 1:].strip()
    nocomment = line[:index].strip()
    if not "=" in nocomment:
      return
    if nocomment.startswith("="):
      return
    if nocomment.endswith("="):
      return
    index = nocomment.find("=")
    part0 = nocomment[:index].strip()
    if not part0.startswith("APP_"):
      return
    name = part0[4:].strip()
    if len(name) < 1:
      return
    part1 = nocomment[index + 1:].strip()
    if len(part1) < 1:
      return
    if part1.lower() == "true":
      self.install_flag = True
    self.path = path
    self.name = name
    self.valid = True

  def write_prop_file_line(self) -> str:
    if not self.valid:
      return ""
    return "APP_" + self.name + "=FALSE    #" + self.path

  def __str__(self) -> str:
    return "valid=" + str(self.valid) + ", name=" + self.name + ", path=" + self.path + ", install_flag=" + str(self.install_flag)
### end of class declaration


def read_file(name: str) -> str:
  with open(name) as f:
    return f.read()


def write_file(name: str, content: str):
  with open(name, "w") as f:
    f.write(content)


def does_container_exist(name):
  result = subprocess.run(["docker", "container", "inspect", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
  return result.returncode == 0


def start_xyna_base_container(image_name):
  if does_container_exist(TMP_CONTAINER_NAME):
    result = subprocess.run(["docker", "rm", TMP_CONTAINER_NAME])
    result.check_returncode()
  result = subprocess.run(["docker", "run", "-d", "--name", TMP_CONTAINER_NAME, image_name])
  result.check_returncode()


def drop_xyna_base_container():
  result = subprocess.run(["docker", "stop", TMP_CONTAINER_NAME])
  result.check_returncode()
  result = subprocess.run(["docker", "rm", TMP_CONTAINER_NAME])
  result.check_returncode()


def get_app_file_list_string(image_name):
  print("Loading xyna base docker image to determine applications list...", flush=True)
  start_xyna_base_container(image_name)
  ret = get_app_file_list_impl()
  drop_xyna_base_container()
  return ret


def get_app_file_list_impl():
  docker_cmd=['docker', 'exec', '-t', TMP_CONTAINER_NAME, 'bash', '-c', "find /tmp/XynaBlackEdition/components -iname \\*.app "]
  app_paths=subprocess.check_output(docker_cmd, shell=True, text=True)
  return app_paths


def get_app_name_from_file_name(app_path):
  parts = app_path.split("/")
  parts = parts[-1].split(".")
  return parts[0]


def filter_apps(applist):
  ret = []
  for app in applist:
    if app[0] in FILTERED_APPS:
      continue
    ret.append(app)
  return ret


def build_app_property_list_string_old(app_paths):
  ret = ""
  pathlist = app_paths.splitlines()
  applist = []
  for path in pathlist:
    if "." in path:
      name = get_app_name_from_file_name(path)
      app = [name, path]
      applist.append(app)
  applist = filter_apps(applist)
  applist = sorted(applist, key=lambda elem: elem[0])
  for app in applist:
    ret = ret + "APP_" + app[0] + "=FALSE    #" + app[1] + "\n"
  return ret


def build_app_property_list_string(app_paths):
  ret = ""
  pathlist = app_paths.splitlines()
  applist = []
  for path in pathlist:
    if "." in path:
      name = get_app_name_from_file_name(path)
      app = [name, path]
      applist.append(app)
  applist = filter_apps(applist)
  applist = sorted(applist, key=lambda elem: elem[0])
  for app in applist:
    ret = ret + "APP_" + app[0] + "=FALSE    #" + app[1] + "\n"
  return ret


def parse_properties(prop_file_content):
  ret = []
  linelist = prop_file_content.splitlines()
  for line in linelist:
    nocomment = line.split("#")[0].strip()
    if not "=" in nocomment:
      continue
    if nocomment.startswith("="):
      continue
    pos = nocomment.find("=")
    part0 = nocomment[:pos]
    part1 = nocomment[pos + 1:]
    prop = [part0.strip(), part1.strip()]
    ret.append(prop)
  ret = sorted(ret, key=lambda elem: elem[0])
  return ret


def build_apps_to_install(proplist):
  ret = ""
  for prop in proplist:
    if len(prop) != 2:
      continue
    propname = prop[0]
    if not propname.startswith("APP_"):
      continue
    propval = prop[1].lower()
    if propval != "true":
      continue
    appname = propname.removeprefix("APP_")
    ret += APP_LINE + appname + " \\" + "\n"
  return ret


def gen_prop_file_content_old(image_name):
  content = "# Created by " + os.path.basename(sys.argv[0])
  content += " version " + SCRIPT_VERSION;
  content += "\n\n"
  content += PROP_NAME_BASE_IMAGE + "=" + image_name + "\n"
  content += PROP_NAME_TARGET_IMAGE + "=my.project.image.1\n"
  content += "\n\n"
  content += "# Xyna Applications - Select which Xyna Application should be included.\n"
  content += "# Including an application automatically installs all dependent applications.\n"
  content += "\n"
  pathstr = get_app_file_list_string(image_name)
  propstr = build_app_property_list_string(pathstr)
  content += propstr + "\n"
  content += "\n"
  return content


def gen_prop_file_content(image_name):
  content = PROP_FILE_HEADER.replace("###_BASE_IMAGE_###", image_name)
  content += "\n"
  content += PROP_FILE_APP_BLOCK_START
  content += "\n"
  #pathstr = get_app_file_list_string(image_name)
  ### fixme
  #write_file("app_paths.tmp", pathstr)
  pathstr = read_file("app_paths.tmp")
  ###
  propstr = build_app_property_list_string(pathstr)
  content += propstr + "\n"
  content += "\n"
  return content


def gen_prop_file(image_name, out_file):
  content = gen_prop_file_content(image_name)
  write_file(out_file, content)


def extract_prop_val(proplist, propname):
  for prop in proplist:
    if len(prop) != 2:
      continue
    if propname != prop[0]:
      continue
    return prop[1]
  return ""


def gen_docker_file(prop_file, docker_file):
  content = gen_docker_file_content(prop_file)
  write_file(docker_file, content)


def gen_docker_file_content(prop_file):
  prop_content = read_file(prop_file)
  proplist = parse_properties(prop_content)
  apps = build_apps_to_install(proplist)
  base_image = extract_prop_val(proplist, PROP_NAME_BASE_IMAGE)
  target_image = extract_prop_val(proplist, PROP_NAME_TARGET_IMAGE)
  ret = DOCKER_TEMPLATE
  ret = ret.replace("###_BASE_IMAGE_###", base_image)
  ret = ret.replace("###_TARGET_IMAGE_###", target_image)
  ret = ret.replace("###_COMMANDS_###", apps)
  return ret


def read_param(name):
  if not name.startswith("-"):
    name = "-" + name
  arglist = sys.argv[1:]
  matched = False
  for arg in arglist:
    if matched:
      return arg
    if arg == name:
      matched = True
  print("Expected parameter missing: " + name)
  usage()


def usage():
  print("Usage: ")
  print(sys.argv[0], " createPropertiesFile -input <image> -output <file>")
  print(sys.argv[0], " createDockerfile -input <file> -output <file> ")
  sys.exit(1)


def main():
  if len(sys.argv) != 6:
    usage()
  variant = sys.argv[1]
  if variant == "createPropertiesFile":
    gen_prop_file(read_param("input"), read_param("output"))
  elif variant == "createDockerfile":
    gen_docker_file(read_param("input"), read_param("output"))
  else:
    usage()


#main()

#lines = read_file("project.properties.v3")
lines = read_file("app_paths.tmp")
#applist = XynaAppList(properties=lines)
applist = XynaAppList(paths=lines)
print(applist)


def test_apps_1():
  app1 = XynaApp(path="my-app-1.app")
  print(app1)
  app2 = XynaApp(path="/xx/yy/my-app-2.app")
  print(app2)
  line = app2.write_prop_file_line()
  print(line)
  line = line.replace("FALSE", "TRUE")
  line = line.replace("2", "3")
  app3 = XynaApp(prop_line=line)
  print(app3)
  app4 = XynaApp()
  print(app4)


#var1 = "abc"
#print(var1, len(var1))
#var1 += "xy"
#print(var1, len(var1))



#app1 = XynaApp("my-app-1", "p1")
#app2 = XynaApp("my-app-2", "p2")
#print(app1, app2)

#vara = {}
#print(type(vara))
#varb= []
#print(type(varb))

