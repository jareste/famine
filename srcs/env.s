section .data
    newline db 10, 0
    famine_str db 'famine=', 0

section .text
global _start

_start:
    mov rbx, rsp
    mov rax, [rbx]
    add rbx, 8

.skip_argv:
    mov rax, [rbx]
    test rax, rax
    je .after_argv
    add rbx, 8
    jmp .skip_argv

.after_argv:
    add rbx, 8

.find_famine:
    mov rsi, [rbx]
    test rsi, rsi
    je .exit

    lea rdi, [rel famine_str]
    call ft_strncmp
    test rax, rax
    je .print_famine_value

    add rbx, 8
    jmp .find_famine

.print_famine_value:
    call print_string
    jmp .exit

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

ft_strncmp:
    mov rcx, 7
    repe cmpsb
    mov rax, rcx
    ret

print_string:
    call strlen
    mov rdi, 1
    mov rdx, rax
    mov rax, 1
    syscall
    ret

print_newline:
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel newline]
    mov rdx, 1
    syscall
    ret

strlen:
    xor rcx, rcx
    not rcx
    xor al, al
    mov rdi, rsi
    repne scasb
    not rcx
    dec rcx
    mov rax, rcx
    ret
