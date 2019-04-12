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

###############################################################################

# Breaks the list of tests to run into multiple sets to be delivered to
# multiple machines.

# Expects a parameter that is the amount of machines that will be running
# the given set of tests, and an environment variable $TARGET_SET that
# should be a machine index from 1 to N amount of machines.

# NOTE: $target_list must store the targets to run in sorted order, because
#       breaking targets into sets require a predictable order so that each
#       machine ends up with a list of tests that is different from all the
#       others that are running the same test.

TOTAL_SETS=$1

case $TEST in
  "TEST_ALL")
    target_list=$(find ${TRAVIS_BUILD_DIR} -iname pkg.yml -exec grep -H "pkg\.type: *unittest" {} \; | cut -d: -f1 | sed s#/pkg.yml##g | sed s#^${TRAVIS_BUILD_DIR}/##g | grep -v "^repos/" | sort)
    ;;
  "BUILD_TARGETS")
    base=$(basename $TRAVIS_REPO_SLUG)
    target_list=$(ls targets/${base}-targets)
    ;;
  "BUILD_BLINKY")
    target_list=$(ls ${TRAVIS_BUILD_DIR}/hw/bsp)
    ;;
  "BUILD_PORTS")
    # don't need to do anything here
    exit 0
    ;;
  *)
    exit 1
    ;;
esac

total_targets=$(echo "$target_list" | wc -l)
set_size=$(echo "${total_targets} / ${TOTAL_SETS} + 1" | bc)
set=0
off=1
sets=()
while [ $set -lt $TOTAL_SETS ]; do
  sets[$set]=$(echo "$target_list" | tail -n +$off | head -n $set_size)
  set=$((set + 1))
  off=$((off + set_size))
done

# Save the targets this machine will run
echo ${sets[$((TARGET_SET - 1))]} > ${TRAVIS_BUILD_DIR}/targets.txt
