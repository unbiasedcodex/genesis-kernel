/* Genesis Kernel Linker Script
 * ELF64 format with 32-bit boot entry
 */

OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start_asm)

SECTIONS {
    /* Load at 1MB */
    . = 1M;

    /* Multiboot header - must be in first 8KB */
    .multiboot BLOCK(4K) : ALIGN(4K) {
        *(.multiboot)
    }

    /* 32-bit boot code */
    .text.boot BLOCK(4K) : ALIGN(4K) {
        *(.text.boot)
    }

    /* 64-bit code */
    .text BLOCK(4K) : ALIGN(4K) {
        *(.text .text.*)
    }

    /* Read-only data (GDT, etc) */
    .rodata BLOCK(4K) : ALIGN(4K) {
        *(.rodata .rodata.*)
    }

    /* Initialized data */
    .data BLOCK(4K) : ALIGN(4K) {
        *(.data .data.*)
    }

    /* Uninitialized data */
    .bss BLOCK(4K) : ALIGN(4K) {
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        __bss_end = .;
    }

    __kernel_end = .;

    /DISCARD/ : {
        *(.comment)
        *(.note.gnu.property)
        *(.eh_frame*)
    }
}
