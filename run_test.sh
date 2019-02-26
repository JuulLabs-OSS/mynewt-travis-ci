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

rc=0
case $TEST in
  "TEST_ALL")
     $HOME/ci/test_all.sh
     rc=$?
     ;;
  "BUILD_TARGETS")
     $HOME/ci/test_build_targets.sh
     rc=$?
     ;;
  "BUILD_BLINKY")
     $HOME/ci/test_build_blinky.sh
     rc=$?
     ;;
  "BUILD_PORTS")
     $HOME/ci/build_ports.sh
     rc=$?
     ;;
  *) exit 1
     ;;
esac

exit $rc
