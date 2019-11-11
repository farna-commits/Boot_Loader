%define MEM_REGIONS_SEGMENT         0x2000
%define PTR_MEM_REGIONS_COUNT       0x0000 
%define PTR_MEM_REGIONS_TABLE       0x18
;%define PTR_MEM_REGIONS_COUNT       0x1000 
;%define PTR_MEM_REGIONS_TABLE       0x1018
%define MEM_MAGIC_NUMBER            0x0534D4150                
    memory_scanner:
            pusha                                       ; Save all general purpose registers on the stack
            ; were going to use function 0xE820 of interrupt 0x15
            ;the function expects certain values in some registers
            ;eax = 0xe820|ebx=0|es:di should contain the address in memory that the function will load the mem info into
            ;ecx=24|edx = 0x0534d4150|(es:di+20) = 0x1
            mov ax,MEM_REGIONS_SEGMENT ;mov 0x2000 into ax first as we cant move to es directly
            mov es,ax   ;move to es
            xor ebx,ebx     ;set ebx =0
            mov [es:PTR_MEM_REGIONS_COUNT],word 0x0 ;let the value 0x2000:0x0000 to be a counter of memory regions
            mov di, PTR_MEM_REGIONS_TABLE   ;set di as 0x18 to store memory region tables
            .memory_scanner_loop:
            mov edx,MEM_MAGIC_NUMBER    ;set edx with the magic number 
            mov word [es:di+20], 0x1    ;(es:di+20) = 0x1
            mov eax, 0xE820 ;eax = 0xe820
            mov ecx,0x18    ;set size of memory buffer
            int 0x15    ;issue the interrupt
            jc .memory_scan_failed  ;if carry flag is set then the scan failed
            cmp eax,MEM_MAGIC_NUMBER    ;if after the interrupt went right then eax should have the magic numb
            jnz .memory_scan_failed     ;yet if its equal 0 then scan failed
            add di,0x18     ;incriment by 24 to point to next entry in the memory region
            inc word [es:PTR_MEM_REGIONS_COUNT] ; incriment the counter
            cmp ebx,0x0 ;check if ebx is 0, if it is then no more regions to scan
            jne .memory_scanner_loop    ;keep looping if ebx isnt 0
            jmp .finish_memory_scan ;else jump to finish to retrieve registers and return
            .memory_scan_failed:
            ;print that there was an error and exit
            mov si,memory_scan_failed_msg   ;move to si the string we want to print 
            call bios_print ;calling the print function 
            jmp hang ;hang the cpu
            .finish_memory_scan:    ;label after finishing scanning succesfully
            popa                                        ; Restore all general purpose registers from the stack
            ret

    print_memory_regions:
            pusha
            mov ax,MEM_REGIONS_SEGMENT      ;move 0x2000 into ax to move it to es
            mov es,ax                       ;set es = 0x2000
            xor edi,edi                     ;initilize edi with 0
            mov di,word [es:PTR_MEM_REGIONS_COUNT]  ;move into di the counter of memory regions to print in hexa
            call bios_print_hexa            ;print number of memory regions in hexa
            mov si,newline                  ;move into si \n to print a newline
            call bios_print                 ;call the print function
            mov ecx,[es:PTR_MEM_REGIONS_COUNT]  
            mov si,0x1018 
            .print_memory_regions_loop:
                mov edi,dword [es:si+4]
                call bios_print_hexa_with_prefix
                mov edi,dword [es:si]
                call bios_print_hexa
                push si
                mov si,double_space
                call bios_print
                pop si

                mov edi,dword [es:si+12]
                call bios_print_hexa_with_prefix
                mov edi,dword [es:si+8]
                call bios_print_hexa

                push si
                mov si,double_space
                call bios_print
                pop si

                mov edi,dword [es:si+16]
                call bios_print_hexa_with_prefix


                push si
                mov si,newline
                call bios_print
                pop si
                add si,0x18

                dec ecx
                cmp ecx,0x0
                jne .print_memory_regions_loop
            popa
            ret