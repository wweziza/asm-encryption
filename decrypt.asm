section .data
    prompt db "Enter the file name to decrypt: ", 0
    prompt_len equ $ - prompt
    key db "thishouldbeuniqueasduckduckpook"  ; Same XOR key for decryption
    error_open db "Error: Unable to open file", 10, 0
    error_open_len equ $ - error_open
    error_read db "Error: Unable to read file", 10, 0
    error_read_len equ $ - error_read
    error_write db "Error: Unable to write file", 10, 0
    error_write_len equ $ - error_write

section .bss
    filename resb 256
    file_buffer resb 1048576  ; 1MB buffer for file content
    file_size resd 1
    file_descriptor resd 1    ; Space for file descriptor

section .text
global _start

_start:
    ; Display prompt and get filename
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

    ; Open encrypted file
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

    ; Decrypt file content using XOR
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

    ; Open output file (remove ".enc" from filename if present)
    mov esi, filename
    call remove_enc
    mov eax, 5
    mov ebx, filename
    mov ecx, 0x42  ; O_WRONLY | O_CREAT | O_TRUNC
    mov edx, 0644  ; Permissions
    int 0x80
    test eax, eax
    js file_open_error
    mov [file_descriptor], eax

    ; Write decrypted content
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

remove_enc:
    mov edi, esi             ; EDI points to the filename
    mov ecx, 256             ; Set a counter for the filename length
.find_end:
    mov al, [edi]            ; Load the current character
    cmp al, 0                ; Check if it's the null terminator
    je .check_enc            ; If yes, jump to check for ".enc"
    inc edi                  ; Move to the next character
    dec ecx                  ; Decrease the counter
    jnz .find_end            ; Repeat until end of string or counter is exhausted

.check_enc:
    sub edi, 4               ; Move back four characters to check for ".enc"
    mov ecx, edi             ; Save the position to restore if no match
    mov eax, [edi]           ; Load the last four bytes of the filename
    cmp eax, 0x636e652e      ; Compare with ".enc" (".enc" in reverse order because of little-endian)
    jne .no_enc              ; If not equal, jump to no_enc
    mov byte [edi], 0        ; If ".enc" found, remove it by setting null terminator
    ret

.no_enc:
    mov edi, ecx             ; Restore the original position
    ret                      ; Return without modifying the filename
