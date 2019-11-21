;this file is for creating the full page table that will map 256 TB of memory (all the memory) after we reached the long mode.
;we need to start mapping after the first 1MB that was mapped in stage 2
;4 counters are needed for the 4 nested loops that will be used to fill the 4 levels of the page table.
;we will have 4 nested loops and each counter should reach 512 (0->511)
;64-bit registers will be used as we in the long mode and because addresses will be huge.


;define the addresses for each level that we set in the 2nd stage page table
%define PML4_ADDRESS          0x100000
%define PDP_ADDRESS           0x101000
%define PDT_ADDRESS           0x102000
%define PTE_ADDRESS           0x103000
%define AFTER_PTE             0x104000
%define PAGE_PRESENT_WRITE    0x3
%define MEM_PAGE_4K           0x1000
%define FIVE_TWELVE           0x200
%define CELL                  0x8
%define TWENTY_FOUR           0x18
%define Mem_Regions_ptr       0x21018
%define Mem_Regions_counter   0x21000

;4 counters
PML4_counter dq 0x0000               ;level 4
PDP_counter  dq 0x0000               ;level 3
PDT_counter  dq 0x0000               ;level 2
PTE_counter  dq 0x0000               ;level 1

;4 pointers to point to the start of each page level
;defined as dq as addresses won't fit in a word
PML4_ptr                 dq PML4_ADDRESS
PDP_ptr                  dq PDP_ADDRESS
PDT_ptr                  dq PDT_ADDRESS
PTE_ptr                  dq PTE_ADDRESS           ;pointer for inside each pte
after_PTE_ptr      dq AFTER_PTE       ;ptr to which is after the first 2mb+page table region in physical memory
max                      dq 0x0                   ;variable to hold max memory of type1 
;mem_reg                  dq 0x0                   ;memory region variable (temp)----------------------------------------------------> switched with r15
Physical_mem_ptr         dq  0x000000             ;define variable for physical memory initialized at 0

;Check Region Function
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
cmp edx, 0x1        ;compare the value of pointer with 1 (type 1)
je type1            ;go to label type1 in the 4 nested loops
jmp continue1       ;this means the memory type wasnt of type1, this label is in the 4 nested loops
cmp edx, 0x2        ;compare the value of pointer with 2 (type 2)
je continue1            ;go to label cont1 in the 4 nested loops
cmp edx, 0x3        ;compare the value of pointer with 3 (type 3)
je continue1            ;go to label cont1 in the 4 nested loops
cmp edx, 0x4        ;compare the value of pointer with 4 (type 4)
je continue1            ;go to label cont1 in the 4 nested loops
cmp edx, 0x5        ;compare the value of pointer with 5 (type 5)
je continue1            ;go to label cont1 in the 4 nested loops


