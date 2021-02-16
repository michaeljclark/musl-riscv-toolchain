#!/bin/bash
#
# ## musl-riscv-toolchain
#
# musl libc GCC cross compiler toolchain bootstrap script
#
# usage: ./bootstrap.sh <arch> [native-cross]
#
# This script by default builds cross compilers for the supported
# target architectures. If the optional "native-cross" option is
# given, then in addition to building a cross compiler for the
# target, the script will use the target cross compiler to build
# a native compiler for the target architecture linked with the
# target architecture's musl C library. The native compiler is
# installed into ${SYSROOT}/usr/bin
#
# ## Supported architectures:
#
# - riscv32
# - riscv64
# - i386
# - x86_64
# - arm
# - aarch64
#
# ## Directory layout
#
# - ${bootstrap_prefix}-${gcc_version}-${bootstrap_version}
#   - bin/
#     - {$triple}-{as,ld,gcc,g++,strip,objdump} # host binaries
#   - ${triple}                                 # sysroot
#     - include                                 # target headers
#     - lib                                     # target libraries
#     - usr
#       - lib -> ../lib
#       - bin
#         - {as,ld,gcc,g++,strip,objdump}       # target binaries
#

case "$1" in
  riscv32)
    ARCH=riscv32
    LINUX_ARCH=riscv
    WITHARCH=--with-arch=rv32imafdc
    ;;
  riscv64)
    ARCH=riscv64
    LINUX_ARCH=riscv
    WITHARCH=--with-arch=rv64imafdc
    ;;
  i386)
    ARCH=i386
    LINUX_ARCH=x86
    WITHARCH=--with-arch-32=core2
    ;;
  x86_64)
    ARCH=x86_64
    LINUX_ARCH=x86
    WITHARCH=--with-arch-64=core2
    ;;
  arm)
    ARCH=arm
    LINUX_ARCH=arm
    WITHARCH=--with-arch=armv7-a
    SUFFIX=eabihf
    ;;
  aarch64)
    ARCH=aarch64
    LINUX_ARCH=arm64
    WITHARCH=--with-arch=armv8-a
    ;;
  *)
    echo "Usage: $0 {riscv32|riscv64|i386|x86_64|arm|aarch64}"
    exit 1
esac

set -e

# build dependency versions
gmp_version=6.1.2
mpfr_version=3.1.4
mpc_version=1.0.3
isl_version=0.16.1
cloog_version=0.18.4
binutils_version=2.31.1
gcc_version=8.2.0
musl_version=1.1.18-riscv-a6
linux_version=4.18

# bootstrap install prefix and version
bootstrap_prefix=/opt/riscv/musl-riscv-toolchain
bootstrap_version=1

# derived variables
PREFIX=${bootstrap_prefix}-${gcc_version}-${bootstrap_version}
TRIPLE=${ARCH}-linux-musl${SUFFIX}
SYSROOT=${PREFIX}/${TARGET:=$TRIPLE}
TOPDIR=$(pwd)

make_directories()
{
  test -d src || mkdir src
  test -d build || mkdir build
  test -d stamps || mkdir stamps
  test -d archives || mkdir archives
  test -d ${PREFIX} || mkdir -p ${PREFIX}
}

