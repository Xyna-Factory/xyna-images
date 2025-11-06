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
XYNA_BASE_IMAGE="xynafactory/xynabase:latest"
PROP_NAME_BASE_IMAGE="BASE_IMAGE"
PROP_NAME_TARGET_IMAGE="TARGET_BASE_IMAGE"


DOCKER_TEMPLATE=r"""
ARG XYNABASE_IMAGE=###_BASE_IMAGE_###

FROM ${XYNABASE_IMAGE} AS xyna-install-stage-1

USER 4242:4242


RUN ${XYNA_PATH}/server/xynafactory.sh start \
  && printf "0\n" | /tmp/XynaBlackEdition/install_black_edition.sh -x GuiHttp \
  && /tmp/XynaBlackEdition/install_black_edition.sh -x ###_APPS_### \
  && ${XYNA_PATH}/server/xynafactory.sh stop

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


def read_file(name):
  with open(name) as f:
    return f.read()


def write_file(name, content):
  with open(name, "w") as f:
    f.write(content)


def does_container_exist(name):
  result = subprocess.run(["docker", "container", "inspect", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
  return result.returncode == 0


def build_xyna_base_container():
  if does_container_exist(TMP_CONTAINER_NAME):
    result = subprocess.run(["docker", "rm", TMP_CONTAINER_NAME])
    result.check_returncode()
  result = subprocess.run(["docker", "run", "-d", "--name", TMP_CONTAINER_NAME, XYNA_BASE_IMAGE])
  result.check_returncode()


def drop_xyna_base_container():
  result = subprocess.run(["docker", "stop", TMP_CONTAINER_NAME])
  result.check_returncode()
  result = subprocess.run(["docker", "rm", TMP_CONTAINER_NAME])
  result.check_returncode()


def get_app_file_list_string():
  build_xyna_base_container()
  ret = get_app_file_list_impl()
  drop_xyna_base_container()
  return ret


def get_app_file_list_impl():
  #docker_cmd=['docker exec -t pull.1507.xyna.base.4 bash -c "find /tmp/XynaBlackEdition/components -iname \\*.app " '
  docker_cmd=['docker', 'exec', '-t', TMP_CONTAINER_NAME, 'bash', '-c', "find /tmp/XynaBlackEdition/components -iname \\*.app "]

  app_paths=subprocess.check_output(docker_cmd, shell=True, text=True)
  #print(app_files)
  #print(app_files.rstrip())
  return app_paths


def get_app_name_from_file_name(app_path):
  parts = app_path.split("/")
  parts = parts[-1].split(".")
  return parts[0]


def build_app_property_list_string(app_paths):
  ret = ""
  #pathlist = app_paths.split("\n")
  pathlist = app_paths.splitlines()
  applist = []
  for path in pathlist:
    if "." in path:
      name = get_app_name_from_file_name(path)
      #print(name)
      app = [name, path]
      applist.append(app)
  applist = sorted(applist, key=lambda elem: elem[0])
  for app in applist:
    #ret = ret + "APP_" + name + "=FALSE    #" + path + "\n"
    ret = ret + "APP_" + app[0] + "=FALSE    #" + app[1] + "\n"
  return ret


# get prop list:
# line, part before # has =, (and = not first)
# split by =
def parse_properties(prop_file_content):
  ret = []
  #linelist = prop_file_content.split("\n")
  linelist = prop_file_content.splitlines()
  for line in linelist:
    nocomment = line.split("#")[0].strip()
    if not "=" in nocomment:
      continue
    if nocomment.startswith("="):
      continue
    #parts = nocomment.split("=")
    pos = nocomment.find("=")
    part0 = nocomment[:pos]
    part1 = nocomment[pos + 1:]
    prop = [part0.strip(), part1.strip()]
    ret.append(prop)
  ret = sorted(ret, key=lambda elem: elem[0])
  return ret


def build_apps_to_install(proplist):
  ret = ""
  isfirst = True
  for prop in proplist:
    if len(prop) != 2:
      continue
    propname = prop[0]
    if not propname.startswith("APP_"):
      continue
    propval = prop[1].lower()
    if propval != "true":
      continue
    #appname = propname.split("_")[1].strip()
    appname = propname.removeprefix("APP_")
    if isfirst:
      isfirst = False
    else:
      ret += ", "
    ret += appname
  return ret


def build_apps_to_install_old(prop_file_content):
  ret = ""
  linelist = prop_file_content.split("\n")
  isfirst = True
  for line in linelist:
    if not line.startswith("APP_"):
      continue
    nocomment = line.split("#")[0].strip()
    if not "=" in nocomment:
      continue
    parts = nocomment.split("=")
    if parts[1].strip().lower() != "true":
      continue
    appname = parts[0].split("_")[1].strip()
    if isfirst:
      isfirst = False
    else:
      ret += ", "
    ret += appname
  return ret


def gen_prop_file_content(image_name):
  content = "# Created by " + os.path.basename(sys.argv[0])
  content += " version " + SCRIPT_VERSION;
  content += "\n\n"
  content += PROP_NAME_BASE_IMAGE + "=" + image_name + "\n"
  #content += PROP_NAME_TARGET_IMAGE + "=" + image_name + "\n"
  content += PROP_NAME_TARGET_IMAGE + "=my.project.image.1\n"
  content += "\n\n"

  content += "# Xyna Applications - Select which Xyna Application should be included.\n"
  content += "# Including an application automatically installs all dependent applications.\n"
  content += "\n"

  pathstr = get_app_file_list_string()
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
  #print(apps)
  #if True:
  #  return apps
  base_image = extract_prop_val(proplist, PROP_NAME_BASE_IMAGE)
  target_image = extract_prop_val(proplist, PROP_NAME_TARGET_IMAGE)
  ret = DOCKER_TEMPLATE
  ret = ret.replace("###_BASE_IMAGE_###", base_image)
  ret = ret.replace("###_TARGET_IMAGE_###", target_image)
  ret = ret.replace("###_APPS_###", apps)
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
  sys.exit(1)


def usage():
  print("Usage: ")
  print(sys.argv[0], " createPropertiesFile -input <image> -output <file>")
  print(sys.argv[0], " createDockerfile -input <file> -output <file> ")
  sys.exit(1)


def main():
  if len(sys.argv) != 6:
    usage()
  variant = sys.argv[1]
  # read_param("p1")
  if variant == "createPropertiesFile":
    gen_prop_file(read_param("input"), read_param("output"))
  elif variant == "createDockerfile":
    gen_docker_file(read_param("input"), read_param("output"))
  else:
    usage()


main()


# createPropertiesFile -input <image> -output <file>
# createDockerfile -input <file> -output <file>


#val = read_param("p1")
#print(val)

#val = read_param("p0")
#print(val)

#pathstr = get_app_file_list_string()
#print(pathstr)

#propstr = build_app_property_list_string(pathstr)
#print(propstr)

#tmp = build_apps_to_install("APP_aaa = TRUE" + "\n" + "APP_baa = True" + "\n" + "APP_ccc = true" + "\n")
#print(tmp)

#print(does_container_exist("tmp_build_1507_b1"))
#print(does_container_exist("tmp_build_1507_x1"))

#write_file("tmp.txt", "my-text-1")


#  if len(sys.argv) != 2:
#    print("Usage: ", sys.argv[0], " <path to application.xml> ")
#    return

#print(os.path.basename(sys.argv[0]))

#print(DOCKER_TEMPLATE)



