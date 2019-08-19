#!/bin/bash

set -e

git clone --depth 1 https://github.com/xiph/ogg.git
git clone --depth 1 https://github.com/xiph/flac.git
git clone --depth 1 https://github.com/guidovranken/fuzzing-headers
git clone --depth 1 https://github.com/guidovranken/flac-fuzzers.git

export CC=clang
export CXX=clang++

export CFLAGS="-fsanitize=address -fsanitize=undefined -g -fsanitize=fuzzer-no-link"
export CXXFLAGS="-D_GLIBCXX_DEBUG -fsanitize=address -fsanitize=undefined -g -fsanitize=fuzzer-no-link -DASAN"

# libogg
mkdir libogg-install
cd ogg/
./autogen.sh
./configure --prefix=`realpath ../libogg-install`
make -j$(nproc)
make install
cd ../

# FLAC
cd flac/
./autogen.sh
./configure --with-ogg=`realpath ../libogg-install` --enable-static --disable-oggtest --disable-examples --disable-xmms-plugin
make -j$(nproc)
cd ..

# Fuzzers
cd flac-fuzzers/
$CXX $CXXFLAGS -I ../fuzzing-headers/include -I ../flac/include/ fuzzer_decoder.cpp ../flac/src/libFLAC++/.libs/libFLAC++.a ../flac/src/libFLAC/.libs/libFLAC.a ../libogg-install/lib/libogg.a -fsanitize=fuzzer -o fuzzer_decoder
$CXX $CXXFLAGS -I ../fuzzing-headers/include -I ../flac/include/ fuzzer_encoder.cpp ../flac/src/libFLAC++/.libs/libFLAC++.a ../flac/src/libFLAC/.libs/libFLAC.a ../libogg-install/lib/libogg.a -fsanitize=fuzzer -o fuzzer_encoder
