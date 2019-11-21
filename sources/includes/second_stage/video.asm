%define VIDEO_BUFFER_SEGMENT                    0xB000
%define VIDEO_BUFFER_OFFSET                     0x8000
%define VIDEO_BUFFER_EFFECTIVE_ADDRESS          0xB8000
%define VIDEO_SIZE      0x0FA0   
    video_cls_16:
            pusha                                   ; Save all general purpose registers on the stack

            ;storing the page table itself in memory from 0x0000(es) to 0x1000(edi)
            mov ax, VIDEO_BUFFER_SEGMENT     ;move into ax first as we cant move to es directly
            mov es, ax                          ;move to es
            xor eax,eax                         ;set eax=0
            mov edi, VIDEO_BUFFER_OFFSET         ;put in edi the end boundary

            .loop1:
            mov edx, ' '
            mov [es:di],dx
            add di,1
            mov edx, 0x0F
            mov [es:di],dx
            add di,1
            mov edx, 0x02
            mov [es:di],dx
            cmp di, 0xFA0
            jl .loop1
            popa                                ; Restore all general purpose registers from the stack
            ret

