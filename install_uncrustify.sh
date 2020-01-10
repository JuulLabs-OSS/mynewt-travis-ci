#!/bin/bash -x

set -e

REL="0.70.1"
FILE="uncrustify-${REL}"
DIR="uncrustify-${FILE}"
TGZ="${FILE}.tar.gz"

wget -c "https://github.com/uncrustify/uncrustify/archive/${TGZ}"

tar xzf "${TGZ}"

pushd ${DIR}

mkdir build && pushd build
cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local ../
make -j4
make install
popd

popd
