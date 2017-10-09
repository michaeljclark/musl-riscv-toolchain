# musl-riscv-toolchain

musl-riscv-toolchain gcc 7.2 bootstrap script

### Building and Installing

The script automatically downloads approximately 120MiB of prerequisites:

- binutils-2.28.tar.bz2
- cloog-0.18.4.tar.gz
- gcc-7.2.0.tar.bz2
- gmp-6.1.0.tar.bz2
- isl-0.16.1.tar.bz2
- mpc-1.0.3.tar.gz
- mpfr-3.1.6.tar.bz2
- musl-riscv-1.1.17-riscv-a5.tar.gz

To build and install the riscv64 toolchain run the following command:

```
sh bootstrap.sh rv64
```

To build toolchains for riscv64, riscv32, x86_64, i386, aarch64 and arm:

```
rm -fr build stamps
for i in rv64 rv32 x86_64 i386 arm64 arm32; do sh bootstrap.sh $i ; rm -fr build stamps ; done
```

The script installs the toolchain to the following directory:

- `/opt/riscv/musl-riscv-toolchain-7.2.0-5`

Add the toolchain to your `PATH` environment variable

```
export PATH=${PATH}:/opt/riscv/musl-riscv-toolchain-7.2.0-5/bin
```

After building, the toolchain will be installed as follows:

- `/opt/riscv/musl-riscv-toolchain-7.2.0-5/`
  - `bin/`
    - `aarch64-linux-musl-{as,ld,gcc,g++,strip,objdump}`
    - `arm-linux-musleabihf-{as,ld,gcc,g++,strip,objdump}`
    - `i386-linux-musl-{as,ld,gcc,g++,strip,objdump}`
    - `riscv32-linux-musl-{as,ld,gcc,g++,strip,objdump}`
    - `riscv64-linux-musl-{as,ld,gcc,g++,strip,objdump}`
    - `x86_64-linux-musl-{as,ld,gcc,g++,strip,objdump}`
  - `aarch64-linux-musl/`
    - `lib/`
    - `include/`
  - `arm-linux-musleabihf/`
    - `lib/`
    - `include/`
  - `i386-linux-musl/`
    - `lib/`
    - `include/`
  - `riscv32-linux-musl/`
    - `lib/`
    - `include/`
  - `riscv64-linux-musl/`
    - `lib/`
    - `include/`
  - `x86_64-linux-musl/`
    - `lib/`
    - `include/`

