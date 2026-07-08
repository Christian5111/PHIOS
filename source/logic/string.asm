pointer dw 0
pointer_2 dw 0

compare_string:
; SI = Pointer of the String A
; DI = Pointer of the String B
.loop:
    lodsb ; Load the character from SI in AL (Char A)
    mov bl, [di] ; Load the character from DI in BL (Char B)
    inc di

    cmp al, bl ; Character Comparison (al-bl)
    je .check_char

    cmp al, ' '         
    jne .not_equal      ; AL isn't a space => NOT EQUAL
    test bl, bl
    jz .equal           ; AL is a space and BL end token (\0) => EQUAL
.check_char:
    test al, al ; End String (\0)
    jz .equal

    cmp al, ' ' ; Space Check
    jne .loop
.not_equal:
    ; Not Equal (ZF=0)
    mov al, 1
    test al, al

    ret
.equal:
    ; Equal (ZF=1)
    xor ax, ax
    ret

str_len:
    xor cx, cx
    push si
.next:
    lodsb ; Load [si] in AL and increment SI
    cmp al, 0
    je .done

    inc cx
    jmp .next
.done:
    pop si
    ret

check_command:
    mov si, buffer
    mov al, [si]

    cmp al, ' '
    je .not_equal

    test al, al
    jz .not_equal

    call compare_string
    jne .not_equal

    ; Equal
    dec si
    mov [pointer], si
    xor ax, ax ; Set ZF=1
    ret
.not_equal:
    mov al, 1
    test al, al ; Set ZF=0
    ret

get_next_argument:
    mov si, [pointer]
.next_char:
    mov al, [si]

    cmp al, ' '
    je .done

    inc si
    jmp .next_char
.done:
    inc si
    mov [pointer], si
    ret