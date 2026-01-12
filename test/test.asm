; Minimal test ELF program for Genesis OS
; Prints "ELF!" using syscalls and loops
; This will be embedded in RAMFS for testing the ELF loader

BITS 64

; Syscall numbers (same as kernel)
SYS_YIELD  equ 0
SYS_PRINT  equ 2

; ELF header
elf_header:
    db 0x7F, "ELF"           ; Magic
    db 2                      ; 64-bit
    db 1                      ; Little endian
    db 1                      ; ELF version
    db 0                      ; OS/ABI (System V)
    times 8 db 0              ; Padding
    dw 2                      ; Type: Executable
    dw 0x3E                   ; Machine: x86-64
    dd 1                      ; Version
    dq _start                 ; Entry point
    dq program_headers - elf_header  ; Program header offset
    dq 0                      ; Section header offset
    dd 0                      ; Flags
    dw elf_header_end - elf_header  ; ELF header size
    dw program_header_size    ; Program header entry size
    dw 1                      ; Number of program headers
    dw 0                      ; Section header entry size
    dw 0                      ; Number of section headers
    dw 0                      ; Section name string table index
elf_header_end:

; Program headers
program_headers:
    dd 1                      ; Type: PT_LOAD
    dd 5                      ; Flags: PF_R | PF_X
    dq 0                      ; Offset in file
    dq 0x800000               ; Virtual address (ELF_LOAD_BASE)
    dq 0x800000               ; Physical address
    dq file_end               ; Size in file
    dq file_end               ; Size in memory
    dq 0x1000                 ; Alignment
program_header_size equ $ - program_headers

; Code section
section .text
global _start

_start:
    ; Print 'E'
    mov rax, SYS_PRINT
    mov rdi, 'E'
    int 0x80

    ; Print 'L'
    mov rax, SYS_PRINT
    mov rdi, 'L'
    int 0x80

    ; Print 'F'
    mov rax, SYS_PRINT
    mov rdi, 'F'
    int 0x80

    ; Print '!'
    mov rax, SYS_PRINT
    mov rdi, '!'
    int 0x80

    ; Print newline
    mov rax, SYS_PRINT
    mov rdi, 10
    int 0x80

.loop:
    ; Yield and loop forever
    mov rax, SYS_YIELD
    int 0x80
    jmp .loop

file_end:
