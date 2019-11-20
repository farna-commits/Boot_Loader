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



            mov eax, 1              ;input


            ._loop:              ;loop to fill the 512 entries of the level 1 page table and to point to the 2MB 
            mov [es:di], eax                ;move the present value of eax (0x0003) into es:di 
            mov ebx, [es:di]
            add di, 4                      ;incriment di by 0x8
            ;Still missing here to print the number '4' we kept putting in memory using the special video instructions 
            cmp ebx ,0x200000        ;check if all 2MB are mapped 
            jl ._loop            ;if not, continue looping if yes then go retrieve regisetrs and return


            popa                                ; Restore all general purpose registers from the stack
            ret

