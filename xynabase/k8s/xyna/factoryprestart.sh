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
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

$SCRIPT_DIR/copywritables.sh
$SCRIPT_DIR/pooldefinition.sh
$SCRIPT_DIR/xynaproperties.sh
$SCRIPT_DIR/userarchive.sh
$SCRIPT_DIR/queue.sh
$SCRIPT_DIR/factorynode.sh
$SCRIPT_DIR/defineip.sh

# execute pre start script, implemented by projects
$SCRIPT_DIR/prestart.sh