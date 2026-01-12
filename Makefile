# Genesis Kernel Makefile
# Phase 12: Device Drivers & Disk I/O

# Tools
GLC = /root/genesisos/genesis-lang/target/release/glc
LD = ld
NASM = nasm
OBJCOPY = objcopy

# Flags
GLCFLAGS = --freestanding --emit-obj
NASMFLAGS = -f elf64
LDFLAGS = -T linker/kernel.ld -m elf_x86_64 --nostdlib

# Output
KERNEL = kernel.elf
ISO = genesis.iso

# Object files
OBJ_BOOT = arch/x86_64/boot.o
OBJ_ISR = arch/x86_64/isr.o
OBJ_CTX = arch/x86_64/context.o
OBJ_KERNEL = kernel.o
OBJS = $(OBJ_BOOT) $(OBJ_ISR) $(OBJ_CTX) $(OBJ_KERNEL)

# Source files
SRC_BOOT = arch/x86_64/boot.asm
SRC_ISR = arch/x86_64/isr.asm
SRC_CTX = arch/x86_64/context.asm
SRC_KERNEL = src/main.gl

# Default target
all: $(KERNEL)

# Link kernel (ELF64, then convert to ELF32 for multiboot)
$(KERNEL): kernel64.elf
	$(OBJCOPY) -O elf32-i386 $< $@

kernel64.elf: $(OBJS) linker/kernel.ld
	$(LD) -T linker/kernel.ld -m elf_x86_64 --nostdlib -o $@ $(OBJS)

# Compile boot stub (32-bit entry + 64-bit transition)
$(OBJ_BOOT): $(SRC_BOOT)
	$(NASM) $(NASMFLAGS) $< -o $@

# Compile ISR stubs (interrupt service routines)
$(OBJ_ISR): $(SRC_ISR)
	$(NASM) $(NASMFLAGS) $< -o $@

# Compile context switch routines
$(OBJ_CTX): $(SRC_CTX)
	$(NASM) $(NASMFLAGS) $< -o $@

# Compile Genesis kernel (64-bit)
$(OBJ_KERNEL): $(SRC_KERNEL)
	$(GLC) build $< $(GLCFLAGS) -o $@

# Create bootable ISO with GRUB
iso: $(KERNEL)
	@mkdir -p iso/boot/grub
	cp $(KERNEL) iso/boot/kernel.elf
	cp iso/boot/grub/grub.cfg iso/boot/grub/grub.cfg 2>/dev/null || true
	grub-mkrescue -o $(ISO) iso 2>/dev/null

# Run in QEMU (text mode via serial)
run: iso
	qemu-system-x86_64 -cdrom $(ISO) -serial stdio -display none

# Run in QEMU with VGA display
run-vga: iso
	qemu-system-x86_64 -cdrom $(ISO)

# Run with debug output
debug: iso
	qemu-system-x86_64 -cdrom $(ISO) -serial stdio -display none -d int -no-reboot

# Create test disk image (8MB)
disk:
	@dd if=/dev/zero of=test.img bs=1M count=8 2>/dev/null
	@echo "Genesis Test Disk - Sector 0" | dd of=test.img bs=1 conv=notrunc 2>/dev/null
	@echo "Created test.img (8MB)"

# Run with disk attached (serial)
run-disk: iso disk
	qemu-system-x86_64 -cdrom $(ISO) -drive file=test.img,format=raw,if=ide -serial stdio -display none

# Run with disk attached (VGA)
run-disk-vga: iso disk
	qemu-system-x86_64 -cdrom $(ISO) -drive file=test.img,format=raw,if=ide

# Clean build artifacts
clean:
	rm -f $(KERNEL) kernel64.elf $(OBJS) $(ISO) test.img
	rm -rf iso/boot/kernel.elf

# Check tools
check:
	@which $(GLC) > /dev/null || (echo "Error: glc not found in PATH" && exit 1)
	@which $(NASM) > /dev/null || (echo "Error: nasm not found" && exit 1)
	@which grub-mkrescue > /dev/null || (echo "Error: grub-mkrescue not found" && exit 1)
	@echo "All tools found"

.PHONY: all iso run run-vga debug disk run-disk run-disk-vga clean check
