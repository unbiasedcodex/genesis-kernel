; Genesis Kernel Boot Stub (ELF64)
; Multiboot1 + 32-to-64 bit transition

bits 32

; ============================================================
; Multiboot Constants
; ============================================================

MBOOT_MAGIC         equ 0x1BADB002
MBOOT_ALIGN         equ 1 << 0
MBOOT_MEMINFO       equ 1 << 1
MBOOT_FLAGS         equ MBOOT_ALIGN | MBOOT_MEMINFO
MBOOT_CHECKSUM      equ -(MBOOT_MAGIC + MBOOT_FLAGS)

; Paging
PAGE_PRESENT        equ 1 << 0
PAGE_WRITE          equ 1 << 1
PAGE_HUGE           equ 1 << 7

; ============================================================
; Multiboot Header
; ============================================================

section .multiboot
align 4
    dd MBOOT_MAGIC
    dd MBOOT_FLAGS
    dd MBOOT_CHECKSUM

; ============================================================
; Data
; ============================================================

section .data

align 16
gdt64:
    dq 0                        ; Null
    dq 0x00AF9A000000FFFF       ; Code64
    dq 0x00CF92000000FFFF       ; Data
gdt64_ptr:
    dw $ - gdt64 - 1
    dd gdt64

; ============================================================
; BSS
; ============================================================

section .bss
align 4096

pml4:   resb 4096
pdpt:   resb 4096
pd:     resb 4096

align 16
stack_bottom:
    resb 65536
stack_top:


; ============================================================
; 32-bit Entry Point
; ============================================================

section .text
global _start_asm
extern _start

_start_asm:
    cli

    ; Save Multiboot info pointer (ebx) to fixed memory address
    ; Multiboot: eax = magic (0x2BADB002), ebx = multiboot_info*
    ; Store at 0x500 (safe low memory location) for kernel to read
    mov dword [0x500], ebx

    mov esp, stack_top

    ; Debug: write '32' to VGA to confirm we started
    mov edi, 0xB8000
    mov word [edi], 0x0233      ; '3' green
    mov word [edi+2], 0x0232    ; '2' green

    ; Debug: write 'B' to serial port (COM1 = 0x3F8)
    mov dx, 0x3F8
    mov al, 'B'
    out dx, al
    mov al, 'O'
    out dx, al
    mov al, 'O'
    out dx, al
    mov al, 'T'
    out dx, al
    mov al, 10
    out dx, al

    ; Clear page tables (use edi for rep stosd)
    mov edi, pml4
    xor eax, eax
    mov ecx, 3072
    rep stosd

    ; Get base addresses into registers
    mov ebx, pml4
    mov ecx, pdpt
    mov edx, pd

    ; PML4[0] -> PDPT
    mov eax, ecx
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov [ebx], eax

    ; PDPT[0] -> PD
    mov eax, edx
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov [ecx], eax

    ; PD[0..3] -> 4x 2MB pages (first 8MB identity mapped)
    mov dword [edx +  0], 0x000000 | PAGE_PRESENT | PAGE_WRITE | PAGE_HUGE
    mov dword [edx +  8], 0x200000 | PAGE_PRESENT | PAGE_WRITE | PAGE_HUGE
    mov dword [edx + 16], 0x400000 | PAGE_PRESENT | PAGE_WRITE | PAGE_HUGE
    mov dword [edx + 24], 0x600000 | PAGE_PRESENT | PAGE_WRITE | PAGE_HUGE

    ; Load CR3 with PML4 address
    mov eax, ebx
    mov cr3, eax

    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Enable Long Mode
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable Paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ; Load GDT64 (use register to avoid RIP-relative addressing)
    mov eax, gdt64_ptr
    lgdt [eax]

    ; Jump to 64-bit code (far jump with absolute address)
    push dword 0x08         ; Code segment selector
    push dword realm64      ; 64-bit entry address
    retf                    ; Far return acts as far jump

; ============================================================
; 64-bit Entry
; ============================================================

bits 64

realm64:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rsp, stack_top

    ; Debug: write 'OK 64' to VGA to confirm 64-bit mode works
    mov rax, 0xB8000
    mov word [rax], 0x0F4F      ; 'O' white on black
    mov word [rax+2], 0x0F4B    ; 'K' white on black
    mov word [rax+4], 0x0F20    ; ' ' white on black
    mov word [rax+6], 0x0F36    ; '6' white on black
    mov word [rax+8], 0x0F34    ; '4' white on black

    ; Debug: write '64\n' to serial to confirm 64-bit mode
    mov dx, 0x3F8
    mov al, '6'
    out dx, al
    mov al, '4'
    out dx, al
    mov al, 10
    out dx, al

    ; Multiboot info pointer is stored at 0x500 for kernel to read
    ; No parameters needed - kernel reads from fixed address
    call _start

.halt:
    cli
    hlt
    jmp .halt

section .note.GNU-stack noalloc noexec nowrite progbits
