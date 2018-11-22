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

NIMBLE_URL=$(pwd)
NIMBLE_VER="travis-build"
RIOT_PATH="RIOT"

git tag $NIMBLE_VER
[[ $? -ne 0 ]] && exit 1

git clone https://github.com/RIOT-OS/RIOT $RIOT_PATH
[[ $? -ne 0 ]] && exit 1

pushd $RIOT_PATH
pushd pkg/nimble/
sed -i'.bak' 's|PKG_URL.*|PKG_URL = '"$NIMBLE_URL"'|' Makefile
sed -i'.bak' 's|PKG_VERSION.*|PKG_VERSION = '"$NIMBLE_VER"'|' Makefile
popd
pushd examples/nimble_gatt/

make
[[ $? -ne 0 ]] && exit 1

popd
popd
