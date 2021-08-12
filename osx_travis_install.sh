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

echo "Doing OSX install"

# Updating homebrew takes a long time, so avoid doing it
# unless explicitly requested
export HOMEBREW_NO_AUTO_UPDATE=1

if [ "${TRAVIS_REPO_SLUG}" == "*mynewt-newt" ]; then
    $HOME/ci/newt_build.sh
else
    $HOME/ci/newt_install.sh
fi

if [ "${TEST}" != "TEST_ALL" ]; then
    brew untap caskroom/cask

    # Tap full clone to allow checkout of specific sha below
    brew tap --full homebrew/cask

    pushd /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask
    git checkout b3a2e0c930~
    popd

    # FIXME: casks don't work with `fetch --retry`
    brew cask install gcc-arm-embedded
fi

if [[ $TRAVIS_REPO_SLUG =~ mynewt-nimble && $TEST == "BUILD_PORTS" ]]; then
    # RIOT-OS requires update to Python3
    # To fetch Python3, database must be up to date
    brew update && brew upgrade python
fi
