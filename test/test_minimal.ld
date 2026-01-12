/* Minimal linker script - no alignment padding */
OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_start)

PHDRS
{
    text PT_LOAD FLAGS(5);  /* R+X */
}

SECTIONS
{
    . = 0x800000;

    .text : AT(ADDR(.text) - 0x800000 + SIZEOF_HEADERS) {
        *(.text)
    } :text

    /DISCARD/ : {
        *(.note*)
        *(.comment*)
        *(.eh_frame*)
    }
}