download_prerequisites()
{
  test -f archives/gmp-${gmp_version}.tar.bz2 || \
      curl -o archives/gmp-${gmp_version}.tar.bz2 \
      https://gmplib.org/download/gmp-${gmp_version}/gmp-${gmp_version}.tar.bz2
  test -f archives/mpfr-${mpfr_version}.tar.bz2 || \
      curl -o archives/mpfr-${mpfr_version}.tar.bz2 \
      https://gcc.gnu.org/pub/gcc/infrastructure/mpfr-${mpfr_version}.tar.bz2
  test -f archives/mpc-${mpc_version}.tar.gz || \
      curl -o archives/mpc-${mpc_version}.tar.gz \
      https://gcc.gnu.org/pub/gcc/infrastructure/mpc-${mpc_version}.tar.gz
  test -f archives/isl-${isl_version}.tar.bz2 || \
      curl -o archives/isl-${isl_version}.tar.bz2 \
      ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-${isl_version}.tar.bz2
  test -f archives/cloog-${cloog_version}.tar.gz || \
      curl -o archives/cloog-${cloog_version}.tar.gz \
      http://www.bastoul.net/cloog/pages/download/cloog-${cloog_version}.tar.gz
  test -f archives/binutils-${binutils_version}.tar.bz2 || \
      curl -o archives/binutils-${binutils_version}.tar.bz2 \
      http://ftp.gnu.org/gnu/binutils/binutils-${binutils_version}.tar.bz2
  test -f archives/musl-riscv-${musl_version}.tar.gz || \
      curl -o archives/musl-riscv-${musl_version}.tar.gz \
      https://codeload.github.com/rv8-io/musl-riscv/tar.gz/${musl_version}
  test -f archives/linux-${linux_version}.tar.xz || \
      curl -L -o archives/linux-${linux_version}.tar.xz \
      https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${linux_version}.tar.xz
  test -f archives/gcc-${gcc_version}.tar.xz || \
      curl -o archives/gcc-${gcc_version}.tar.xz \
      http://ftp.gnu.org/gnu/gcc/gcc-${gcc_version}/gcc-${gcc_version}.tar.xz
}

extract_archives()
{
  test -d src/gmp-${gmp_version} || \
      tar -C src -xjf archives/gmp-${gmp_version}.tar.bz2
  test -d src/mpfr-${mpfr_version} || \
      tar -C src -xjf archives/mpfr-${mpfr_version}.tar.bz2
  test -d src/mpc-${mpc_version} || \
      tar -C src -xzf archives/mpc-${mpc_version}.tar.gz
  test -d src/isl-${isl_version} || \
      tar -C src -xjf archives/isl-${isl_version}.tar.bz2
  test -d src/cloog-${cloog_version} || \
      tar -C src -xzf archives/cloog-${cloog_version}.tar.gz
  test -d src/binutils-${binutils_version} || \
      tar -C src -xjf archives/binutils-${binutils_version}.tar.bz2
  test -d src/musl-riscv-${musl_version} || \
      tar -C src -xzf archives/musl-riscv-${musl_version}.tar.gz
  test -d src/linux-${linux_version} || \
      tar -C src -xJf archives/linux-${linux_version}.tar.xz
  test -d src/gcc-${gcc_version} || \
      tar -C src -xJf archives/gcc-${gcc_version}.tar.xz
}

patch_musl()
{
  test -f src/musl-riscv-${musl_version}/.patched || (
    set -e
    cd src/musl-riscv-${musl_version}
    patch -p0 < ../../patches/musl-stdbool-cpluscplus.patch
    touch .patched
  )
  test "$?" -eq "0" || exit 1
}

patch_gcc()
{
  test -f src/gcc-${gcc_version}/.patched || (
    set -e
    cd src/gcc-${gcc_version}
    #patch -p0 < ../../patches/gcc-7.1-strict-operands.patch
    touch .patched
  )
  test "$?" -eq "0" || exit 1
}

build_gmp()
{
  host=$1; shift
  test -f stamps/lib-gmp-${host} || (
    set -e
    test -d build/gmp-${host} || mkdir build/gmp-${host}
    cd build/gmp-${host}
    CFLAGS=-fPIE ../../src/gmp-${gmp_version}/configure \
        --disable-shared \
        --prefix=${TOPDIR}/build/install-${host} \
        $*
    make -j$(nproc) && make install
  ) && touch stamps/lib-gmp-${host}
  test "$?" -eq "0" || exit 1
}

build_mpfr()
{
  host=$1; shift
  test -f stamps/lib-mpfr-${host} || (
    set -e
    test -d build/mpfr-${host} || mkdir build/mpfr-${host}
    cd build/mpfr-${host}
    CFLAGS=-fPIE ../../src/mpfr-${mpfr_version}/configure \
        --disable-shared \
        --prefix=${TOPDIR}/build/install-${host} \
        --with-gmp=${TOPDIR}/build/install-${host} \
        $*
    make -j$(nproc) && make install
  ) && touch stamps/lib-mpfr-${host}
  test "$?" -eq "0" || exit 1
}

