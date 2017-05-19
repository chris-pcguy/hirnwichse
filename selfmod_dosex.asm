
; selfmod_dosex == self-modifying code dos (executable) example
; nasm -f bin -o selfmod_dosex.com selfmod_dosex.asm
; msg1 on HWemu (CPU_CACHE_SIZE value doesn't matter), VBox, Qemu-KVM; msg2 on Bochs, Qemu-Classic

org 100h

main:
    mov al, 90h
    mov cx, 4h
    mov di, .1f
.1f:
    rep stosb
    jmp .2f
.2f:
    jcxz .3f
    call PrintMsg2
    jmp .exit
.3f:
    call PrintMsg1
.exit:
    mov ax, 4c00h
    int 21h

PrintString: ; this function is "inspired"/stolen
    mov bx, 1
    mov ah, 040h
    int 21h
    ret

PrintMsg1:
    mov dx, msg1
    mov cx, msg1len
    jmp PrintString

PrintMsg2:
    mov dx, msg2
    mov cx, msg2len
    jmp PrintString


msg1 db 'Undetected',13,10 ; CPU-Cache?
msg1len equ $ - msg1

msg2 db 'Detected',13,10 ; No CPU-Cache?
msg2len equ $ - msg2
