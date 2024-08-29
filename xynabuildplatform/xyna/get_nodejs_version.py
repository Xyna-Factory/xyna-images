#!/usr/bin/python

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

import json
import datetime
import csv
import sys
import operator
import itertools
import os
import subprocess
import argparse
import re
import pathlib

def get_nodejs_version(package_jsonfile):
  f = open(package_jsonfile)
  package_dict = json.load(f)
  f.close()

  node=package_dict['engines']['node']
  result = re.search(r"(\d+\.\d+\.\d+\.\d+)$", node)
  if result is None:
    result = re.search(r"(\d+\.\d+\.\d+)$", node)
    if result is None:
      result = re.search(r"(\d+\.\d+)$", node)
      if result is None:
        raise Exception("Node version not found")

  return result.group(0)

parser = argparse.ArgumentParser()
parser.add_argument('--package_jsonfile',type=str,required=True,help='package_jsonfile')

args=parser.parse_args()
print(get_nodejs_version(args.package_jsonfile))
