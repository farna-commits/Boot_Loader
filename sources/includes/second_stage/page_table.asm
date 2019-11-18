%define PAGE_TABLE_BASE_ADDRESS 0x0000
%define PAGE_TABLE_BASE_OFFSET 0x1000
%define PAGE_TABLE_EFFECTIVE_ADDRESS 0x1000
%define PAGE_PRESENT_WRITE 0x3  ; 011b
%define MEM_PAGE_4K         0x1000

build_page_table:
    pusha                                   ; Save all general purpose registers on the stack
        ;storing the page table itself in memory from 0x0000(es) to 0x1000(edi)
        mov ax, PAGE_TABLE_BASE_ADDRESS     ;move into ax first as we cant move to es directly
        mov es, ax                          ;move to es
        xor eax,eax                         ;set eax=0
        mov edi, PAGE_TABLE_BASE_OFFSET         ;put in edi the end boundary

        ;Initialize the 4 levels of page tables
        mov ecx,0x1000          ;set ecx as a counter starting at 4KB   
        xor eax,eax             ;set eax to 0
        cld                     ;instruction to clear Direction FLag
        rep stosd               ;this instruction does ALL the following: 1) let eax = 4KB and store at the address between es->edi done above
                                ;2)loop untill value of our counter ecx(4KB) = 0; 3)incriment edi by 4 each loop; 4)that will create 4*4KB =16KB(4 levels page table)


        mov edi, PAGE_TABLE_BASE_OFFSET         ;reset edi to the end boundary again as the previous loop changed its value
        ;PML4 (level 4) 
        ;level 4 is now stored between 0x0000->0x1000
        lea eax, [es:di+MEM_PAGE_4K]            ;load effective address; loads the address of next page table (level3)     
        or eax,PAGE_PRESENT_WRITE               ;set bit 0 and bit 2 as 1 (011); where are Present and Write flags
        mov [es:di],eax                         ;point the first cell in PML4 to the next page table (level3)
        ;PDP (level 3)
        ;level 3 is now stored between 0x0000->0x2000
        add di, MEM_PAGE_4K                     ;set di as 0x1000
        lea eax, [es:di+MEM_PAGE_4K]            ;load effective address; loads the address of the next page table (level 2)
        or eax, PAGE_PRESENT_WRITE              ;set bit 0 and bit 2 as 1 (011); where are Present and Write flags
        mov [es:di], eax                        ;point the first cell in PDP to the next page table (level2)
        ;PDT (level 2)
        ;level 2 is now stored between 0x0000->0x3000
        add di, MEM_PAGE_4K                     ;set di as 0x1000
        lea eax, [es:di+MEM_PAGE_4K]            ;load effective address; loads the address of the next page table (level 1)
        or eax, PAGE_PRESENT_WRITE              ;set bit 0 and bit 2 as 1 (011); where are Present and Write flags
        mov [es:di], eax                        ;point the first cell in PDP to the next page table (level2)
        ;PT (level1)
        ;level 1 is now stored between 0x0000->0x4000
        add di, MEM_PAGE_4K                     ;set di as 0x1000
        mov eax, PAGE_PRESENT_WRITE             ;store 0x0003 in eax      

        .pte_loop:              ;loop to fill the 512 entries of the level 1 page table and to point to the 2MB 
        mov [es:di], eax                ;move the present value of eax (0x0003) into es:di 
        add eax, MEM_PAGE_4K            ;incriment eax by 0x1000
        add di, 0x8                     ;incriment di by 0x8
        cmp eax,0x200000        ;check if all 2MB are mapped 
        jl .pte_loop            ;if not, continue looping if yes then go retrieve regisetrs and return

    popa                                ; Restore all general purpose registers from the stack
    ret