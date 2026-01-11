; Genesis Kernel - Interrupt Service Routines
; x86_64 ISR stubs

bits 64

; ============================================================
; External handler (defined in Genesis Lang)
; ============================================================

extern isr_handler

; ============================================================
; Macro for ISRs without error code
; ============================================================

%macro ISR_NOERRCODE 1
global isr%1
isr%1:
    push qword 0                ; Dummy error code
    push qword %1               ; Interrupt number
    jmp isr_common
%endmacro

; ============================================================
; Macro for ISRs with error code (CPU pushes it)
; ============================================================

%macro ISR_ERRCODE 1
global isr%1
isr%1:
    push qword %1               ; Interrupt number (error code already on stack)
    jmp isr_common
%endmacro

; ============================================================
; Macro for IRQs (hardware interrupts)
; ============================================================

%macro IRQ 2
global irq%1
irq%1:
    push qword 0                ; Dummy error code
    push qword %2               ; Interrupt number (32 + IRQ#)
    jmp isr_common
%endmacro

; ============================================================
; Exception handlers (0-31)
; ============================================================

; CPU exceptions
ISR_NOERRCODE 0     ; Divide by zero
ISR_NOERRCODE 1     ; Debug
ISR_NOERRCODE 2     ; NMI
ISR_NOERRCODE 3     ; Breakpoint
ISR_NOERRCODE 4     ; Overflow
ISR_NOERRCODE 5     ; Bound range exceeded
ISR_NOERRCODE 6     ; Invalid opcode
ISR_NOERRCODE 7     ; Device not available
ISR_ERRCODE   8     ; Double fault
ISR_NOERRCODE 9     ; Coprocessor segment overrun (legacy)
ISR_ERRCODE   10    ; Invalid TSS
ISR_ERRCODE   11    ; Segment not present
ISR_ERRCODE   12    ; Stack segment fault
ISR_ERRCODE   13    ; General protection fault
ISR_ERRCODE   14    ; Page fault
ISR_NOERRCODE 15    ; Reserved
ISR_NOERRCODE 16    ; x87 FPU error
ISR_ERRCODE   17    ; Alignment check
ISR_NOERRCODE 18    ; Machine check
ISR_NOERRCODE 19    ; SIMD floating point
ISR_NOERRCODE 20    ; Virtualization
ISR_ERRCODE   21    ; Control protection
ISR_NOERRCODE 22    ; Reserved
ISR_NOERRCODE 23    ; Reserved
ISR_NOERRCODE 24    ; Reserved
ISR_NOERRCODE 25    ; Reserved
ISR_NOERRCODE 26    ; Reserved
ISR_NOERRCODE 27    ; Reserved
ISR_NOERRCODE 28    ; Reserved
ISR_NOERRCODE 29    ; Reserved
ISR_ERRCODE   30    ; Security exception
ISR_NOERRCODE 31    ; Reserved

; ============================================================
; Hardware IRQs (remapped to 32-47)
; ============================================================

IRQ 0, 32           ; PIT timer
IRQ 1, 33           ; Keyboard
IRQ 2, 34           ; Cascade
IRQ 3, 35           ; COM2
IRQ 4, 36           ; COM1
IRQ 5, 37           ; LPT2
IRQ 6, 38           ; Floppy
IRQ 7, 39           ; LPT1 / spurious
IRQ 8, 40           ; RTC
IRQ 9, 41           ; Free
IRQ 10, 42          ; Free
IRQ 11, 43          ; Free
IRQ 12, 44          ; PS/2 mouse
IRQ 13, 45          ; FPU
IRQ 14, 46          ; Primary ATA
IRQ 15, 47          ; Secondary ATA

; ============================================================
; Common ISR handler
; Saves all registers, calls C handler, restores and returns
; ============================================================

isr_common:
    ; Save all general-purpose registers
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    ; Save segment registers (as 64-bit for alignment)
    mov rax, ds
    push rax

    ; Load kernel data segment
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Call Genesis handler with pointer to stack frame
    ; Stack layout at this point (from RSP):
    ;   [RSP+0]   = saved DS
    ;   [RSP+8]   = r15
    ;   ...
    ;   [RSP+120] = rax
    ;   [RSP+128] = interrupt number
    ;   [RSP+136] = error code
    ;   [RSP+144] = RIP (pushed by CPU)
    ;   [RSP+152] = CS
    ;   [RSP+160] = RFLAGS
    ;   [RSP+168] = RSP
    ;   [RSP+176] = SS
    mov rdi, rsp            ; First argument: pointer to interrupt frame
    call isr_handler

    ; Check if context switch is needed by reading SWITCH_RSP_ADDR (0x422010)
    mov rax, [0x422010]
    test rax, rax
    jz .no_switch

    ; Context switch: use new RSP from memory
    mov rsp, rax

.no_switch:
    ; Restore segment registers
    pop rax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Restore general-purpose registers
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    ; Remove interrupt number and error code
    add rsp, 16

    ; Return from interrupt
    iretq

; ============================================================
; ISR stub table for IDT setup
; ============================================================

section .data
global isr_stub_table
isr_stub_table:
    dq isr0, isr1, isr2, isr3, isr4, isr5, isr6, isr7
    dq isr8, isr9, isr10, isr11, isr12, isr13, isr14, isr15
    dq isr16, isr17, isr18, isr19, isr20, isr21, isr22, isr23
    dq isr24, isr25, isr26, isr27, isr28, isr29, isr30, isr31
    dq irq0, irq1, irq2, irq3, irq4, irq5, irq6, irq7
    dq irq8, irq9, irq10, irq11, irq12, irq13, irq14, irq15

section .note.GNU-stack noalloc noexec nowrite progbits
