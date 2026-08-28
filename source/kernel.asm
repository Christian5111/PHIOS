BITS 16
ORG 0x7E00

jmp start_kernel

; VARIABLES ;
ALIGN 2
rows dw 0
columns dw 0
color db 0
color_data db 0x00
background_color db 0 
current_page dw 0

calculated_color db 0x00
print_color db 0x07
print_background_color db 0x00

; COLORS ;
COLOR_BLACK equ 0x00
COLOR_BLUE equ 0x01
COLOR_GREEN equ 0x02
COLOR_CYAN equ 0x03
COLOR_YELLOW equ 0x0E
COLOR_WHITE equ 0x0F
COLOR_GRAY equ 0x07
COLOR_DARK_GRAY equ 0x08
COLOR_LIGHT_BLUE equ 0X09

ALIGN 2
buffer: times 32 db 0

start_kernel:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax

    call return_screen_dimension
    call clear_screen
    
    jmp start_screen

; PAGES ;
start_screen:
    mov byte [color], COLOR_GRAY
    mov byte [background_color], COLOR_BLACK

    mov dh, 0
    call create_line

    mov ax, [rows]
    dec ax
    mov dh, al
    call create_line

    ; Title
    call print_title

    ; Welcome Text
    mov byte [color], COLOR_GRAY
    mov dh, 10

    mov si, WELCOME
    call get_centered_x_offset

    call set_cursor_position
    call print_string

    mov byte [color], COLOR_DARK_GRAY
    mov dh, 13
    call create_line
    mov dh, 17
    call create_line
    mov byte [color], COLOR_GRAY

    mov dh, 15

    mov si, START
    call get_centered_x_offset

    call set_cursor_position
    mov byte [color], COLOR_CYAN
    call print_string

    mov ah, 0x00
    int 0x16

    call clear_screen
    jmp shell_screen

shell_screen:
    mov ax, SHELL
    mov [current_page], ax
    call top_bar

    mov dh, 2
    mov dl, 3
    call set_cursor_position

    jmp .loop
.loop:
    mov byte [color], 0x07
    call set_cursor_position
    mov si, COMMAND_INPUT
    call print_string

    call input

    add dh, 1
    cmp dh, 23
    jg .reset_screen

    mov dl, 3
    call set_cursor_position

    jmp .loop
.reset_screen:
    mov ax, SHELL
    mov [current_page], ax

    mov al, 5
    call scroll_up

    call top_bar

    sub dh, 5
    mov dl, 3
    jmp .loop

top_bar:
    push dx

    mov byte [color], COLOR_GRAY
    mov dh, 0
    call create_line

    mov byte [color], COLOR_BLACK
    mov byte [background_color], COLOR_GRAY

    mov si, [current_page]
    call get_centered_x_offset
    mov dh, 0
    call set_cursor_position

    call print_string

    mov byte [background_color], COLOR_BLACK

    pop dx
    mov dl, 3
    call set_cursor_position

    ret

editor_screen:
    call clear_screen

    mov ax, EDITOR
    mov [current_page], ax
    call top_bar

    call .create_lines

    mov byte [color], 0x07
    mov dl, 5
    mov dh, 1
    call set_cursor_position

    jmp .editor_loop
.editor_loop:
    call .input

    jmp .editor_loop
.input:
.loop:
    mov ah, 0x00
    int 0x16            ; AL = CHAR

    cmp al, 13          ; ENTER
    je .done

    cmp al, 8           ; BACKSPACE
    je .backspace

    cmp ah, 0x48
    je .move_up

    cmp ah, 0x50
    je .move_down

    cmp ah, 0x4B
    je .move_left

    cmp ah, 0x4D
    je .move_right

    ; Screen Echo
    mov ah, 0x0E
    int 0x10
    jmp .loop
.move_up:
    dec dh
    call set_cursor_position

    jmp .loop
.move_down:
    inc dh
    call set_cursor_position

    jmp .loop
.move_left:
    call get_cursor_position
    cmp dl, 5
    jbe .loop

    dec dl
    call set_cursor_position

    jmp .loop
.move_right:
    jbe .loop

    inc dl
    call set_cursor_position

    jmp .loop
