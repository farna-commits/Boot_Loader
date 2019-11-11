;this method is the way of constructing our physical memory to be used through the upcoming stages

GDT64:
    .Null: equ $ - GDT64         ; The null descriptor.
    ;set all the null descriptor elements as 0
        dw 0
        dw 0
        db 0
        db 0
        db 0
        db 0
    .Code: equ $ - GDT64         ; The Kernel code descriptor.
    ;set all the kernel code descriptor as 0 except: Access Bytes: Pr, Privl & Ex ; FLags: L
        dw 0
        dw 0
        db 0
        db 10011000b
        db 00100000b
        db 0
    .Data: equ $ - GDT64         ; The Kernel data descriptor.
    ;set all the kernel code descriptor as 0 except: Access Bytes: Pr, Privl, RW & AC    
        dw 0
        dw 0
        db 0
        db 10010011b
        db 00000000b
        db 0
ALIGN 4                 ; for the address of GDT to be word aligned 
        dw 0
    .Pointer:
    dw $-GDT64 - 1      ;limit of GDT 
    dd GDT64            ;Base address of GDT