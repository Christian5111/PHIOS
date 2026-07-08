BITS 16

get_cursor_position:
    mov ah, 0x03
    mov bh, 0
    int 0x10

    ret

set_cursor_position:
    mov ah, 0x02 ; Set cursor position
    mov bh, 0x00 ; Video Page
    int 0x10
    ret

print_string:
    pusha

    mov bh, 0x00 ; Video Page

    mov al, [background_color]
    shl al, 4
    or al, [color]

    mov bl, al
.next:
    lodsb ; Load the SI character in AL
    test al, al ; Check for the final string token (0)
    jz .done

    ; Print the Character
    mov ah, 0x09 ; Write Character and Attribute
    mov cx, 1 ; Times of printing characters
    int 0x10

    ; Move the cursor
    inc dl ; dl+=1
    call set_cursor_position ; Update cursor position

    jmp .next
.done:
    popa
    ret

    get_centered_x_offset:
    push si
    call str_len
    pop si
    
    mov ax, [columns]
    shr ax, 1
    
    mov bx, cx
    shr bx, 1
    
    sub ax, bx
    mov dl, al
    ret

set_center_x:
    xor dx, dx
    mov ax, [columns]
    mov bx, 2
    div bx

    mov dl, al
    ret

set_center_string:
    push si
    call str_len
    pop si

    xor dx, dx
    mov ax, cx
    mov bx, 2
    div bx

    sub dl, al
    ret

return_screen_dimension:
    ; Columns
    mov ah, 0x0F
    int 0x10
    movzx ax, ah ; AH extended in AX
    mov [columns], ax

    ; Rows
    mov ax, 0x1130
    mov bh, 0
    int 0x10
    mov al, dl ; DL = Rows - 1
    inc al ; AL = DL + 1 (Rows)
    mov [rows], ax

    ret

clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

; AL = Number of Rows
scroll_up:
    mov ah, 0x06
    mov bh, 0x07

    int 10h
    ret