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
- mpfr-3.1.5.tar.bz2
- musl-riscv-1.1.17-riscv-a3.tar.gz

To build and install the toolchain run the following command:

```
sh bootstrap.sh rv64
```

The script installs the toolchain to the following directory:

- `/opt/riscv/musl-riscv-toolchain-7.2.0-1`

Add the toolchain to your `PATH` environment variable

```
export PATH=${PATH}:/opt/riscv/musl-riscv-toolchain-7.2.0-1/bin
```
