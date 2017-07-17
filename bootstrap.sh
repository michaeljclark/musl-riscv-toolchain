#!/bin/bash

set -e

ARCH=rv64imafdc
PREFIX=/opt/riscv/toolchain-7.1.0

gmp_version=6.1.0
mpfr_version=3.1.5
mpc_version=1.0.3
isl_version=0.16.1
cloog_version=0.18.4
binutils_version=2.28
gcc_version=7.1.0
musl_version=1.1.17-riscv-a2

SINGLE=$(echo ${ARCH} | sed 's#rv\([1-9]*\).*#riscv\1#')
TRIPLE=${SINGLE}-linux-musl
TEMP=`pwd`/build/temp-install
SYSROOT=${PREFIX}/sysroot

echo ARCH=${ARCH}
echo TRIPLE=${TRIPLE}
echo PREFIX=${PREFIX}

test -d stamps || mkdir stamps
test -d archives || mkdir archives
test -d ${PREFIX} || mkdir -p ${PREFIX}
test -d ${TEMP} || mkdir -p ${TEMP}

export CC=cc

# build gmp
test -f stamps/lib-gmp || (
  set -e
  test -f archives/gmp-${gmp_version}.tar.bz2 || \
      curl -o archives/gmp-${gmp_version}.tar.bz2 \
      ftp://ftp.gmplib.org/pub/gmp-${gmp_version}/gmp-${gmp_version}.tar.bz2
  test -d build/gmp-${gmp_version} || \
      tar -C build -xjf archives/gmp-${gmp_version}.tar.bz2
  cd build/gmp-${gmp_version}
  CFLAGS=-fPIE ./configure --disable-shared --prefix=${TEMP}
  make -j8 && make install
) && touch stamps/lib-gmp

# build mpfr
test -f stamps/lib-mpfr || (
  set -e
  test -f archives/mpfr-${mpfr_version}.tar.bz2 || \
      curl -o archives/mpfr-${mpfr_version}.tar.bz2 \
      http://www.mpfr.org/mpfr-current/mpfr-${mpfr_version}.tar.bz2
  test -d build/mpfr-${mpfr_version} || \
      tar -C build -xjf archives/mpfr-${mpfr_version}.tar.bz2
  cd build/mpfr-${mpfr_version} 
  CFLAGS=-fPIE ./configure \
      --disable-shared \
      --prefix=${TEMP} \
      --with-gmp=${TEMP}
  make -j8 && make install
) && touch stamps/lib-mpfr

# build mpc
test -f stamps/lib-mpc || (
  set -e
  test -f archives/mpc-${mpc_version}.tar.gz || \
      curl -o archives/mpc-${mpc_version}.tar.gz \
      http://www.multiprecision.org/mpc/download/mpc-${mpc_version}.tar.gz
  test -d build/mpc-${mpc_version} || \
      tar -C build -xzf archives/mpc-${mpc_version}.tar.gz
  cd build/mpc-${mpc_version}
  CFLAGS=-fPIE ./configure \
      --disable-shared \
      --prefix=${TEMP} \
      --with-gmp=${TEMP} \
      --with-mpfr=${TEMP}
  make -j8 && make install
) && touch stamps/lib-mpc

# build isl
test -f stamps/lib-isl || (
  set -e
  test -f archives/isl-${isl_version}.tar.bz2 || \
      curl -o archives/isl-${isl_version}.tar.bz2 \
      ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-${isl_version}.tar.bz2
  test -d build/isl-${isl_version} || \
      tar -C build -xjf archives/isl-${isl_version}.tar.bz2
  cd build/isl-${isl_version}
  CFLAGS=-fPIE ./configure \
      --disable-shared \
      --prefix=${TEMP} \
      --with-gmp-prefix=${TEMP}
  make -j8 && make install
) && touch stamps/lib-isl

# build cloog
test -f stamps/lib-cloog || (
  set -e
  test -f archives/cloog-${cloog_version}.tar.gz || \
      curl -o archives/cloog-${cloog_version}.tar.gz \
      https://www.bastoul.net/cloog/pages/download/cloog-${cloog_version}.tar.gz
  test -d build/cloog-${cloog_version} || \
      tar -C build -xzf archives/cloog-${cloog_version}.tar.gz
  cd build/cloog-${cloog_version}
  CFLAGS=-fPIE ./configure \
      --disable-shared \
      --prefix=${TEMP} \
      --with-isl-prefix=${TEMP} \
      --with-gmp-prefix=${TEMP}
  make -j8 && make install
) && touch stamps/lib-cloog

# build binutils
test -f stamps/binutils || (
  set -e
  test -f archives/binutils-${binutils_version}.tar.bz2 || \
      curl -o archives/binutils-${binutils_version}.tar.bz2 \
      http://ftp.gnu.org/gnu/binutils/binutils-${binutils_version}.tar.bz2
  test -d build/binutils-${binutils_version} || \
      tar -C build -xjf archives/binutils-${binutils_version}.tar.bz2
  cd build/binutils-${binutils_version}
  CFLAGS=-fPIE ./configure \
        --prefix=${PREFIX} \
        --target=${TRIPLE} \
	--with-arch=${ARCH} \
        --program-transform-name='s&^&'${TRIPLE}'-&' \
	--with-sysroot=${SYSROOT} \
	--disable-nls \
	--disable-libssp \
	--disable-shared \
	--disable-werror  \
        --disable-isl-version-check \
        --with-gmp=${TEMP} \
        --with-mpfr=${TEMP} \
        --with-mpc=${TEMP} \
        --with-isl=${TEMP} \
        --with-cloog=${TEMP}
  make -j8 && make install
) && touch stamps/binutils

