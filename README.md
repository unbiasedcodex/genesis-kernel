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
- `ld` (GNU linker)
- QEMU (for testing)

### Installing glc

```bash
git clone https://github.com/unbiasedcodex/genesis-lang
cd genesis-lang
cargo build --release
sudo cp target/release/glc /usr/local/bin/
```

## Building

```bash
make            # Build kernel.elf
make run        # Run in QEMU
make clean      # Remove build artifacts
```

## Project Structure

```
genesis-kernel/
├── src/
│   └── main.gl         # Kernel entry point
├── linker/
│   └── kernel.ld       # Linker script
├── Makefile
└── README.md
```

## Development Status

- [x] Phase 0: Project setup
- [ ] Phase 1: Minimal boot (requires 32-to-64-bit bootloader)
- [ ] Phase 2: Memory management
- [ ] Phase 3: Interrupts
- [ ] Phase 4: Processes
- [ ] Phase 5: IPC

### Current Status

The kernel compiles to a valid ELF64 executable. Booting requires a bootloader that:
1. Loads in 32-bit protected mode (Multiboot)
2. Sets up long mode (64-bit)
3. Jumps to the Genesis kernel entry point

This will be implemented in Phase 1.

## License

MIT
