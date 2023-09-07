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

#!/bin/bash

if [ $# -eq 0 ] 
  then
  echo "$0 argument required"
  exit 1
fi

XYNA="$(grep "installation.folder" /etc/opt/xyna/environment/black_edition_001.properties|cut -d'=' -f2)/server"

case $1 in
  "init")
    cp "$XYNA/func_lib/processing/processing_lib.sh" "$XYNA/func_lib/processing/processing_lib.sh_log_block"
    cp "$XYNA/func_lib/processing/processing_lib.sh" "$XYNA/func_lib/processing/processing_lib.sh_stdout_block"
    cp "$XYNA/func_lib/processing/processing_lib.sh" "$XYNA/func_lib/processing/processing_lib.sh_log_nonblock"
    cp "$XYNA/func_lib/processing/processing_lib.sh" "$XYNA/func_lib/processing/processing_lib.sh_stdout_nonblock"


	# log block
    sed -ri 's#^\s*nohup .*$#${FACTORY_CLI_CMD} "$@" TEST2>\&1 | ${VOLATILE_LOGGER} -p "${XYNA_SYSLOG_FACILITY}.debug"#' "$XYNA/func_lib/processing/processing_lib.sh_log_block"
	sed -ri 's#^\s*f_start_factory_internal .*JAVA_OPTIONS.*$#f_start_factory_internal ${JAVA_OPTIONS} com.gip.xyna.xmcp.xfcli.XynaFactoryCommandLineInterface "$@" 2>\&1#' "$XYNA/func_lib/processing/processing_lib.sh_log_block"


	# stdout block
    sed -ri 's#^\s*nohup .*$#${FACTORY_CLI_CMD} "$@" 2>\&1#' "$XYNA/func_lib/processing/processing_lib.sh_stdout_block"
    sed -ri 's#^\s*f_start_factory_internal .*JAVA_OPTIONS.*$#f_start_factory_internal ${JAVA_OPTIONS} com.gip.xyna.xmcp.xfcli.XynaFactoryCommandLineInterface "$@" 2>\&1#' "$XYNA/func_lib/processing/processing_lib.sh_stdout_block"
	
	
	# log nonblock => default behavior, no change required
	
	# stdout nonblock
    sed -ri 's#^\s*nohup .*$#${FACTORY_CLI_CMD} "$@" 2>\&1 \&#' "$XYNA/func_lib/processing/processing_lib.sh_stdout_nonblock"
    sed -ri 's#^\s*f_start_factory_internal .*JAVA_OPTIONS.*$#f_start_factory_internal ${JAVA_OPTIONS} com.gip.xyna.xmcp.xfcli.XynaFactoryCommandLineInterface "$@" 2>\&1 \&#' "$XYNA/func_lib/processing/processing_lib.sh_stdout_nonblock"
    ;;
  "log_block")
    cp "$XYNA/func_lib/processing/processing_lib.sh_log_block" "$XYNA/func_lib/processing/processing_lib.sh"
	;;
  "stdout_block")
    cp "$XYNA/func_lib/processing/processing_lib.sh_stdout_block" "$XYNA/func_lib/processing/processing_lib.sh"
    ;;
  "log_nonblock")
    cp "$XYNA/func_lib/processing/processing_lib.sh_log_nonblock" "$XYNA/func_lib/processing/processing_lib.sh"
	;;
  "stdout_nonblock")
    cp "$XYNA/func_lib/processing/processing_lib.sh_stdout_nonblock" "$XYNA/func_lib/processing/processing_lib.sh"
	;;
  *)
    exit 1
	;;
esac