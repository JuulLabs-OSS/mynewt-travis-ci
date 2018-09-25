#!/bin/bash -x

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

MASTER_ZIP="master.zip"
BLINKY_URL="https://github.com/apache/mynewt-blinky/archive"

wget -q -c "${BLINKY_URL}/${MASTER_ZIP}" -O "$HOME/${MASTER_ZIP}"
[[ $? -ne 0 ]] && exit 1

unzip -q "$HOME/${MASTER_ZIP}" -d "$HOME"
[[ $? -ne 0 ]] && exit 1

ln -s "$HOME/mynewt-blinky-master/apps/blinky" apps/blinky

EXIT_CODE=0
BSPS="$(ls ${TRAVIS_BUILD_DIR}/hw/bsp)"

for bsp in ${BSPS}; do
    # NOTE: do not remove the spaces around IGNORED_BSPS; it's required to
    #       match against the first and last entries
    if [[ " ${IGNORED_BSPS} " =~ [[:blank:]]${bsp}[[:blank:]] ]]; then
        echo "Skipping bsp=$bsp"
        continue
    fi

    echo "Testing bsp=$bsp"

    target="test-blinky-$bsp"
    newt target delete -s -f $target &> /dev/null
    newt target create -s $target
    newt target set -s $target bsp="@apache-mynewt-core/hw/bsp/$bsp"
    newt target set -s $target app="apps/blinky"
    newt build -q $target

    rc=$?
    [[ $rc -ne 0 ]] && EXIT_CODE=$rc

    newt target delete -s -f $target
done

exit $EXIT_CODE
