#!/usr/bin/python
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
