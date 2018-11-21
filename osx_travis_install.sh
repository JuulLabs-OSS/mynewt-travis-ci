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

# Install newt.
$HOME/ci/newt_install.sh

if [ "${TEST}" == "TEST_ALL" ]; then
    # conflicts with gcc5
    brew cask uninstall oclint

    PKGS=(gcc5)
else
    brew untap caskroom/cask
    brew tap homebrew/cask

    PKGS=()

    # FIXME: casks don't work with `fetch --retry`
    brew cask install gcc-arm-embedded
fi

for pkg in ${PKGS[@]}; do
    brew fetch --retry $pkg
    brew install $pkg
done

if [[ $TRAVIS_REPO_SLUG =~ mynewt-nimble && $TEST == "BUILD_PORTS" ]]; then
    # RIOT-OS requires update to Python3
    # To fetch Python3, database must be up to date
    brew update && brew upgrade python
fi