# musl headers
test -f stamps/musl-headers || (
  set -e
  test -f archives/musl-riscv-${musl_version}.tar.gz || \
      curl -o archives/musl-riscv-${musl_version}.tar.gz \
      https://codeload.github.com/rv8-io/musl-riscv/tar.gz/v${musl_version}
  test -d build/musl-riscv-${musl_version} || \
      tar -C build -xzf archives/musl-riscv-${musl_version}.tar.gz
  cd build/musl-riscv-${musl_version}
  echo prefix=/usr > config.mak
  echo exec_prefix=/usr >> config.mak
  echo ARCH=${SINGLE} >> config.mak
  echo CC=${PREFIX}/bin/${TRIPLE}-gcc >> config.mak
  echo AS=${PREFIX}/bin/${TRIPLE}-as >> config.mak
  echo LD=${PREFIX}/bin/${TRIPLE}-ld >> config.mak
  make DESTDIR=${SYSROOT} install-headers
) && touch stamps/musl-headers

# build gcc stage1
test -f stamps/gcc-stage1 || (
  set -e
  test -f archives/gcc-${gcc_version}.tar.bz2 || \
      curl -o archives/gcc-${gcc_version}.tar.bz2 \
      http://ftp.gnu.org/gnu/gcc/gcc-${gcc_version}/gcc-${gcc_version}.tar.bz2
  test -d build/gcc-${gcc_version} || \
      tar -C build -xjf archives/gcc-${gcc_version}.tar.bz2
  cd build/gcc-${gcc_version}
  test -d output || mkdir output
  cd output
  CFLAGS=-fPIE ../configure \
	--prefix=${PREFIX} \
        --target=${TRIPLE} \
	--with-arch=${ARCH} \
	--program-transform-name='s&^&'${TRIPLE}'-&' \
	--with-sysroot=${SYSROOT} \
	--with-gnu-as \
	--with-gnu-ld \
	--enable-languages=c,c++ \
	--enable-target-optspace \
	--enable-cloog-backend=isl \
	--enable-initfini-array \
	--enable-shared \
	--disable-threads \
	--disable-libgcc \
	--disable-libatomic \
	--disable-tls \
	--disable-libstdc__-v3 \
	--disable-libquadmath \
	--disable-multilib \
	--disable-zlib \
	--disable-libssp \
	--disable-libmudflap \
	--disable-libgomp \
	--disable-libitm \
	--disable-nls \
	--disable-plugins \
	--disable-sjlj-exceptions \
	--disable-bootstrap \
        --disable-isl-version-check \
	--with-gmp=${TEMP} \
	--with-mpfr=${TEMP} \
	--with-mpc=${TEMP} \
	--with-isl=${TEMP} \
        --with-cloog=${TEMP}
  make -j8 all && make install
) && touch stamps/gcc-stage1

# build musl static
test -f stamps/musl-static || (
  set -e
  cd build/musl-riscv-${musl_version}
  make -j8 lib/libc.a CFLAGS=-fPIE
  make DESTDIR=${SYSROOT} SHARED_LIBS= install-libs
) && touch stamps/musl-static

# build final gcc
test -f stamps/gcc-final || (
  set -e
  test -f archives/gcc-${gcc_version}.tar.bz2 || \
      curl -o archives/gcc-${gcc_version}.tar.bz2 \
      http://ftp.gnu.org/gnu/gcc/gcc-${gcc_version}/gcc-${gcc_version}.tar.bz2
  test -d build/gcc-${gcc_version} || \
      tar -C build -xjf archives/gcc-${gcc_version}.tar.bz2
  cd build/gcc-${gcc_version}
  test -d output || mkdir output
  cd output
  CFLAGS=-fPIE ../configure \
	--prefix=${PREFIX} \
        --target=${TRIPLE} \
	--with-arch=${ARCH} \
	--program-transform-name='s&^&'${TRIPLE}'-&' \
	--with-sysroot=${SYSROOT} \
	--with-gnu-as \
	--with-gnu-ld \
	--enable-languages=c,c++ \
	--enable-target-optspace \
	--enable-cloog-backend=isl \
	--enable-initfini-array \
	--enable-shared \
	--enable-threads \
	--enable-libgcc \
	--enable-libatomic \
	--enable-tls \
	--enable-libstdc__-v3 \
	--enable-libquadmath \
	--disable-multilib \
	--disable-zlib \
	--disable-libssp \
	--disable-libmudflap \
	--disable-libgomp \
	--disable-libitm \
	--disable-nls \
	--disable-plugins \
	--disable-sjlj-exceptions \
	--disable-bootstrap \
        --disable-isl-version-check \
	--with-gmp=${TEMP} \
	--with-mpfr=${TEMP} \
	--with-mpc=${TEMP} \
	--with-isl=${TEMP} \
        --with-cloog=${TEMP}
  make -j8 all && make install
) && touch stamps/gcc-final

# build musl dynamic
test -f stamps/musl-dynamic || (
  set -e
  cd build/musl-riscv-${musl_version}
  make -j8
  make DESTDIR=${SYSROOT} install-libs
) && touch stamps/musl-dynamic
