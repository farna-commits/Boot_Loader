;this file is for creating the full page table that will map 256 TB of memory (all the memory) after we reached the long mode. 
;we need to start mapping after the first 1MB that was mapped in stage 2
;4 counters are needed for the 4 nested loops that will be used to fill the 4 levels of the page table.
;we will have 4 nested loops and each counter should reach 512 (0->511)
;64-bit registers will be used as we in the long mode and because addresses will be huge.

;define the addresses for each level that we set in the 2nd stage page table
%define PML4_ADDRESS    0x100000
%define PDP_ADDRESS     0x101000
%define PDT_ADDRESS     0x102000
%define PTE_ADDRESS     0x103000
%define PAGE_PRESENT_WRITE 0x3  /* same as 011b used to activate the page (flags)*/
%define MEM_PAGE_4K         0x1000
%define FIVE_TWELVE         0x200   /*tables entries size*/
%define CELL                0x8     /*8 bytes of each cell*/     

;4 counters
PML4_counter dw 0x0000               ;level 4      
PDP_counter  dw 0x0000               ;level 3 
PDT_counter  dw 0x0000               ;level 2 
PTE_counter  dw 0x0000               ;level 1 

;4 pointers to point to the start of each page level
;defined as dq as addresses won't fit in a word
PML4_ptr dq PML4_ADDRESS
PDP_ptr  dq PDP_ADDRESS
PDT_ptr  dq PDT_ADDRESS
PTE_ptr  dq PTE_ADDRESS         ;pointer for inside each pte
PTE_accum_ptr   dq PTE_ADDRESS  ;pointer for choosing which pte are we in from the 512   
Type_ptr     dq  PTE_ADDRESS 
Mem_Regions_ptr   dq 0x21018      ;0x1018->memory regions table; 0x20000->memory regions information start at 0x20000


;define variable for physical memory initialized at 0
Physical_mem_ptr   dq  0x0000


check_region:
add rcx,0x10        ;add the offset of 16 to access the type bits
mov rdx, dw[rcx]    ;mov the value of pointer to a register
add rcx, 0x8        ;add 8  (24-16) to move to next entry
cmp rdx, 0x1        ;compare the value of pointer with 1 (type 1)
je type1            ;go to label type1 in the 4 nested loops
cmp rdx, 0x2        ;compare the value of pointer with 1 (type 1)
je continue1            ;go to label cont1 in the 4 nested loops
cmp rdx, 0x3        ;compare the value of pointer with 1 (type 1)
je continue1            ;go to label cont1 in the 4 nested loops
cmp rdx, 0x4        ;compare the value of pointer with 1 (type 1)
je continue1            ;go to label cont1 in the 4 nested loops
jmp exit            ;if nothing of the 4 types exit






page_table:
pusha
xor rcx,rcx
xor rdx,rdx
mov rcx, qword[Mem_Regions_ptr]         ;move 0x21018 to a reg
    ;initialize the 4 page tables 
    ;we need to start after 1MB that was mapped in 2nd stage
    ;create the 4 loops: 
    .PML4_loop: 

        .PDP_loop:
        ;this level will create 512 pdt tables to map 512 x 512 x 2mb = 512gb
        ;zero the rax and rbx registers to use here
        xor rax,rax
        xor rbx,rbx 

        mov rbx, qword[PDT_ptr]         ;move pdt pointer to rbx 
        or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active

        mov rax, qword[PDP_ptr]         ;move pdp pointre to rax
        mov [rax], rbx         ;let pdp  = pte ptr value

        mov qword[PDT_counter], 0x0000  ;reset the pdt counter


            .PDT_loop:
            ;this level will create 512 pte tables to map 512 x 2mb = 1gb
            ;zero the rax and rbx registers to use here
            xor rax,rax
            xor rbx,rbx           

            mov rbx, qword[PTE_ptr]         ;move pte pointer to rbx 
            or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active

            mov rax, qword[PDT_ptr]         ;move pte pointre to rax
            mov [rax], rbx         ;let pdt  = pte ptr value


            mov qword[PTE_counter], 0x0000  ;reset the pte counter

                .PTE_loop:
                ;map 2mb from memory
                ;zero the rax(PTE) and rbx(Physical) registers to use here
                xor rax,rax
                xor rbx,rbx

                mov rax,  qword[PTE_ptr]    ;store in rax position of pte pointer
                mov rbx,  qword[Physical_mem_ptr]   ;store in rbx the position of physical memory pointer
                ;check if the types
                jmp check_region
                type1:
                or rbx, PAGE_PRESENT_WRITE     ;add 3 to the physical memory pointer
                mov [rax], rbx                  ;connect the current cell of pte to the physical memory + 3

                continue1:
                ;incriment addresses
                add qword[Physical_mem_ptr], MEM_PAGE_4K         ;incriment a page from physical
                add qword[PTE_ptr], CELL                          ;incriment 1 cell in the pte table (8bytes)

                ;incriment loop counter
                add qword[PTE_counter], 0x0001                       ;counter ++

                ;check if the 512 cells are filled
                cmp [PTE_counter], FIVE_TWELVE  ;check if counter for PTE reached 512
                jl .PTE_loop            ;if still less continue looping

            ;move physical memory ptr to pte ptr
            xor rax,rax
            xor rbx,rbx

            mov rax,qword[Physical_mem_ptr]     ;load physical memory pointer into rax
            mov qword[PTE_ptr], rax             ;pte pointer = physical memory pointer
            add qword[Physical_mem_ptr], MEM_PAGE_4K         ;incriment a page from physical
            add qword[PDT_ptr], CELL        ;incriment to next cell in pdt table
            ;incriment counter 
            add qword[PDT_counter], 0x0001       ;counter++

            ;update cr3
            mov cr3,PML4_ADDRESS    

            ;check if the 512 cells are filled
            cmp [PDT_counter], FIVE_TWELVE      ;check if counter for PDT reached 512
            jl .PDT_loop                ;if still less conitnue looping


        ;move physical memory ptr to pdt ptr
        xor rax,rax
        xor rbx,rbx

        mov rax,qword[Physical_mem_ptr]     ;load physical memory pointer into rax
        mov qword[PDT_ptr], rax             ;pdt pointer = physical memory pointer

        add qword[Physical_mem_ptr], MEM_PAGE_4K         ;incriment a page from physical
        add qword[PDP_ptr], CELL        ;incriment to next cell in pdt table
        ;incriment counter 
        add qword[PDP_counter], 0x0001       ;counter++

        ;check if the 512 cells are filled
        cmp [PDP_counter], FIVE_TWELVE          ;check if counter for PDP reached 512
        jl .PDP_loop                    ;if still less continue looping
        
    cmp [PML4_counter], FIVE_TWELVE             ;check if counter for PDP reached 512
    jl .PML4_loop                       ;if still less continue looping


exit:
;update cr3
mov cr3,PML4_ADDRESS

popa
ret