.backspace:
    call get_cursor_position

    cmp dl, 5
    jbe .loop

    mov ah, 0x0E
    mov al, 8
    int 0x10      ; Move the cursor to left (VIDEO INTERRUPT)

    mov al, ' '
    int 0x10      ; Delete with SPACE

    mov al, 8
    int 0x10      ; Move the cursor to left (VIDEO INTERRUPT)
    jmp .loop
.done:
    mov dl, 5
    inc dh
    call set_cursor_position
.finish:
    ret 
.create_lines:
    mov ax, 1

    mov cx, [rows]
    dec cx

    mov dh, 1
    mov dl, 0

    mov byte [color], 0x0A
.iteration:
    push ax
    push cx

    call set_cursor_position

    mov bp, sp
    mov ax, [bp+2]

    call print_numbers

    mov dl, 3
    call set_cursor_position

    mov si, EDITOR_LINE
    call print_string

    mov dl, 0
    call set_cursor_position

    pop cx
    pop ax

    inc ax
    inc dh

    cmp dh, 25
    je .editor_done

    loop .iteration
.editor_done:
    ret

; FUNCTIONS ;
print_numbers:
    pusha

    cmp ax, 0
    je .zero

    mov bx, 10 ; BX = 10
    xor cx, cx ; CX = Number of Digits
.divide_loop:
    xor dx, dx ; DX = 0
    div bx     ; AX = AX / 10, DX = rest

    push dx    ; Save Digit
    inc cx
    
    test ax, ax
    jnz .divide_loop
.print_loop:
    pop ax ; DX = Digit
    add al, '0' ; Convert to ASCII

    push cx
    mov ah, 0x09
    mov bh, 0
    mov bl, [color]
    mov cx, 1
    int 0x10
    pop cx

    push cx
    mov ah, 0x03
    xor bh, bh
    int 0x10
    
    inc dl
    mov ah, 0x02
    int 0x10
    pop cx

    loop .print_loop
    jmp .done
.zero:
    mov al, '0'
    mov ah, 0x09
    mov bh, 0
    mov bl, [color]
    mov cx, 1
    int 0x10
.done:
    popa
    ret

parse_hex_byte:
    mov al, [si]
    call hex_char_to_val
    mov [calculated_color], al
    ret

hex_char_to_val:
    cmp al, '0'
    jl .invalid
    cmp al, '9'
    jle .is_digit
    cmp al, 'A'
    jl .invalid
    cmp al, 'F'
    jle .is_lower
.invalid:
    mov al, 0x07
    ret
.is_digit:
    sub al, '0'
    ret
.is_lower:
    sub al, 'A'
    add al, 10
    ret

check_commands:
    ; Quit Command
    mov di, QUIT_COMMAND
    call check_command
    jz .quit

    ; Clear Command
    mov di, CLEAR_COMMAND
    call check_command
    jz .clear_command

    ; Shutdown Command
    mov di, SHUTDOWN_COMMAND
    call check_command
    jz .shutdown

    ; Print Command
    mov di, PRINT_COMMAND
    call check_command
    jz .print

    ; Color Command
    mov di, COLOR_COMMAND
    call check_command
    jz .color

    ; Editor Command
    ; mov di, EDITOR_COMMAND
    ; call check_command
    ; jz .editor

    ; PHI Command
    mov di, PHI_COMMAND
    call check_command
    jz PHI_Command

    ; Cool Shutdown Command
    mov di, COOL_SHUTDOWN_COMMAND
    call check_command
    jz .shutdown

    jmp .unknown_command
.quit:
    call clear_screen
    jmp start_screen
.clear_command:
    call clear_screen
    jmp shell_screen
.shutdown:
    jmp shutdown
.print:
    mov al, [print_color]
    mov [color], al

    call get_next_argument

    mov si, [pointer]
    call print_string

    inc dh
    call set_cursor_position

    jmp shell_screen.loop
.color:
    call get_next_argument

    mov si, [pointer]
    call parse_hex_byte

    mov al, [calculated_color]
    mov [print_color], al

    jmp shell_screen.loop
.editor:
    jmp editor_screen
.unknown_command:
    mov byte [color], 0xC
    mov si, UNKNOWN_COMMAND
    call print_string
    ret

PHI_Command:
    call print_title
    mov dl, 0x00
    mov dh, 0x00

    jmp .color_1
.color_1:
    mov byte [color], COLOR_LIGHT_BLUE
    jmp .loop
.color_2:
    mov byte [color], COLOR_CYAN
    jmp .loop