build_mpc()
{
  host=$1; shift
  test -f stamps/lib-mpc-${host} || (
    set -e
    test -d build/mpc-${host} || mkdir build/mpc-${host}
    cd build/mpc-${host}
    CFLAGS=-fPIE ../../src/mpc-${mpc_version}/configure \
        --disable-shared \
        --prefix=${TOPDIR}/build/install-${host} \
        --with-gmp=${TOPDIR}/build/install-${host} \
        --with-mpfr=${TOPDIR}/build/install-${host} \
        $*
    make -j$(nproc) && make install
  ) && touch stamps/lib-mpc-${host}
  test "$?" -eq "0" || exit 1
}

build_isl()
{
  host=$1; shift
  if [ "${build_graphite}" = "yes" ]; then
    test -f stamps/lib-isl-${host} || (
      set -e
      test -d build/isl-${host} || mkdir build/isl-${host}
      cd build/isl-${host}
      CFLAGS=-fPIE ../../src/isl-${isl_version}/configure \
          --disable-shared \
          --prefix=${TOPDIR}/build/install-${host} \
          --with-gmp-prefix=${TOPDIR}/build/install-${host} \
          $*
      make -j$(nproc) && make install
    ) && touch stamps/lib-isl-${host}
    test "$?" -eq "0" || exit 1
  fi
}

build_cloog()
{
  host=$1; shift
  if [ "${build_graphite}" = "yes" ]; then
    test -f stamps/lib-cloog-${host} || (
      set -e
      test -d build/cloog-${host} || mkdir build/cloog-${host}
      cd build/cloog-${host}
      CFLAGS=-fPIE ../../src/cloog-${cloog_version}/configure \
          --disable-shared \
          --prefix=${TOPDIR}/build/install-${host} \
          --with-isl-prefix=${TOPDIR}/build/install-${host} \
          --with-gmp-prefix=${TOPDIR}/build/install-${host} \
          $*
      make -j$(nproc) && make install
    ) && touch stamps/lib-cloog-${host}
    test "$?" -eq "0" || exit 1
  fi
}

build_binutils()
{
  host=$1; shift
  prefix=$1; shift
  destdir=$1; shift
  transform=$1; shift
  test -f stamps/binutils-${host}-${ARCH} || (
    set -e
    test -d build/binutils-${host}-${ARCH} || mkdir build/binutils-${host}-${ARCH}
    cd build/binutils-${host}-${ARCH}
    CFLAGS=-fPIE ../../src/binutils-${binutils_version}/configure \
        --prefix=${prefix} \
        --target=${TARGET:=$TRIPLE} ${WITHARCH} \
        ${transform:+--program-transform-name='s&^&'${TRIPLE}'-&'} \
        --with-sysroot=${SYSROOT} \
        --disable-nls \
        --disable-libssp \
        --disable-shared \
        --disable-werror  \
        --disable-multilib \
        --with-gmp=${TOPDIR}/build/install-${host} \
        --with-mpfr=${TOPDIR}/build/install-${host} \
        --with-mpc=${TOPDIR}/build/install-${host} \
        ${build_graphite:+--disable-isl-version-check} \
        ${build_graphite:+--with-isl=${TOPDIR}/build/install-${host}} \
        ${build_graphite:+--with-cloog=${TOPDIR}/build/install-${host}} \
        $*
    make -j$(nproc) && make DESTDIR=${destdir} install
  ) && touch stamps/binutils-${host}-${ARCH}
  test "$?" -eq "0" || exit 1
}

