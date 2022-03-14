#!/bin/bash

set -e
set -x

BASE=`pwd`
DEST=$BASE/out
SRC=$DEST/src

LDFLAGS="-L$DEST/lib"
CPPFLAGS="-I$DEST/include"
CFLAGS="-O3 -march=armv7-a -mtune=cortex-a9"
CXXFLAGS=$CFLAGS
CONFIGURE="./configure --prefix=$DEST --host=arm-linux"
MAKE="make -j`nproc`"

mkdir -p $SRC

######## ####################################################################
# ZLIB # ####################################################################
######## ####################################################################

mkdir -p $SRC/zlib && cd $SRC/zlib

if [ ! -f .built ]; then

	wget https://www.zlib.net/zlib-1.2.12.tar.gz
	tar zxvf zlib-1.2.12.tar.gz
	cd zlib-1.2.12

	LDFLAGS=$LDFLAGS \
	CPPFLAGS=$CPPFLAGS \
	CFLAGS=$CFLAGS \
	CXXFLAGS=$CXXFLAGS \
	CROSS_PREFIX=arm-linux- \
	./configure \
	--prefix=$DEST \
	--static

	$MAKE
	make install

	touch $SRC/zlib/.built
fi

########### #################################################################
# OPENSSL # #################################################################
########### #################################################################

mkdir -p $SRC/openssl && cd $SRC/openssl

if [ ! -f .built ]; then

	wget https://www.openssl.org/source/openssl-1.1.1o.tar.gz
	tar zxvf openssl-1.1.1o.tar.gz
	cd openssl-1.1.1o

	./Configure no-shared linux-armv4 -march=armv7-a -mtune=cortex-a9 \
	--prefix=$DEST no-zlib \

	make CC=arm-linux-gcc
	make CC=arm-linux-gcc install INSTALLTOP=$DEST OPENSSLDIR=$DEST/ssl

	touch $SRC/openssl/.built
fi

####### #####################################################################
# TBB # #####################################################################
####### #####################################################################

mkdir -p $SRC/tbb && cd $SRC/tbb

if [ ! -f .built ]; then

        git clone https://github.com/oneapi-src/oneTBB.git
        cd oneTBB
	mkdir -p build && cd build

	cmake \
	-Wno-dev \
	-DCMAKE_SYSTEM_NAME="Linux" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=$DEST \
	-DCMAKE_C_COMPILER=`which arm-linux-gcc` \
	-DCMAKE_CXX_COMPILER=`which arm-linux-g++` \
	-DCMAKE_C_FLAGS="-std=c99" \
	-DCMAKE_CXX_FLAGS="-D__TBB_DYNAMIC_LOAD_ENABLED=0" \
	-DCMAKE_EXE_LINKER_FLAGS="-latomic" \
	-DBUILD_SHARED_LIBS=OFF \
	-DTBB_TEST=OFF \
	-DTBB_STRICT=OFF \
	..

	$MAKE
	make install

	touch $SRC/tbb/.built
fi

######## ####################################################################
# MOLD # ####################################################################
######## ####################################################################

mkdir -p $SRC/mold && cd $SRC/mold

	git clone https://github.com/rui314/mold.git
	cd mold

	CPPFLAGS=$CPPFLAGS \
	CFLAGS="$CPPFLAGS $CFLAGS" \
	CXXFLAGS="$CPPFLAGS $CXXFLAGS" \
	LDFLAGS="-s -static $LDFLAGS" \
	SYSTEM_TBB=1 \
	USE_MIMALLOC=1 \
	$MAKE \
	mold \
	CC=arm-linux-gcc \
	CXX=arm-linux-g++ \
	CPPFLAGS=$CPPFLAGS \
	CFLAGS="$CPPFLAGS $CFLAGS" \
	CXXFLAGS="$CPPFLAGS $CXXFLAGS" \
	LDFLAGS="-s -static $LDFLAGS" \
	SYSTEM_TBB=1 \
	USE_MIMALLOC=1

	cp $DEST/src/mold/mold/mold $BASE
