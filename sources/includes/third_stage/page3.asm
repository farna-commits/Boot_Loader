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
%define AFTER_PAGETABLE     0x104000
%define PAGE_PRESENT_WRITE  0x3
%define MEM_PAGE_4K         0x1000
%define FIVE_TWELVE         0x200
%define CELL                0x8
%define Mem_Regions_ptr     0x21018
%define Mem_Regions_counter   0x21000

;4 counters
PML4_counter dq 0x0000               ;level 4
PDP_counter  dq 0x0000               ;level 3
PDT_counter  dq 0x0000
PTE_counter  dq 0x0000               ;level 1

;4 pointers to point to the start of each page level
;defined as dq as addresses won't fit in a word
PML4_ptr dq PML4_ADDRESS
PDP_ptr  dq PDP_ADDRESS
PDT_ptr  dq PDT_ADDRESS
PTE_ptr  dq PTE_ADDRESS         ;pointer for inside each pte
after_pagetable_ptr     dq AFTER_PAGETABLE
type           dq 0x0
max           dq 0x0
mem_reg    dq 0x0


;define variable for physical memory initialized at 0
Physical_mem_ptr   dq  0x000000


get_max:
pushaq
mov rdx,Mem_Regions_ptr
mov rax,qword[Mem_Regions_counter]
mov qword[mem_reg],rax
     .loop3:
     mov rax,qword[rdx]
     mov rbx,qword[rdx+8]
     add rbx,rax
     xor rcx,rcx
     mov ecx,dword[rdx+16]
     cmp rcx,0x1
     jne .skp
     mov qword[max],rbx
     .skp:
     dec qword[mem_reg]
     add rdx, 0x18
     cmp qword[mem_reg],0x0
     jne .loop3
popaq
ret

; check_region:
; pushaq
; mov r8, Mem_Regions_ptr
; sub r8,0x18
; mov qword[type],0x0
;      .loop4:
;      add r8,24       ;move to the next row by adding 24 bytes

;      mov r9, qword[r8]        ;getting base address (Start)
;      mov r10,qword[r8+8]      ;getting length
;      add r10,r9               ;end = start + length
;      cmp qword[Physical_mem_ptr], r9          ;compare page with start address
;      jl .loop4              ;if less go to this label
;      cmp qword[Physical_mem_ptr],r10             ;if not compare with the end
;      jg .loop4       ;if less then im between start and end so go check the type

;      xor rcx,rcx
;      mov ecx,dword[r8+16]
;      mov qword[type],rcx


; popaq
; ret



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

.check_type:        ;to check which type from 1->5 AFTER we made sure were between start and end
xor rdx,rdx
add r8,0x10        ;add the offset of 16 to access the type bits
mov edx, dword[r8]    ;mov the value of pointer to a register
;add r8, 0x8        ;add 8  (24-16) to move to next entry
cmp edx, 0x1        ;compare the value of pointer with 1 (type 1)
je type1            ;go to label type1 in the 4 nested loops
jmp continue1



page_table:
pushaq
call get_max
; PML4_loop: 
; ;       ;this level will create 512 pdt tables to map 512 x 512 x 512 x 2mb = 262tb
; ;       ;zero the rax and rbx registers to use here     
; mov rbx, qword[PDP_ptr]         ;move pte pointer to rbx
; or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active

; mov rax, qword[PML4_ptr]         ;move pte pointre to rax
; mov qword[rax], rbx         ;let pdt  = pte ptr value


; mov qword[PDP_counter], 0x0 ;reset the pte counter
;      PDP_loop:
;      mov rbx, qword[PDT_ptr]         ;move pte pointer to rbx
;      or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active

;      mov rax, qword[PDP_ptr]         ;move pte pointre to rax
;      mov qword[rax], rbx         ;let pdt  = pte ptr value


;      mov qword[PDT_counter], 0x0 ;reset the pte counter

;             PDT_loop:
            ;mov rsi,hello_world_str4
            ; call video_print
            ;this level will create 512 pte tables to map 512 x 2mb = 1gb


             mov rbx, qword[PTE_ptr]         ;move pte pointer to rbx
             or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active

             mov rax, qword[PDT_ptr]         ;move pte pointre to rax
             mov qword[rax], rbx         ;let pdt  = pte ptr value


           mov qword[PTE_counter], 0x0 ;reset the pte counter

                PTE_loop:

                ;map 2mb from memory
                ;zero the rax(PTE) and rbx(Physical) registers to use here
                mov rax, qword[max]
                mov rbx, qword[Physical_mem_ptr]
                cmp rax,rbx
                je exit

               ;cmp qword[Physical_mem_ptr],0x200000
               ;jle .skipcheck
               ;call check_region
               ;cmp qword[type],0x1
               ;jne .nomap

                ;.skipcheck:
                ;check if the types
                jmp check_region
                type1:


                mov rax,  qword[PTE_ptr]    ;store in rax position of pte pointer
                mov rbx,  qword[Physical_mem_ptr]   ;store in rbx the position of physical memory pointer
                or rbx, PAGE_PRESENT_WRITE     ;add 3 to the physical memory pointer
                mov qword[rax], rbx                  ;connect the current cell of pte to the physical memory + 3
                add qword[PTE_ptr], CELL                          ;incriment 1 cell in the pte table (8bytes)

               ;nomap:
               continue1:
                ;incriment addresses
                add qword[Physical_mem_ptr], MEM_PAGE_4K         ;incriment a page from physical


                ;incriment loop counter
                inc qword[PTE_counter]                     ;counter ++

                ;check if the 512 cells are filled
                cmp qword[PTE_counter], FIVE_TWELVE ;check if counter for PTE reached 512


                jl PTE_loop            ;if still less continue looping
          ; mov rsi,hello_world_str
           ; call video_print

             mov rax, qword[after_pagetable_ptr]
             mov qword[PTE_ptr], rax
             add qword[after_pagetable_ptr], MEM_PAGE_4K


          cmp qword[PDP_counter],0x0
          jnz .skpload
            ;update cr3
            mov rax, qword[PML4_ptr]
             mov cr3,rax
          .skpload:

              add qword[PDT_ptr], CELL        ;incriment to next cell in pdt table
     ;         ;incriment counter
              inc qword[PDT_counter]       ;counter++

     ; ;    ;     inc r15

          cmp qword[PDT_counter], FIVE_TWELVE
;              jl PDT_loop

;              mov rax, qword[after_pagetable_ptr]
;              mov qword[PDT_ptr],rax
;              add qword[after_pagetable_ptr], MEM_PAGE_4K

;             ; mov rsi,hello_world_str5
;            ;call video_print

;      add qword[PDP_ptr], CELL        ;incriment to next cell in pdt table
;      ;         ;incriment counter
;      inc qword[PDP_counter]       ;counter++

;      ; ;    ;     inc r15

;      cmp qword[PDP_counter], FIVE_TWELVE
;      jl PDP_loop


; add qword[PML4_ptr], CELL        ;incriment to next cell in pdt table
; ;         ;incriment counter
; inc qword[PML4_counter]       ;counter++

; ; ;    ;     inc r15

; cmp qword[PML4_counter], 0x4
; jl PML4_loop

; exit:
;             mov rsi,hello_world_str2
;             call video_print
;             mov rax, qword[PML4_ptr]
;             mov cr3,rax
exit:
 popaq
 ret