configure_musl()
{
  test -f stamps/musl-config-${ARCH} || (
    set -e
    rsync -a src/musl-riscv-${musl_version}/ build/musl-${ARCH}/
    cd build/musl-${ARCH}
    echo prefix= > config.mak
    echo exec_prefix= >> config.mak
    echo ARCH=${ARCH} >> config.mak
    echo CC=${PREFIX}/bin/${TRIPLE}-gcc >> config.mak
    echo AS=${PREFIX}/bin/${TRIPLE}-as >> config.mak
    echo LD=${PREFIX}/bin/${TRIPLE}-ld >> config.mak
    echo AR=${PREFIX}/bin/${TRIPLE}-ar >> config.mak
    echo RANLIB=${PREFIX}/bin/${TRIPLE}-ranlib >> config.mak
  ) && touch stamps/musl-config-${ARCH}
  test "$?" -eq "0" || exit 1
}

install_musl_headers()
{
  test -f stamps/musl-headers-${ARCH} || (
    set -e
    cd build/musl-${ARCH}
    make DESTDIR=${SYSROOT} install-headers
    mkdir -p ${SYSROOT}/usr
    test -L ${SYSROOT}/usr/lib || ln -s ../lib ${SYSROOT}/usr/lib
    test -L ${SYSROOT}/usr/include || ln -s ../include ${SYSROOT}/usr/include
  ) && touch stamps/musl-headers-${ARCH}
  test "$?" -eq "0" || exit 1
}

install_linux_headers()
{
  test -f stamps/linux-headers-${ARCH} || (
    set -e
    mkdir -p build/linux-headers-${ARCH}/staged
    ( cd src/linux-${linux_version} && \
        make ARCH=${LINUX_ARCH} O=../../build/linux-headers-${ARCH} \
             INSTALL_HDR_PATH=../../build/linux-headers-${ARCH}/staged headers_install )
    find build/linux-headers-${ARCH}/staged/include '(' -name .install -o -name ..install.cmd ')' -exec rm {} +
    rsync -a build/linux-headers-${ARCH}/staged/include/ ${SYSROOT}/usr/include/
  ) && touch stamps/linux-headers-${ARCH}
  test "$?" -eq "0" || exit 1
}

build_gcc_stage1()
{
  # musl compiler
  host=$1; shift
  prefix=$1; shift
  destdir=$1; shift
  transform=$1; shift
  test -f stamps/gcc-stage1-${host}-${ARCH} || (
    set -e
    test -d build/gcc-stage1-${host}-${ARCH} || mkdir build/gcc-stage1-${host}-${ARCH}
    cd build/gcc-stage1-${host}-${ARCH}
    CFLAGS=-fPIE ../../src/gcc-${gcc_version}/configure \
        --prefix=${prefix} \
        --target=${TARGET:=$TRIPLE} ${WITHARCH} \
        ${transform:+--program-transform-name='s&^&'${TRIPLE}'-&'} \
        --with-sysroot=${SYSROOT} \
        --with-gnu-as \
        --with-gnu-ld \
        --enable-languages=c,c++ \
        --enable-target-optspace \
        --enable-initfini-array \
        --enable-zlib \
        --enable-libgcc \
        --enable-tls \
        --disable-shared \
        --disable-threads \
        --disable-libatomic \
        --disable-libstdc__-v3 \
        --disable-libquadmath \
        --disable-libsanitizer \
        --disable-libvtv \
        --disable-libmpx \
        --disable-multilib \
        --disable-libssp \
        --disable-libmudflap \
        --disable-libgomp \
        --disable-libitm \
        --disable-nls \
        --disable-plugins \
        --disable-sjlj-exceptions \
        --disable-bootstrap \
        --with-gmp=${TOPDIR}/build/install-${host} \
        --with-mpfr=${TOPDIR}/build/install-${host} \
        --with-mpc=${TOPDIR}/build/install-${host} \
        ${build_graphite:+--disable-isl-version-check} \
        ${build_graphite:+--enable-cloog-backend=isl} \
        ${build_graphite:+--with-isl=${TOPDIR}/build/install-${host}} \
        ${build_graphite:+--with-cloog=${TOPDIR}/build/install-${host}} \
        $*
    make -j$(nproc) inhibit-libc=true all-gcc all-target-libgcc
    make DESTDIR=${destdir} inhibit-libc=true install-gcc install-target-libgcc
  ) && touch stamps/gcc-stage1-${host}-${ARCH}
  test "$?" -eq "0" || exit 1
}

