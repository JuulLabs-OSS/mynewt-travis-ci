
TC_HOME=$HOME/TC

case $ARMGCC_VERSION in
  "6.2.1")
       GCC_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/6-2016q4/gcc-arm-none-eabi-6_2-2016q4-20161216-linux.tar.bz2
       GCC_BASE=gcc-arm-none-eabi-6_2-2016q4
     ;;
  "6.3.1")
       GCC_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/6-2017q2/gcc-arm-none-eabi-6-2017-q2-update-linux.tar.bz2
       GCC_BASE=gcc-arm-none-eabi-6-2017-q2-update
     ;;
  "7.2.1")
       GCC_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2017q4/gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2
       GCC_BASE=gcc-arm-none-eabi-7-2017-q4-major
     ;;
  *)  exit 1
     ;;
esac

mkdir -p $TC_HOME

if [ ! -s ${TC_HOME}/$GCC_BASE/bin/arm-none-eabi-gcc ]; then
  wget -O ${TC_HOME}/${GCC_BASE}.tar.bz2 $GCC_URL
  tar xfj ${TC_HOME}/${GCC_BASE}.tar.bz2 -C $TC_HOME
  ${TC_HOME}/$GCC_BASE/bin/arm-none-eabi-gcc --version
fi

for i in ${TC_HOME}/${GCC_BASE}/bin/arm-none-eabi-* ; do
    rm -f  ~/bin/${i##*/}
    ln -s $i ~/bin/${i##*/}
done

