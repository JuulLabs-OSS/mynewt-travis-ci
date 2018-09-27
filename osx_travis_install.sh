#!/bin/sh -x
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

brew tap Caskroom/cask
brew tap runtimeco/homebrew-mynewt

brew cask uninstall oclint

MAX_RETRIES=3
PKGS=(Caskroom/cask/gcc-arm-embedded mynewt-newt gcc5)

for pkg in ${PKGS[@]}; do
    retry=0
    while [[ $retry -lt $MAX_RETRIES ]]; do
        brew install $pkg
        [[ $? -eq 0 ]] && break
        # wait a little bit
        sleep 5
        retry=$((retry + 1))
    done
    [[ $retry -eq $MAX_RETRIES ]] && exit 1
done

if [[ $TRAVIS_REPO_SLUG =~ mynewt-nimble ]]; then
    # Upgrade python to v3
    # Required to build RIOT OS
    brew upgrade python
fi
