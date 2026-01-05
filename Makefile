# Genesis Kernel Makefile

# Compiler
GLC = glc
LD = ld

# Flags
GLCFLAGS = --freestanding --emit-obj
LDFLAGS = -T linker/kernel.ld --nostdlib -e _start

# Output
KERNEL = kernel.elf
OBJ = kernel.o

# Source files
SRC = src/main.gl

# Default target
all: $(KERNEL)

# Build kernel (compile + link)
$(KERNEL): $(OBJ)
	$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJ)

# Compile to object file
$(OBJ): $(SRC)
	$(GLC) build $(SRC) $(GLCFLAGS) -o $(OBJ)

# Run in QEMU
run: $(KERNEL)
	qemu-system-x86_64 -kernel $(KERNEL) -serial stdio -no-reboot -no-shutdown

# Run with debug output
debug: $(KERNEL)
	qemu-system-x86_64 -kernel $(KERNEL) -serial stdio -no-reboot -no-shutdown -d int,cpu_reset

# Clean build artifacts
clean:
	rm -f $(KERNEL) $(OBJ) *.bin

# Check if glc is available
check:
	@which $(GLC) > /dev/null || (echo "Error: glc not found in PATH" && exit 1)
	@echo "glc found: $$(which $(GLC))"

.PHONY: all run debug clean check
