input:
    mov di, buffer      ; DI = Buffer
.loop:
    mov ah, 0x00
    int 0x16            ; AL = CHAR

    cmp al, 13          ; ENTER
    je .done

    cmp al, 8           ; BACKSPACE
    je .backspace

    mov bx, di          ; BX = DI (POINTER)
    mov [bx], al        ; Write the CHAR in Memory
    inc di              ; di += 1 (Next CHARS)

    ; Screen Echo
    mov ah, 0x0E
    int 0x10
    jmp .loop
.backspace:
    cmp di, buffer
    je .loop
    dec di
    mov byte [di], 0

    mov ah, 0x0E
    mov al, 8
    int 0x10      ; Move the cursor to left (VIDEO INTERRUPT)

    mov al, ' '
    int 0x10      ; Delete with SPACE

    mov al, 8
    int 0x10      ; Move the cursor to left (VIDEO INTERRUPT)
    jmp .loop
.done:
    mov byte [di], 0 

    mov ah, 0x0E
    mov al, 13
    int 0x10      ; Carriage Return
    mov al, 10
    int 0x10      ; Line Feed

    mov dl, 3
    inc dh
    call set_cursor_position

    mov si, buffer
    call check_commands
.finish:
    mov di, buffer
    call clear_buffer

    call clear_buffer

    ret

clear_buffer:
    mov al, 0
    mov cx, 32 ; Buffer's Length
    rep stosb
    ret