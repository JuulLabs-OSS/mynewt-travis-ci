
TOOLCHAIN_PATH=$HOME/TOOLCHAIN

GCC_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2017q4/gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2
GCC_BASE=gcc-arm-none-eabi-7-2017-q4-major

mkdir -p $TOOLCHAIN_PATH

if [ ! -s ${TOOLCHAIN_PATH}/$GCC_BASE/bin/arm-none-eabi-gcc ]; then
  wget -O ${TOOLCHAIN_PATH}/${GCC_BASE}.tar.bz2 $GCC_URL
  tar xfj ${TOOLCHAIN_PATH}/${GCC_BASE}.tar.bz2 -C $TOOLCHAIN_PATH
  ${TOOLCHAIN_PATH}/$GCC_BASE/bin/arm-none-eabi-gcc --version
fi

for i in ${TOOLCHAIN_PATH}/${GCC_BASE}/bin/arm-none-eabi-* ; do
    rm -f  ~/bin/${i##*/}
    ln -s $i ~/bin/${i##*/}
done

ln -s /usr/bin/gcc-7 ~/bin/gcc
ln -s /usr/bin/g++-7 ~/bin/g++
