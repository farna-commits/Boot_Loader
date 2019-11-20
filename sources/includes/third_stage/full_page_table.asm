;this file is for creating the full page table that will map 256 TB of memory (all the memory) after we reached the long mode. 
;we need to start mapping after the first 1MB that was mapped in stage 2
;4 counters are needed for the 4 nested loops that will be used to fill the 4 levels of the page table.
;we will have 4 nested loops and each counter should reach 512 (0->511)
;64-bit registers will be used as we in the long mode and because addresses will be huge.


%include "sources/includes/third_stage/pushaq.asm"





;define the addresses for each level that we set in the 2nd stage page table
%define PML4_ADDRESS        0x100000
%define PDP_ADDRESS         0x101000
%define PDT_ADDRESS         0x102000
%define PTE_ADDRESS         0x103000
%define PAGE_PRESENT_WRITE  0x3  
%define MEM_PAGE_4K         0x1000
%define FIVE_TWELVE         0x200  
%define CELL                0x8      
%define Mem_Regions_ptr     0x21018  

;4 counters
PML4_counter dw 0x0000               ;level 4      
PDP_counter  dw 0x0000               ;level 3 
PDT_counter  dw 0x0000
PTE_counter  dw 0x0000               ;level 1 

;4 pointers to point to the start of each page level
;defined as dq as addresses won't fit in a word
PML4_ptr dq PML4_ADDRESS
PDP_ptr  dq PDP_ADDRESS
PDT_ptr  dq PDT_ADDRESS
PTE_ptr  dq PTE_ADDRESS         ;pointer for inside each pte
PTE_accum_ptr   dq PTE_ADDRESS  ;pointer for choosing which pte are we in from the 512   
Type_ptr     dq  PTE_ADDRESS 


;define variable for physical memory initialized at 0
Physical_mem_ptr   dq  0x200000


check_region:
mov r8, Mem_Regions_ptr  ;mov the address of the table
sub r8,24       ;move to the next row by adding 24 bytes    ;for the first time
.loopCheck:
add r8,24       ;move to the next row by adding 24 bytes

mov r9, qword[r8]        ;getting base address (Start)
mov r10,qword[r8+8]      ;getting length 
add r10,r9               ;end = start + length
cmp qword[Physical_mem_ptr], r9          ;compare page with start address
jl .loopCheck               ;if less go to this label
cmp qword[Physical_mem_ptr],r10             ;if not compare with the end 
jg .loopCheck        ;if less then im between start and end so go check the type

;if no go check type
; .nextRow:

; add r8,24       ;move to the next row by adding 24 bytes
; cmp r9,r10      ;if start = end
; ;je exit         ;then i'm not in memory region table so exit the whole function

   
.check_type:        ;to check which type from 1->5 AFTER we made sure were between start and end
xor rdx,rdx
add r8,0x10        ;add the offset of 16 to access the type bits
mov edx, dword[r8]    ;mov the value of pointer to a register
;add r8, 0x8        ;add 8  (24-16) to move to next entry
cmp edx, 0x1        ;compare the value of pointer with 1 (type 1)
je type1            ;go to label type1 in the 4 nested loops
cmp edx, 0x2        ;compare the value of pointer with 1 (type 1)
je continue1            ;go to label cont1 in the 4 nested loops
cmp edx, 0x3        ;compare the value of pointer with 1 (type 1)
je continue1            ;go to label cont1 in the 4 nested loops
cmp edx, 0x4        ;compare the value of pointer with 1 (type 1)
je continue1            ;go to label cont1 in the 4 nested loops
cmp edx, 0x5        ;compare the value of pointer with 1 (type 1)
je continue1            ;go to label cont1 in the 4 nested loops
jmp exit            ;if nothing of the 4 types exit


page_table:
pushaq
mov r14,0


; ;     ;initialize the 4 page tables 
; ;     ;we need to start after 1MB that was mapped in 2nd stage
; ;     ;create the 4 loops: 
;      PML4_loop: 
; ;       ;this level will create 512 pdt tables to map 512 x 512 x 512 x 2mb = 262tb
; ;       ;zero the rax and rbx registers to use here     
;         xor rax, rax
;         xor rbx, rbx

;         mov rax, qword[PML4_ptr]        ;move pml4 pointer to rax
;         mov rbx, qword[PDP_ptr]         
;         or rbx, PAGE_PRESENT_WRITE      ;or to make it page active
;         mov qword[rax], rbx                  ;let pml4 = pdp ptr value

