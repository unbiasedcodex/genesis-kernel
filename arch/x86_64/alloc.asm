; Genesis Kernel - Simple Bump Allocator
; Provides malloc/free symbols for compiler-generated struct allocations

bits 64

; Mark stack as non-executable
section .note.GNU-stack noalloc noexec nowrite progbits

section .data

; Heap pointer (simple bump allocator)
align 8
heap_ptr: dq 0x650000       ; Start of kernel heap (KERNEL_HEAP_BASE)

; Heap limits
HEAP_BASE equ 0x650000
HEAP_END  equ 0x660000      ; 64KB heap

section .text

; malloc(size) -> ptr
; Input: rdi = size in bytes
; Output: rax = pointer to allocated memory, or 0 if out of memory
global malloc
malloc:
    push rbx

    ; Load current heap pointer
    mov rax, [rel heap_ptr]

    ; Align to 8 bytes: (ptr + 7) & ~7
    add rax, 7
    and rax, ~7

    ; Calculate new pointer
    mov rbx, rax
    add rbx, rdi            ; new_ptr = aligned + size

    ; Check bounds
    cmp rbx, HEAP_END
    ja .out_of_memory

    ; Store new heap pointer
    mov [rel heap_ptr], rbx

    ; Return aligned pointer
    pop rbx
    ret

.out_of_memory:
    xor eax, eax            ; Return NULL
    pop rbx
    ret

; free(ptr)
; Input: rdi = pointer to free
; No-op for bump allocator
global free
free:
    ret