;Get maximum memory fucntion
get_max:
pushaq
mov rdx,Mem_Regions_ptr                 ;move the address of the table (from memory scanner func)
mov r15,qword[Mem_Regions_counter]      ;counter used in memory scanner function (won't change)
;mov qword[mem_reg],rax                  ;put the memory region counter from memory scanner into a temp location to be altered
     .loop3:
     mov rax,qword[rdx]                 ;get the base address (start)               
     mov rbx,qword[rdx+CELL]            ;get the length
     add rbx,rax                        ;add to get the end, end = start + length
     xor rcx,rcx                        ;zeroing rcx to be used
     mov ecx,dword[rdx+16]              ;move 16 bytes to reach the type 
     cmp rcx,0x1                        ;compare with type 1
     jne .not_type1                     ;if not type 1 then skip, max is only of type 1
     mov qword[max],rbx                 ;move the max into a memory variable
     .not_type1:
     dec r15                            ;decrement the counter
     add rdx, TWENTY_FOUR               ;move to the next row of the table                      
     cmp r15,0x0                        ;compare the counter if it reached zero exit
     jne .loop3
popaq
ret



;Main function to be called
page_table:
pushaq
call get_max   ;get the max type 1 memory that can me mapped, used in PTE loop
PML4_loop:        ;this level will create 512 pdt tables to map 512 x 512 x 512 x 2mb = 262tb   
mov rbx, qword[PDP_ptr]         ;move PDP pointer to rbx
or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active
mov rax, qword[PML4_ptr]         ;move PML4 pointre to rax
mov qword[rax], rbx         ;let pml4  = pdp ptr value
mov qword[PDP_counter], 0x0 ;reset the pdp counter

     PDP_loop:      ;this level will create 512 x 512 x 2mb = 512gb
     mov rbx, qword[PDT_ptr]         ;move pdt pointer to rbx
     or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active
     mov rax, qword[PDP_ptr]         ;move pdp pointre to rax
     mov qword[rax], rbx         ;let pdp  = pdt ptr value
     mov qword[PDT_counter], 0x0 ;reset the pdt counter

          PDT_loop:    ;this level will create 512 pte tables to map 512 x 2mb = 1gb 
          mov rbx, qword[PTE_ptr]         ;move pte pointer to rbx
          or rbx, PAGE_PRESENT_WRITE      ;or it to make it page active
          mov rax, qword[PDT_ptr]         ;move pte pointre to rax
          mov qword[rax], rbx         ;let pdt  = pte ptr value
          mov qword[PTE_counter], 0x0 ;reset the pte counter

               PTE_loop: ;map 2mb from memory (physical memory connection)
               mov rax, qword[max]               ;move the max to a temp register
               mov rbx, qword[Physical_mem_ptr]  ;move the physical memory pointer (extract a page from physical) to a register
               cmp rax,rbx                       ;compare both, if page extracted greater than max then exit the whole file function
               je exit                           ;go to exit if reached max

               cmp qword[Physical_mem_ptr],0x100000    ;check whether we are in the first 2mb (that was mapped by small ptable) or not
               jle type1                           ;if yes we were less, we can't check the first 2mb (crash)

               jmp check_region                        ;go to label of check region, similar to calling a function

               type1:                                  ;global label seen from the function check region, if type1 then we map
               mov rax,  qword[PTE_ptr]    ;store in rax position of pte pointer
               mov rbx,  qword[Physical_mem_ptr]   ;store in rbx the position of physical memory pointer
               or rbx, PAGE_PRESENT_WRITE     ;or 3 to make it page active
               mov qword[rax], rbx                  ;connect the current cell of pte to the physical memory + 3
               add qword[PTE_ptr], CELL                          ;incriment 1 cell in the pte table (8bytes)

               continue1:                         ;global label that indicates that memory at hand isn't type1 
               add qword[Physical_mem_ptr], MEM_PAGE_4K         ;incriment a page from physical
               inc qword[PTE_counter]                     ;counter ++
               cmp qword[PTE_counter], FIVE_TWELVE ;check if counter for PTE reached 512
               jl PTE_loop            ;if still less continue looping

          mov rax, qword[after_PTE_ptr]           ;move into rax 0x104000
          mov qword[PTE_ptr], rax                 ;connect pte ptr and after pte ptr
          add qword[after_PTE_ptr], MEM_PAGE_4K   ;increment with 4kb, to reserve a page for next pte table 

          ;update cr3
          mov rax, qword[PML4_ptr]
          mov cr3,rax

          add qword[PDT_ptr], CELL                ;incriment to next cell in pdt table
          inc qword[PDT_counter]                  ;counter++
          cmp qword[PDT_counter], FIVE_TWELVE     ;check if counter reached 512
          jl PDT_loop                             ;if still less continue looping
     mov rax, qword[after_PTE_ptr]                ;move into rax 0x104000         
     mov qword[PDT_ptr],rax                       ;connect pte ptr and after pte ptr     
     add qword[after_PTE_ptr], MEM_PAGE_4K        ;increment with 4kb, to reserve a page for next pte table   

     add qword[PDP_ptr], CELL                     ;incriment to next cell in pdp table
     inc qword[PDP_counter]                       ;counter++
     cmp qword[PDP_counter], FIVE_TWELVE          ;check if counter reached 512
     jl PDP_loop                                  ;if still less continue looping


add qword[PML4_ptr], CELL                         ;incriment to next cell in pml4 table
inc qword[PML4_counter]                           ;counter++
cmp qword[PML4_counter], FIVE_TWELVE              ;check if counter reached 512
jl PML4_loop                                      ;if still less continue looping

exit:               ;in case of bypassing max memory of type 1 or finishing the loops 
;update cr3 for the final time
mov rax, qword[PML4_ptr]
mov cr3,rax
popaq
ret