;         mov dword[PDP_counter], 0x0000  ;reset the pdp counter

;         PDP_loop:
; ;         ;this level will create 512 pdt tables to map 512 x 512 x 2mb = 512gb
; ;         ;zero the rax and rbx registers to use here
;         xor rax,rax
;         xor rbx,rbx 

;         mov rbx, qword[PDT_ptr]         ;move pdt pointer to rbx 
;         or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active

;         mov rax, qword[PDP_ptr]         ;move pdp pointre to rax
;         mov qword[rax], rbx         ;let pdp  = pte ptr value

;         mov dword[PDT_counter], 0x0000  ;reset the pdt counter


            PDT_loop:
              ;              mov rsi,hello_world_str4
               ; call video_print
            ;this level will create 512 pte tables to map 512 x 2mb = 1gb
            ;zero the rax and rbx registers to use here
            xor rax,rax
            xor rbx,rbx           

            mov rbx, qword[PTE_ptr]         ;move pte pointer to rbx 
            or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active

            mov rax, qword[PDT_ptr]         ;move pte pointre to rax
            mov qword[rax], rbx         ;let pdt  = pte ptr value


            mov dword[PTE_counter], 0x0000  ;reset the pte counter

                PTE_loop:
                
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
                mov qword[rax], rbx                  ;connect the current cell of pte to the physical memory + 3
                

                continue1:
                ;incriment addresses
                add qword[Physical_mem_ptr], MEM_PAGE_4K         ;incriment a page from physical
                add qword[PTE_ptr], CELL                          ;incriment 1 cell in the pte table (8bytes)

                ;incriment loop counter
                add dword[PTE_counter], 0x0001                       ;counter ++
                
                ;check if the 512 cells are filled
                cmp dword[PTE_counter], FIVE_TWELVE  ;check if counter for PTE reached 512
                
                
                jl PTE_loop            ;if still less continue looping
               ; mov rsi,hello_world_str
                ;call video_print
             cmp dword[PDP_counter],0x0000
             jnz .dontUpdateCR3
            ;update cr3
            mov r12,qword[PML4_ptr]
            ;mov cr3, r12

            .dontUpdateCR3:
            ;move physical memory ptr to pte ptr


            ; mov rax,qword[Physical_mem_ptr]     ;load physical memory pointer into rax
            ; mov qword[PTE_ptr], rax             ;pte pointer = physical memory pointer
            ; add qword[Physical_mem_ptr], MEM_PAGE_4K         ;incriment a page from physical


            add qword[PDT_ptr], CELL        ;incriment to next cell in pdt table
            ;incriment counter 
            add dword[PDT_counter], 0x0001       ;counter++

            
            inc r14
            ;check if the 512 cells are filled
            cmp r14,255
            je  now
        
            cmp r14, 512      ;check if counter for PDT reached 512
            jl PDT_loop                ;if still less conitnue looping
                ;mov rsi,hello_world_str3
                ;call video_print

;         ;move physical memory ptr to pdt ptr
;         xor rax,rax
;         xor rbx,rbx

;         ; mov rax,qword[Physical_mem_ptr]     ;load physical memory pointer into rax
;         ; mov qword[PDT_ptr], rax             ;pdt pointer = physical memory pointer
;         ; add qword[Physical_mem_ptr], MEM_PAGE_4K         ;incriment a page from physical

;         add qword[PDP_ptr], CELL        ;incriment to next cell in pdt table
;         ;incriment counter 
;         add dword[PDP_counter], 0x0001       ;counter++

;         ;check if the 512 cells are filled
;         cmp dword[PDP_counter], FIVE_TWELVE          ;check if counter for PDP reached 512
;         jl PDP_loop                    ;if still less continue looping

    
;     add qword[PML4_ptr], CELL                   ;advance ptr of pml4 a cell
;     add dword[PML4_counter], 0x0001             ;incriment counter
;     cmp dword[PML4_counter], FIVE_TWELVE            ;check if counter for PDP reached 512
;     jl PML4_loop                       ;if still less continue looping

now:
 mov rsi,hello_world_str5
 call video_print



     exit:
                     mov rsi,hello_world_str2
                call video_print
;     ;update cr3
;     xor rdx,rdx
;     mov rdx,qword[PML4_ptr]
;     mov cr3, rdx
popaq
ret