.loop:
    call set_cursor_position
    inc dl
    inc dh

    mov si, PHI_STRING
    call print_string

    cmp dh, [columns]
    je .next

    jmp .loop
.next:
    inc dl
    mov dh, 0x00

    cmp byte [color], COLOR_LIGHT_BLUE
    je .color_2

    jmp .color_1

create_line:
    mov dl, 0
    call set_cursor_position

    jmp .iteration
.iteration:
    mov si, LINE
    call print_string

    inc dl
    call set_cursor_position

    cmp dl, [columns]
    jne .iteration
    
    ret

shutdown:
    ; Initializing APM Connession
    mov ax, 0x5301
    xor bx, bx
    int 0x15

    ; Setting power state of all devices
    mov ax, 0x530E
    xor bx, bx
    mov cx, 0x0102
    int 0x15

    ; Power Off Command
    mov ax, 0x5307
    mov bx, 0x0001      ; All Devices
    mov cx, 0x0003      ; State: Off
    int 0x15

    ; Shutdown Failed
    jmp $

print_title:
    mov byte [color], 0x09
    mov dh, 2

    mov si, TITLE_1
    call get_centered_x_offset
    call set_cursor_position
    call print_string

    inc dh

    mov si, TITLE_2
    call get_centered_x_offset
    call set_cursor_position
    call print_string

    inc dh

    mov si, TITLE_3
    call get_centered_x_offset
    call set_cursor_position
    call print_string

    inc dh

    mov si, TITLE_4
    call get_centered_x_offset
    call set_cursor_position
    call print_string

    inc dh

    mov si, TITLE_5
    call get_centered_x_offset
    call set_cursor_position
    call print_string

    inc dh

    mov si, TITLE_6
    call get_centered_x_offset
    call set_cursor_position
    call print_string

    ret

; INCLUDE DRIVERS ;
%include "drivers/video.asm"
%include "drivers/keyboard.asm"

; INCLUDE LOGIC ;
%include "logic/string.asm"

; CONST VARIABLES ;
SQ equ 0xDB

LINE db SQ, 0
EDITOR_LINE db '#', 0
PHI_STRING db '1.6180339', 0

TITLE db ' [ PHI OS ] ', 0
TITLE_1 db ' ',SQ,SQ,SQ,SQ,SQ,SQ,'   ',SQ,'     ',SQ,'   ',SQ,'      ',SQ,SQ,SQ,SQ,SQ,SQ,'  ',SQ,SQ,SQ,SQ,SQ,SQ, 0
TITLE_2 db ' ',SQ,'    ',SQ,'   ',SQ,'     ',SQ,'   ',SQ,'      ',SQ,'    ',SQ,'  ',SQ,'     ', 0
TITLE_3 db ' ',SQ,'    ',SQ,'   ',SQ,SQ,SQ,SQ,SQ,SQ,SQ,'   ',SQ,'      ',SQ,'    ',SQ,'  ',SQ,'     ', 0
TITLE_4 db ' ',SQ,SQ,SQ,SQ,SQ,SQ,'   ',SQ,'     ',SQ,'   ',SQ,'      ',SQ,'    ',SQ,'  ',SQ,SQ,SQ,SQ,SQ,SQ, 0
TITLE_5 db ' ',SQ,'        ',SQ,'     ',SQ,'   ',SQ,'      ',SQ,'    ',SQ,'       ',SQ,'', 0
TITLE_6 db ' ',SQ,'        ',SQ,'     ',SQ,'   ',SQ,'      ',SQ,SQ,SQ,SQ,SQ,SQ,'  ',SQ,SQ,SQ,SQ,SQ,SQ, 0

WELCOME db 'Welcome User!', 0
START db 'Press any key to enter workspace...', 0

SHELL db '[ WORKSPACE ] ', 0
EDITOR db '  [ EDITOR ] ', 0
COMMAND_INPUT db '>> ', 0

QUIT_COMMAND db 'quit', 0
CLEAR_COMMAND db 'clear', 0
SHUTDOWN_COMMAND db 'shutdown', 0
PRINT_COMMAND db 'print', 0
COLOR_COMMAND db 'color', 0
PHI_COMMAND db 'phi', 0
EDITOR_COMMAND db 'editor', 0
UNKNOWN_COMMAND db 'Unknown Command.', 0

COOL_SHUTDOWN_COMMAND db 'asdfghjkl',0x3B,0x27, 0