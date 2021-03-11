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

echo "Doing Linux install"

if [ "${TRAVIS_REPO_SLUG}" == "*mynewt-newt" ]; then
    $HOME/ci/newt_build.sh
else
    $HOME/ci/newt_install.sh
fi

# Do not install ARM toolchain when running "newt test"
if [ "${TEST}" == "TEST_ALL" ] || [ "${TEST}" == "TEST_NEWT" ]; then
  # FIXME: should use update-alternatives here maybe?
    ln -s /usr/bin/gcc-8 ~/bin/gcc
    ln -s /usr/bin/g++-8 ~/bin/g++
fi

if [ "${TEST}" != "TEST_ALL" ]; then
    source $HOME/ci/linux_toolchain_install.sh
fi
