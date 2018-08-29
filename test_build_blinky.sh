#!/bin/bash

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

BSP_PATH="repos/apache-mynewt-core/hw/bsp/"
EXIT_CODE=0

for bsp in "${bsps_arr[@]}"
do
    echo "Testing bsp=$bsp"

    target="test-blinky-$bsp"
    newt target delete -s $target &> /dev/null
    newt target create -s $target
    newt target set -s $target bsp="@apache-mynewt-core/hw/bsp/$bsp"
    newt target set -s $target app="apps/blinky"
    newt build -s $target 2>&1

    if [ $? -ne 0 ]; then
            EXIT_CODE=$?
    fi

    newt target delete -s $target
done

exit $EXIT_CODE
