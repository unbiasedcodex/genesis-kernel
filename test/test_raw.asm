; Minimal self-contained ELF64 executable
; Code immediately follows headers for minimal size
; Entry point: 0x800078 (right after headers)

BITS 64
org 0x800000

; Syscall numbers
SYS_YIELD  equ 0
SYS_PRINT  equ 2

; ELF64 Header (64 bytes)
ehdr:
    db 0x7F, "ELF"           ; e_ident[0..3]: Magic
    db 2                      ; e_ident[4]: Class = 64-bit
    db 1                      ; e_ident[5]: Data = Little endian
    db 1                      ; e_ident[6]: Version
    db 0                      ; e_ident[7]: OS/ABI
    times 8 db 0              ; e_ident[8..15]: Padding
    dw 2                      ; e_type: Executable
    dw 0x3E                   ; e_machine: x86-64
    dd 1                      ; e_version
    dq _start                 ; e_entry: Entry point
    dq phdr - ehdr            ; e_phoff: Program header offset (64)
    dq 0                      ; e_shoff: Section header offset (none)
    dd 0                      ; e_flags
    dw ehdr_size              ; e_ehsize: ELF header size
    dw phdr_size              ; e_phentsize: Program header entry size
    dw 1                      ; e_phnum: Number of program headers
    dw 0                      ; e_shentsize: Section header entry size
    dw 0                      ; e_shnum: Number of section headers
    dw 0                      ; e_shstrndx: Section name string table index
ehdr_size equ $ - ehdr

; Program Header (56 bytes)
phdr:
    dd 1                      ; p_type: PT_LOAD
    dd 5                      ; p_flags: PF_R | PF_X
    dq 0                      ; p_offset: File offset
    dq 0x800000               ; p_vaddr: Virtual address
    dq 0x800000               ; p_paddr: Physical address
    dq file_size              ; p_filesz: Size in file
    dq file_size              ; p_memsz: Size in memory
    dq 0x1000                 ; p_align: Alignment
phdr_size equ $ - phdr

; Code starts here (0x800078)
_start:
    ; Print 'E' (0x45)
    mov rax, SYS_PRINT
    mov rdi, 0x45
    int 0x80

    ; Print 'L' (0x4C)
    mov rax, SYS_PRINT
    mov rdi, 0x4C
    int 0x80

    ; Print 'F' (0x46)
    mov rax, SYS_PRINT
    mov rdi, 0x46
    int 0x80

    ; Print '!' (0x21)
    mov rax, SYS_PRINT
    mov rdi, 0x21
    int 0x80

    ; Print newline (0x0A)
    mov rax, SYS_PRINT
    mov rdi, 0x0A
    int 0x80

.loop:
    ; Yield
    mov rax, SYS_YIELD
    int 0x80
    jmp .loop

file_size equ $ - ehdr
