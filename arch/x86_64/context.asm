; Genesis Kernel - Context Switch
; x86_64 context switching for process scheduler

bits 64

section .text

; ============================================================
; context_switch - Switch from current to next process
;
; Called from timer interrupt handler AFTER registers are saved.
; The ISR has already pushed all registers to the current stack.
;
; Arguments:
;   rdi = pointer to current process RSP storage (to save)
;   rsi = new RSP value to load (next process stack)
;
; This function:
;   1. Saves current RSP to [rdi]
;   2. Loads RSP from rsi
;   3. Returns (to the new process context)
; ============================================================

global asm_context_switch
asm_context_switch:
    ; Save current RSP to the current process PCB
    mov [rdi], rsp

    ; Load new RSP from next process
    mov rsp, rsi

    ; Return - will return into the new process context
    ; The ISR common handler will restore registers and iretq
    ret

; ============================================================
; init_process_stack_kernel - Initialize a KERNEL mode process stack
;
; Sets up a fake interrupt frame so the process can be
; "resumed" by the scheduler as if it was interrupted.
;
; Arguments:
;   rdi = stack top (highest address of stack)
;   rsi = entry point (RIP)
;
; Returns:
;   rax = initial RSP value (to store in PCB)
;
; Stack layout (matching isr_common):
;   [top]
;   SS        = 0x10 (kernel data)
;   RSP       = stack_top - 8 (return address slot)
;   RFLAGS    = 0x202 (IF=1, reserved=1)
;   CS        = 0x08 (kernel code)
;   RIP       = entry point
;   error_code = 0
;   int_num    = 0
;   rax..r15   = 0 (all gprs)
;   ds         = 0x10
; ============================================================

global asm_init_stack
asm_init_stack:
    mov rax, rdi            ; Start at stack top

    ; Push SS (kernel data segment)
    sub rax, 8
    mov qword [rax], 0x10

    ; Push RSP (process will use this stack)
    sub rax, 8
    mov rcx, rdi
    sub rcx, 8              ; Slight offset for return address
    mov [rax], rcx

    ; Push RFLAGS (IF=1 to enable interrupts)
    sub rax, 8
    mov qword [rax], 0x202

    ; Push CS (kernel code segment)
    sub rax, 8
    mov qword [rax], 0x08

    ; Push RIP (entry point)
    sub rax, 8
    mov [rax], rsi

    ; Push error code (0)
    sub rax, 8
    mov qword [rax], 0

    ; Push interrupt number (0)
    sub rax, 8
    mov qword [rax], 0

    ; Push all GPRs (16 regs * 8 bytes = 128 bytes)
    ; Order: rax, rbx, rcx, rdx, rsi, rdi, rbp, r8-r15
    mov rcx, 15             ; 15 registers (rax already used)
.push_gpr:
    sub rax, 8
    mov qword [rax], 0
    dec rcx
    jnz .push_gpr

    ; Push one more for rax
    sub rax, 8
    mov qword [rax], 0

    ; Push DS
    sub rax, 8
    mov qword [rax], 0x10

    ; RAX now points to the "saved" stack pointer
    ret

; ============================================================
; init_process_stack_user - Initialize a USER mode process stack
;
; Sets up a fake interrupt frame for RING 3 process.
; The process will start in user mode after IRETQ.
;
; Arguments:
;   rdi = user stack top (ring 3 stack)
;   rsi = entry point (RIP)
;
; Returns:
;   rax = initial RSP value (to store in PCB)
;
; Stack layout (matching isr_common):
;   [top]
;   SS        = 0x23 (user data, RPL=3)
;   RSP       = user_stack_top - 8
;   RFLAGS    = 0x202 (IF=1)
;   CS        = 0x1B (user code, RPL=3)
;   RIP       = entry point
;   error_code = 0
;   int_num    = 0
;   rax..r15   = 0
;   ds         = 0x23 (user data)
; ============================================================

global asm_init_stack_user
asm_init_stack_user:
    mov rax, rdi            ; Start at stack top

    ; Push SS (user data segment, RPL=3)
    sub rax, 8
    mov qword [rax], 0x23

    ; Push RSP (user stack pointer)
    sub rax, 8
    mov rcx, rdi
    sub rcx, 8
    mov [rax], rcx

    ; Push RFLAGS (IF=1 to enable interrupts)
    sub rax, 8
    mov qword [rax], 0x202

    ; Push CS (user code segment, RPL=3)
    sub rax, 8
    mov qword [rax], 0x1B

    ; Push RIP (entry point)
    sub rax, 8
    mov [rax], rsi

    ; Push error code (0)
    sub rax, 8
    mov qword [rax], 0

    ; Push interrupt number (0)
    sub rax, 8
    mov qword [rax], 0

    ; Push all GPRs (15 registers)
    mov rcx, 15
.push_gpr_user:
    sub rax, 8
    mov qword [rax], 0
    dec rcx
    jnz .push_gpr_user

    ; Push one more for rax
    sub rax, 8
    mov qword [rax], 0

    ; Push DS (user data segment)
    sub rax, 8
    mov qword [rax], 0x23

    ; RAX now points to the "saved" stack pointer
    ret

; ============================================================
; get_rsp - Get current RSP value
; Returns: rax = current RSP
; ============================================================

global get_rsp
get_rsp:
    mov rax, rsp
    ret

; ============================================================
; tss_set_rsp0 - Set RSP0 in TSS (kernel stack for ring transitions)
;
; Arguments:
;   rdi = TSS base address
;   rsi = RSP0 value (kernel stack pointer)
;
; TSS RSP0 is at offset 0x04 (4 bytes from start)
; ============================================================

global tss_set_rsp0
tss_set_rsp0:
    mov [rdi + 4], rsi      ; TSS.RSP0 is at offset 4
    ret

; ============================================================
; tss_load - Load Task Register with TSS selector
;
; Arguments:
;   rdi = TSS selector (e.g., 0x28)
; ============================================================

global tss_load
tss_load:
    mov ax, di
    ltr ax
    ret

; ============================================================
; gdt_reload - Reload GDT with 64-bit pointer
;
; Arguments:
;   rdi = pointer to GDTR structure (10 bytes: limit + base)
; ============================================================

global gdt_reload
gdt_reload:
    lgdt [rdi]
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
