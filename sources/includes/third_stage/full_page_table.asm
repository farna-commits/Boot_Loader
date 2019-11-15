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
PTE_ptr  dq PTE_ADDRESS


page_table:
pusha
    ;initialize the 4 page tables 
    ;we need to start after 1MB that was mapped in 2nd stage
    ;create the 4 loops: 
    .PML4_loop: 

        .PDP_loop:

            .PDT_loop:

                .PTE_loop:

                cmp [PTE_counter], 0x200  ;check if counter for PTE reached 512
                jl .PTE_loop            ;if still less continue looping

            cmp [PDT_counter], 0x200      ;check if counter for PDT reached 512
            jl .PDT_loop                ;if still less conitnue looping
        
        cmp [PDP_counter], 0x200          ;check if counter for PDP reached 512
        jl .PDP_loop                    ;if still less continue looping
        
    cmp [PML4_counter], 0x200             ;check if counter for PDP reached 512
    jl .PML4_loop                       ;if still less continue looping


popa
ret