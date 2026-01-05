# Genesis Kernel

A microkernel for Genesis OS, written in [Genesis Lang](https://github.com/unbiasedcodex/genesis-lang).

> **Note**: This project requires `glc` (Genesis Lang compiler) in your PATH. See [Requirements](#requirements) for installation instructions.

## Features

- **Microkernel architecture**: Minimal kernel space (~5000 lines)
- **Capability-based security**: No ambient authority
- **Message passing IPC**: Synchronous communication
- **Memory safety**: Inherited from Genesis Lang

## Requirements

- `glc` (Genesis Lang compiler) in PATH
- `nasm` (Netwide Assembler)
- `ld` (GNU linker)
- `objcopy` (from binutils)
- `grub-mkrescue` and `xorriso` (for ISO creation)
- QEMU (for testing)

### Installing Dependencies (Ubuntu/Debian)

```bash
sudo apt install nasm grub-pc-bin xorriso qemu-system-x86
```

### Installing glc

```bash
git clone https://github.com/unbiasedcodex/genesis-lang
cd genesis-lang
cargo build --release
sudo cp target/release/glc /usr/local/bin/
```

## Building

```bash
make iso        # Build bootable ISO
make run        # Run in QEMU (serial output)
make run-vga    # Run in QEMU (VGA display)
make debug      # Run with interrupt logging
make clean      # Remove build artifacts
```

### Boot Verification

When running `make run`, you should see:

```
BOOT
64
KERNEL
```

- `BOOT` - 32-bit Multiboot entry reached
- `64` - Long mode transition successful
- `KERNEL` - Genesis kernel running

## Project Structure

```
genesis-kernel/
├── src/
│   └── main.gl              # Kernel entry point (_start)
├── arch/
│   └── x86_64/
│       └── boot.asm         # Multiboot + 32→64 bit transition
├── linker/
│   └── kernel.ld            # Linker script
├── iso/
│   └── boot/grub/
│       └── grub.cfg         # GRUB configuration
├── Makefile
└── README.md
```

## Development Status

- [x] Phase 1: Minimal boot
  - [x] Multiboot1 header
  - [x] 32-bit to 64-bit transition
  - [x] Identity paging (8MB)
  - [x] VGA text output
  - [x] Serial debug output
  - [x] Bootable ISO with GRUB
- [ ] Phase 2: Memory management
- [ ] Phase 3: Interrupts
- [ ] Phase 4: Processes
- [ ] Phase 5: IPC

## License

MIT
