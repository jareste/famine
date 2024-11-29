;debug
section .data
    hello db 'Hello, World!', 10, 0
;debug

section .text
    global _start

_start:
    mov r14, [rsp + 8] ; argv0
	push rdx
	push rsp
	sub rsp, 6900 ; by substracting 6900 from rsp, we can access the 6900 bytes before the stack pointer (malloc but on stack)
	mov r15, rsp ; r15 = malloc(6900)
	mov byte [r15 + 69], 0 ; r15[69] = 0 (we must go somewhere to start the program)


; chdir
    call set_dir ; set the directory to /tmp/test
    chdir:
        pop rdi ; rdi = "/tmp/test"
        mov rax, 80 ; syscall number for sys_chdir
        syscall ; invoke operating system to change directory
    test rax, rax ; test if rax is zero 
    js restore_stack ; if syscall is not zero exit
; chdir

    call hello_world  ; print "Hello, World!"

    call restore_stack ; exit

foo: ;find the string when doing strings on the binary
    db "Que me quedo sin comer by gemitareste", 0

set_dir:
    call chdir ; change directory to /tmp/test
    db "/tmp/test", 0 ; next instruction to exec, so it's stack-top

;debug
hello_world:
; PRINT
    mov rax, 1 ; syscall number for sys_write
    mov rdi, 1 ; file descriptor 1 is stdout
    lea rsi, [rel hello] ; address of string to output
    mov rdx, 14 ; number of bytes
    syscall ; invoke operating system to do the write
    ret
; PRINT
;debug

restore_stack:
    pop rsp ; restore the stack pointer
    pop rdx ; restore rdx

safe_exit:
    mov rax, 60 ; syscall number for sys_exit
    xor rdi, rdi ; exit code 0
    syscall ; invoke operating system to exit
