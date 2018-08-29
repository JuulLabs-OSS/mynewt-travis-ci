#!/bin/sh -x

echo "Doing Linux install"

OLD_DIR=$PWD

export GOPATH=$HOME/gopath

mkdir -p $HOME/bin $GOPATH || true

go version

go get mynewt.apache.org/newt/newt

rm -rf $GOPATH/bin $GOPATH/pkg

cd $GOPATH/src/mynewt.apache.org/newt/

git checkout mynewt_1_4_1_tag

go install mynewt.apache.org/newt/newt

cp $GOPATH/bin/newt $HOME/bin

cd $OLD_DIR

. ci/linux_toolchain_install.sh
