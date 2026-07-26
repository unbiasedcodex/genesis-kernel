# Genesis Kernel

The kernel of Genesis OS, written in [Genesis Lang](https://github.com/unbiasedcodex/genesis-lang) (~34,000 lines of `.gl`) with a small amount of x86_64 assembly for boot, interrupt stubs, and context switching.

> **Note**: This project requires `glc` (Genesis Lang compiler) in your PATH. See [Requirements](#requirements) for installation instructions.

Current kernel version: **v0.0.12**

## Features

- **Microkernel direction**: core services (init, VFS, console, shell) run as userspace processes loaded as GRUB modules and communicate via IPC
- **Memory management**: bitmap PMM, paging VMM, heap with dynamic expansion up to 64 MB, slab allocator, memory-mapped files with demand paging
- **Processes**: PCB-based scheduler, context switching, syscall interface (spawn, wait with `WAIT_NOHANG`, time, sleep), userspace ELF loading from multiboot modules
- **Interrupts**: IDT, PIC remapping, ISR stubs in assembly
- **Drivers**: serial, PS/2 keyboard and mouse, ATA disk, E1000 network card, VBE framebuffer
- **Network stack**: Ethernet, ARP, DHCP, IPv4, ICMP, UDP, TCP, sockets
- **TLS 1.2**: complete handshake with RSA-2048 key exchange, AES-GCM encryption, and X.509 certificate validation
- **Graphics**: VBE framebuffer with optimized (inline assembly) operations, bitmap font rendering, TTF font rasterizer
- **Window manager**: compositor, windows, event system
- **Memory safety**: inherited from Genesis Lang (HARC)

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
make            # Build kernel.elf
make iso        # Build bootable ISO (expects userspace ELFs in iso/boot/, see genesis-runtime)
make run        # Run in QEMU (serial output)
make run-vga    # Run in QEMU (VGA display)
make run-disk   # Run with an 8MB IDE test disk attached
make run-net    # Run with an E1000 NIC (user networking, host port 8080 -> guest 80)
make debug      # Run with interrupt logging
make clean      # Remove build artifacts
make check      # Verify build tools are available
```

The full system boots the kernel plus the userspace services from `genesis-runtime`. GRUB loads them as multiboot modules (see `iso/boot/grub/grub.cfg`):

```
multiboot /boot/kernel.elf
module /boot/init.elf init
module /boot/vfs.elf vfs
module /boot/console.elf console
module /boot/shell.elf shell
```

Build the services with `make install` in `genesis-runtime` before `make iso`.

## Project Structure

```
genesis-kernel/
├── src/
│   ├── main.gl              # Kernel core: entry, mm glue, syscalls, scheduler,
│   │                        #   drivers (serial, PS/2, ATA), IPC, TLS
│   ├── mm/                  # Physical/virtual memory, heap, slab, multiboot parsing
│   ├── interrupts/          # IDT, PIC, handlers
│   ├── net/                 # E1000, ethernet, ARP, DHCP, IPv4, ICMP, UDP, TCP, sockets
│   ├── gfx/                 # Framebuffer primitives
│   ├── font/                # Bitmap font + TTF rasterizer
│   ├── wm/                  # Window manager: compositor, windows, events
│   └── drivers/             # Driver module index
├── arch/x86_64/
│   ├── boot.asm             # Multiboot + 32->64 bit transition (128MB identity mapped)
│   ├── isr.asm              # Interrupt service routine stubs
│   ├── context.asm          # Context switch routines
│   └── alloc.asm            # Allocator stubs
├── linker/kernel.ld         # Linker script
├── iso/boot/grub/grub.cfg   # GRUB configuration (kernel + userspace modules)
├── Makefile
└── README.md
```

## Development Status

- [x] Phase 1: Minimal boot (Multiboot1, long mode, VGA/serial output, GRUB ISO)
- [x] Phase 2: Memory management (PMM, VMM, heap, slab, dynamic heap expansion)
- [x] Phase 3: Interrupts (IDT, PIC, ISRs)
- [x] Phase 4: Processes (scheduler, context switch, syscalls, userspace spawning)
- [x] Phase 5: IPC (message passing; VFS/console/shell extracted to userspace)
- [x] Phase 6: Drivers and disk I/O (ATA, PS/2 mouse, VBE framebuffer)
- [x] Phase 7: Network stack (E1000, ARP, DHCP, IPv4, TCP, UDP, sockets)
- [x] Phase 8: TLS 1.2 (RSA-2048, AES-GCM, X.509 validation)
- [ ] Next: HTTPS end-to-end in the userspace browser (see genesis-runtime), stability, SMP

## License

MIT
