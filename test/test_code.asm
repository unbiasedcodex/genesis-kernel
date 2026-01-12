; Minimal test code for Genesis OS ELF loader
; Prints "ELF!" using syscalls and loops
; Will be linked into a proper ELF

BITS 64

; Syscall numbers (same as kernel)
SYS_YIELD  equ 0
SYS_PRINT  equ 2

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
