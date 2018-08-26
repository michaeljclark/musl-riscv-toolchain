# musl-riscv-toolchain

musl-riscv-toolchain gcc 8.1 bootstrap script

### Building and Installing

The script automatically downloads approximately 200MiB of prerequisites:

- binutils-2.31.1.tar.bz2
- cloog-0.18.4.tar.gz
- gcc-8.1.0.tar.bz2
- gmp-6.1.2.tar.bz2
- isl-0.16.1.tar.bz2
- linux-4.18.tar.xz
- mpc-1.0.3.tar.gz
- mpfr-3.1.4.tar.bz2
- musl-riscv-1.1.18-riscv-a6.tar.gz

To build and install the riscv64 toolchain run the following command:

```
sh bootstrap.sh riscv64
```

To build toolchains for riscv32, riscv64, i386, x86_64, arm and aarch64:

```
for i in riscv32 riscv64 i386 x86_64 arm aarch64; do sh bootstrap.sh $i ; done
```

The script installs the toolchain to the following directory:

- `/opt/riscv/musl-riscv-toolchain-8.1.0-1`

Add the toolchain to your `PATH` environment variable

```
export PATH=${PATH}:/opt/riscv/musl-riscv-toolchain-8.1.0-1/bin
```

After building, the toolchain will be installed as follows:

- `/opt/riscv/musl-riscv-toolchain-8.1.0-1/`
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

