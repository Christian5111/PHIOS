BITS 16
ORG 0x7C00

start:
    ; Save Boot Drive
    mov [BOOT_DRIVE], dl

    ; Segments and Stack Setup
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000

    ; Clear Screen and set Text Mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Print Message
    mov si, msg
    call print_string

    ; Load Kernel
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x7E00 ; Destination: 0x7E00

    mov ah, 0x02
    mov al, 5 ; Read 5 Sectors
    mov ch, 0
    mov dh, 0
    mov cl, 2 ; Load Kernel at Sector 2
    mov dl, [BOOT_DRIVE]
    int 0x13
    jc disk_error

    ; Jump to Kernel
    jmp 0x0000:0x7E00

.print:
    lodsb
    test al, al
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp .print

disk_error:
    mov si, err
.err_loop:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x0C
    int 0x10
    jmp .err_loop

.halt:
    cli
    hlt
    jmp .halt

print_string:
.next:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x0A
    int 0x10
    jmp .next

.done:
    ret

msg db 'Booting the operating system...', 0
err db 'Disk error!', 0

BOOT_DRIVE db 0

times 510-($-$$) db 0
dw 0xAA55