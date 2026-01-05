# Genesis Kernel Makefile

# Compiler
GLC = glc
GLCFLAGS = --freestanding --linker-script=linker/kernel.ld

# Output
KERNEL = kernel.elf

# Source files
SRC = src/main.gl

# Default target
all: $(KERNEL)

# Build kernel
$(KERNEL): $(SRC) linker/kernel.ld
	$(GLC) build $(SRC) $(GLCFLAGS) -o $(KERNEL)

# Run in QEMU
run: $(KERNEL)
	qemu-system-x86_64 -kernel $(KERNEL) -serial stdio -no-reboot -no-shutdown

# Run with debug output
debug: $(KERNEL)
	qemu-system-x86_64 -kernel $(KERNEL) -serial stdio -no-reboot -no-shutdown -d int,cpu_reset

# Clean build artifacts
clean:
	rm -f $(KERNEL) *.o *.bin

# Check if glc is available
check:
	@which $(GLC) > /dev/null || (echo "Error: glc not found in PATH" && exit 1)
	@echo "glc found: $$(which $(GLC))"

.PHONY: all run debug clean check
