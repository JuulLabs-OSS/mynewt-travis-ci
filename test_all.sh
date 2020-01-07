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

EXIT_CODE=0

blacklist=(
    "net/oic/selftest"
    "net/ip/mn_socket/selftest"

    # The below tests are included for backwards compatibility.  They can be
    # removed when the corresponding packages are removed from mynewt-core.
    "net/oic/test"
    "net/ip/mn_socket/test"
)

is_blacklisted() {
    local sought="$1"
    local elem
    shift

    for elem in "${blacklist[@]}"
    do
        if [ "$elem" = "$sought" ]
        then
            return 0
        fi
    done

    return 1
}

TARGETS=$(cat ${TRAVIS_BUILD_DIR}/targets.txt)
for unittest in ${TARGETS}; do
    # TODO: ignore tests that fail on Ubuntu 14.04
    if [ ${TRAVIS_OS_NAME} = "linux" ]; then
        if is_blacklisted "$unittest"
        then
            echo "Ignoring $unittest"
            continue
        fi
    fi

    echo "Testing unittest=$unittest"

    # On Travis settings define a NEWT_TEST_DEBUG environment variable with
    # a space separated list of tests to run with debug enabled, eg:
    #   NEWT_TEST_DEBUG="kernel/os/selftest util/rwlock/selftest"

    if [[ $NEWT_TEST_DEBUG == *"${unittest}"* ]]; then
        newt test -ldebug -v $unittest
    else
        newt test -q $unittest
    fi

    rc=$?
    [[ $rc -ne 0 ]] && EXIT_CODE=$rc
done

exit $EXIT_CODE