build_musl()
{
  test -f stamps/musl-dynamic-${ARCH} || (
    set -e
    cd build/musl-${ARCH}
    make -j$(nproc)
    make DESTDIR=${SYSROOT} install-libs
  ) && touch stamps/musl-dynamic-${ARCH}
  test "$?" -eq "0" || exit 1
}

build_gcc_stage2()
{
  # final compiler
  host=$1; shift
  prefix=$1; shift
  destdir=$1; shift
  transform=$1; shift
  test -f stamps/gcc-stage2-${host}-${ARCH} || (
    set -e
    test -d build/gcc-stage2-${host}-${ARCH} || mkdir build/gcc-stage2-${host}-${ARCH}
    cd build/gcc-stage2-${host}-${ARCH}
    CFLAGS=-fPIE ../../src/gcc-${gcc_version}/configure \
        --prefix=${prefix} \
        --target=${TARGET:=$TRIPLE} ${WITHARCH} \
        ${transform:+--program-transform-name='s&^&'${TRIPLE}'-&'} \
        --with-sysroot=${SYSROOT} \
        --with-gnu-as \
        --with-gnu-ld \
        --enable-languages=c,c++ \
        --enable-target-optspace \
        --enable-initfini-array \
        --enable-zlib \
        --enable-libgcc \
        --enable-tls \
        --enable-shared \
        --enable-threads \
        --enable-libatomic \
        --enable-libstdc__-v3 \
        --disable-libquadmath \
        --disable-libsanitizer \
        --disable-libvtv \
        --disable-libmpx \
        --disable-multilib \
        --disable-libssp \
        --disable-libmudflap \
        --disable-libgomp \
        --disable-libitm \
        --disable-nls \
        --disable-plugins \
        --disable-sjlj-exceptions \
        --disable-bootstrap \
        --with-gmp=${TOPDIR}/build/install-${host} \
        --with-mpfr=${TOPDIR}/build/install-${host} \
        --with-mpc=${TOPDIR}/build/install-${host} \
        ${build_graphite:+--disable-isl-version-check} \
        ${build_graphite:+--enable-cloog-backend=isl} \
        ${build_graphite:+--with-isl=${TOPDIR}/build/install-${host}} \
        ${build_graphite:+--with-cloog=${TOPDIR}/build/install-${host}} \
        $*
    make -j$(nproc) all-gcc all-target-libgcc all-target-libstdc++-v3
    make DESTDIR=${destdir} install-gcc install-target-libgcc install-target-libstdc++-v3
  ) && touch stamps/gcc-stage2-${host}-${ARCH}
  test "$?" -eq "0" || exit 1
}


#
# build musl libc toolchain for host
#

make_directories
download_prerequisites
extract_archives
patch_musl
patch_gcc

build_gmp             host
build_mpfr            host
build_mpc             host
build_isl             host
build_cloog           host
build_binutils        host ${PREFIX} / transform-name

configure_musl
install_musl_headers
install_linux_headers

build_gcc_stage1      host ${PREFIX} / transform-name
build_musl
build_gcc_stage2      host ${PREFIX} / transform-name


#
# build musl libc toolchain for target
#

if [ "$2" = "native-cross" ]; then

  export PATH=${PREFIX}/bin:${PATH}

  build_gmp             ${ARCH} --host=${TRIPLE}
  build_mpfr            ${ARCH} --host=${TRIPLE}
  build_mpc             ${ARCH} --host=${TRIPLE}
  build_isl             ${ARCH} --host=${TRIPLE}
  build_cloog           ${ARCH} --host=${TRIPLE}
  build_binutils        ${ARCH} /usr ${SYSROOT} '' --host=${TRIPLE}
  build_gcc_stage2      ${ARCH} /usr ${SYSROOT} '' --host=${TRIPLE}

fi
