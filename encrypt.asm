section .data
welcome db "Welcome to brainducking - encryption", 10, 0
welcome_len equ $ - welcome
prompt db "Enter the file name to encrypt: ", 0
prompt_len equ $ - prompt
key db "thishouldbeuniqueasduckduckpook" ; Simple XOR key
error_open db "Error: Unable to open file", 10, 0
error_open_len equ $ - error_open
error_read db "Error: Unable to read file", 10, 0
error_read_len equ $ - error_read
error_write db "Error: Unable to write file", 10, 0
error_write_len equ $ - error_write

section .bss
filename resb 256
file_buffer resb 1048576 ; 1MB buffer for file content
file_size resd 1
file_descriptor resd 1 ; Space for file descriptor

section .text
global _start

_start:

mov eax, 4
mov ebx, 1
mov ecx, welcome
mov edx, welcome_len
int 0x80

mov eax, 4
mov ebx, 1
mov ecx, prompt
mov edx, prompt_len
int 0x80

mov eax, 3
mov ebx, 0
mov ecx, filename
mov edx, 256
int 0x80

; Remove newline from filename
mov esi, filename
call remove_newline

; Open file for reading
mov eax, 5
mov ebx, filename
mov ecx, 0  ; O_RDONLY
int 0x80
test eax, eax
js file_open_error
mov [file_descriptor], eax

; Read file content
mov eax, 3
mov ebx, [file_descriptor]
mov ecx, file_buffer
mov edx, 1048576
int 0x80
test eax, eax
js file_read_error
mov [file_size], eax

; Close input file
mov eax, 6
mov ebx, [file_descriptor]
int 0x80

; Encrypt file content using XOR
mov esi, file_buffer
xor ecx, ecx
mov ecx, [file_size]
mov edi, key
xor_loop:
    mov al, [esi]
    xor al, [edi]
    mov [esi], al
    inc esi
    inc edi
    cmp byte [edi], 0
    jnz xor_loop
    loop xor_loop

; Re-open the same file for writing (overwriting the original content)
mov eax, 5
mov ebx, filename
mov ecx, 0x42  ; O_WRONLY | O_CREAT | O_TRUNC
mov edx, 0644  ; Permissions
int 0x80
test eax, eax
js file_open_error
mov [file_descriptor], eax

; Write encrypted content
mov eax, 4
mov ebx, [file_descriptor]
mov ecx, file_buffer
mov edx, [file_size]
int 0x80
test eax, eax
js file_write_error

; Close output file
mov eax, 6
mov ebx, [file_descriptor]
int 0x80

; Exit program
mov eax, 1
xor ebx, ebx
int 0x80

file_open_error:
mov eax, 4
mov ebx, 1
mov ecx, error_open
mov edx, error_open_len
int 0x80
jmp exit_program

file_read_error:
mov eax, 4
mov ebx, 1
mov ecx, error_read
mov edx, error_read_len
int 0x80
jmp exit_program

file_write_error:
mov eax, 4
mov ebx, 1
mov ecx, error_write
mov edx, error_write_len
int 0x80

exit_program:
mov eax, 1
mov ebx, 0
int 0x80

remove_newline:
mov ecx, 256
.loop:
mov al, [esi]
cmp al, 10
je .found
inc esi
dec ecx
jnz .loop
ret
.found:
mov byte [esi], 0
ret
