#!/bin/bash

case "$1" in
    rv32)
	ARCH=riscv32
	WITHARCH=--with-arch=rv32imafdc
	;;
    rv64)
	ARCH=riscv64
	WITHARCH=--with-arch=rv64imafdc
	;;
    i386)
	ARCH=i386
	WITHARCH=--with-arch-32=core2
	;;
    x86_64)
	ARCH=x86_64
	WITHARCH=--with-arch-64=core2
	;;
    aarch64)
	ARCH=aarch64
	WITHARCH=--with-arch=armv8-a
	;;
  *)
    echo "Usage: $0 {rv32|rv64|i386|x86_64|aarch64}"
    exit 1
esac

bootstrap_prefix=/opt/riscv/musl-riscv-toolchain
bootstrap_version=1
gmp_version=6.1.0
mpfr_version=3.1.5
mpc_version=1.0.3
isl_version=0.16.1
cloog_version=0.18.4
binutils_version=2.28
gcc_version=7.2.0
musl_version=1.1.17-riscv-a3

PREFIX=${bootstrap_prefix}-${gcc_version}-${bootstrap_version}
TRIPLE=${ARCH}-linux-musl
TEMP=`pwd`/build/temp-install
SYSROOT=${PREFIX}/${TARGET:=$TRIPLE}

echo PREFIX=${PREFIX}
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
test "$?" -eq "0" || exit 1

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
test "$?" -eq "0" || exit 1

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
test "$?" -eq "0" || exit 1

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
test "$?" -eq "0" || exit 1

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
test "$?" -eq "0" || exit 1

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
        --target=${TARGET:=$TRIPLE} ${WITHARCH} \
        --program-transform-name='s&^&'${TRIPLE}'-&' \
	--with-sysroot=${SYSROOT} \
	--disable-nls \
	--disable-libssp \
	--disable-shared \
	--disable-werror  \
        --disable-isl-version-check \
        --disable-multilib \
        --with-gmp=${TEMP} \
        --with-mpfr=${TEMP} \
        --with-mpc=${TEMP} \
        --with-isl=${TEMP} \
        --with-cloog=${TEMP}
  make -j8 && make install
) && touch stamps/binutils
test "$?" -eq "0" || exit 1

# musl headers
test -f stamps/musl-headers || (
  set -e
  test -f archives/musl-riscv-${musl_version}.tar.gz || \
      curl -o archives/musl-riscv-${musl_version}.tar.gz \
      https://codeload.github.com/rv8-io/musl-riscv/tar.gz/v${musl_version}
  test -d build/musl-riscv-${musl_version} || \
      tar -C build -xzf archives/musl-riscv-${musl_version}.tar.gz
  cd build/musl-riscv-${musl_version}
  test -f ../../stamps/musl-patch || (
    patch -p0 < ../../patches/musl-stdbool-cpluscplus.patch
    touch ../../stamps/musl-patch
  )
  echo prefix= > config.mak
  echo exec_prefix= >> config.mak
  echo ARCH=${ARCH} >> config.mak
  echo CC=${PREFIX}/bin/${TRIPLE}-gcc >> config.mak
  echo AS=${PREFIX}/bin/${TRIPLE}-as >> config.mak
  echo LD=${PREFIX}/bin/${TRIPLE}-ld >> config.mak
  make DESTDIR=${SYSROOT} install-headers
  mkdir -p ${SYSROOT}/usr
  ln -s ../lib ${SYSROOT}/usr/lib
  ln -s ../include ${SYSROOT}/usr/include
) && touch stamps/musl-headers
test "$?" -eq "0" || exit 1

# build gcc stage1
test -f stamps/gcc-stage1 || (
  set -e
  test -f archives/gcc-${gcc_version}.tar.xz || \
      curl -o archives/gcc-${gcc_version}.tar.xz \
      http://ftp.gnu.org/gnu/gcc/gcc-${gcc_version}/gcc-${gcc_version}.tar.xz
  test -d build/gcc-${gcc_version} || \
      tar -C build -xJf archives/gcc-${gcc_version}.tar.xz
  cd build/gcc-${gcc_version}
  test -f ../../stamps/gcc-patch || (
    patch -p0 < ../../patches/gcc-7.1-strict-operands.patch
    touch ../../stamps/gcc-patch
  )
  test -d output || mkdir output
  cd output
  CFLAGS=-fPIE ../configure \
	--prefix=${PREFIX} \
        --target=${TARGET:=$TRIPLE} ${WITHARCH} \
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
	--disable-libsanitizer \
	--disable-libvtv \
	--disable-libmpx \
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
test "$?" -eq "0" || exit 1

# build musl static
test -f stamps/musl-static || (
  set -e
  cd build/musl-riscv-${musl_version}
  make -j8 lib/libc.a CFLAGS=-fPIE
  make DESTDIR=${SYSROOT} SHARED_LIBS= install-libs
) && touch stamps/musl-static
test "$?" -eq "0" || exit 1

# build stage2 gcc
test -f stamps/gcc-stage2 || (
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
        --target=${TARGET:=$TRIPLE} ${WITHARCH} \
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
	--enable-tls \
	--enable-libgcc \
	--disable-libatomic \
	--disable-libstdc__-v3 \
	--disable-libquadmath \
	--disable-libsanitizer \
	--disable-libvtv \
	--disable-libmpx \
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
) && touch stamps/gcc-stage2
test "$?" -eq "0" || exit 1

# build musl dynamic
test -f stamps/musl-dynamic || (
  set -e
  cd build/musl-riscv-${musl_version}
  make -j8
  make DESTDIR=${SYSROOT} install-libs
) && touch stamps/musl-dynamic
test "$?" -eq "0" || exit 1

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
        --target=${TARGET:=$TRIPLE} ${WITHARCH} \
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
	--enable-tls \
	--enable-libgcc \
	--enable-libatomic \
	--enable-libstdc__-v3 \
	--disable-libquadmath \
	--disable-libsanitizer \
	--disable-libvtv \
	--disable-libmpx \
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
test "$?" -eq "0" || exit 1
