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

declare -a bsps_arr=(
"ada_feather_nrf52"
"apollo2_evb"
"arduino_primo_nrf52"
"bbc_microbit"
"ble400"
"bmd200"
"bmd300eval"
"calliope_mini"
# "ci40"  # required 'mips-mti-elf-gcc'
"dwm1001-dev"
# "embarc_emsk" # required 'arc-elf32-gcc'
"fanstel-ev-bt840"
"frdm-k64f"
# "hifive1" # required 'riscv64-unknown-elf-gcc'
"native"
# "native-armv7" # build error
# "native-mips" # required 'mips-mti-linux-gnu-gcc'
"nina-b1"
"nrf51-arduino_101"
"nrf51-blenano"
"nrf51dk"
"nrf51dk-16kbram"
"nrf52840pdk"
"nrf52dk"
"nrf52-thingy"
"nucleo-f303k8"
"nucleo-f303re"
"nucleo-f401re"
"nucleo-f413zh"
"nucleo-f746zg"
"nucleo-f767zi"
"nucleo-l476rg"
"olimex-p103"
"olimex_stm32-e407_devboard"
# "pic32mx470_6lp_clicker" # required 'xc32-gcc'
# "pic32mz2048_wi-fire" # required 'xc32-gcc'
"puckjs"
"rb-blend2"
"rb-nano2"
"ruuvi_tag_revb2"
# "sensorhub" # build error
"stm32f3discovery"
"stm32f429discovery"
"stm32f4discovery"
"stm32f7discovery"
"stm32l152discovery"
"telee02"
# "usbmkw41z" # build error
"vbluno51"
"vbluno52"
)

MASTER_ZIP="master.zip"
BLINKY_URL="https://github.com/apache/mynewt-blinky/archive"

wget -q -c "${BLINKY_URL}/${MASTER_ZIP}" -O "$HOME/${MASTER_ZIP}"
[[ $? -ne 0 ]] && exit 1

unzip -q "$HOME/${MASTER_ZIP}" -d "$HOME"
[[ $? -ne 0 ]] && exit 1

ln -s "$HOME/mynewt-blinky-master/apps/blinky" apps/blinky

EXIT_CODE=0

for bsp in "${bsps_arr[@]}"
do
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
