# Genesis Kernel Makefile

# Tools
GLC = glc
LD = ld

# Flags
GLCFLAGS = --freestanding --emit-obj
LDFLAGS = -T linker/kernel.ld --nostdlib -e _start

# Output
KERNEL = kernel.elf
OBJ_KERNEL = kernel.o

# Source files
SRC = src/main.gl

# Default target
all: $(KERNEL)

# Build kernel
$(KERNEL): $(OBJ_KERNEL) linker/kernel.ld
	$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJ_KERNEL)

# Compile Genesis code
$(OBJ_KERNEL): $(SRC)
	$(GLC) build $(SRC) $(GLCFLAGS) -o $(OBJ_KERNEL)

# Clean build artifacts
clean:
	rm -f $(KERNEL) $(OBJ_KERNEL)

# Check if tools are available
check:
	@which $(GLC) > /dev/null || (echo "Error: glc not found in PATH" && exit 1)
	@echo "glc found: $$(which $(GLC))"

.PHONY: all clean check
