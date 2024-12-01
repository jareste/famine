%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN	2
%define SYS_CLOSE   3
%define SYS_CHDIR   80
%define SYS_EXIT    60
%define NULL        0

%define BARRA_N     10

;debug
section .data
    hello db 'Hello, World!', BARRA_N, NULL
    newline db  BARRA_N, NULL
;debug

section .text
    global _start

_start:
    mov r14, [rsp + 8] ; argv0
	push rdx
	push rsp
	sub rsp, 6900 ; by substracting 6900 from rsp, we can access the 6900 bytes before the stack pointer (malloc but on stack)
	mov r15, rsp ; r15 = malloc(6900)
	mov byte [r15 + 69], NULL ; r15[69] = 0 (we must go somewhere to start the program)

    lea rdi, [rel folder1] ; rdi = "/tmp/test"
    call open_dir ; change directory to "/tmp/test"

    call getdents

    call hello_world  ; print "Hello, World!"

    call restore_stack ; exit

open_dir:
    mov rax, SYS_OPEN ; syscall number for sys_open
    mov rsi, 0 ; O_RDONLY
    syscall ; invoke operating system to open directory
    test rax, rax ; check for error
    js safe_exit ; if error, exit
    ret

getdents:
    mov rdi, rax ; save file descriptor
    mov rax, 217 ; syscall number for sys_getdents64
    lea rsi, [r15 + 400] ; buffer to store directory entries
    mov rdx, 4096 ; size of buffer
    syscall ; invoke operating system to read directory entries
    test rax, rax ; check for error
    js safe_exit ; if error, exit

    mov qword [r15 + 350], rax ; save number of bytes read
    mov rax, SYS_CLOSE ; syscall number for sys_close
    syscall ; invoke operating system to close directory

    ret


; if code arrives here it's a segfault 100%
foo: ;find the string when doing strings on the binary
    db "Que me quedo sin comer by gemitareste", NULL

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

new_line:
    mov rax, 1 ; syscall number for sys_write
    mov rdi, 1 ; file descriptor 1 is stdout
    lea rsi, [rel newline] ; address of string to output
    mov rdx, 1 ; number of bytes
    syscall ; invoke operating system to do the write
    ret

restore_stack:
    pop rsp ; restore the stack pointer
    pop rdx ; restore rdx

safe_exit:
    mov rax, SYS_EXIT ; syscall number for sys_exit
    xor rdi, rdi ; exit code 0
    syscall ; invoke operating system to exit


folder1 db "/tmp/test", NULL
folder2 db "/tmp/test2", NULL

signature db "Famine project coded by gemitareste", NULL