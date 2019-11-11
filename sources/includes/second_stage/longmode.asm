%define CODE_SEG     0x0008         /* Code segment selector in GDT */
%define DATA_SEG     0x0010         /* Data segment selector in GDT */
%define PAGE_TABLE_EFFECTIVE_ADDRESS        0x1000


switch_to_long_mode:

    ;Configuring Control Register CR4 to be 10100000 (enabling processor operations and extensions )
    mov eax, 10100000b      ;set the PAE and PGE bits to 1 (bit 5 and 7)
    mov cr4, eax            ;store eax to cr4

    ;Configuring Control Register CR3 to be 0x1000 (Pointing it to first cell in our level 4 page table PML4)
    mov edi,PAGE_TABLE_EFFECTIVE_ADDRESS    ;we cant set cr3 directly so do a work around
    mov edx, edi
    mov cr3, edx                            ;point cr3 to 0x1000 (first cell in PML4)

    ;Configuring Extended Feature Enable Register EFER (to set long mode bit to enable it)
    mov ecx, 0xC0000080     ;mov into ecx the EFER register number 
    rdmsr       ;read model specific register which is here EFER (0xC0000080)
    or eax, 0x00000100  ;set the long mode enabled LME bit to 1 (its the 8th bit)
    wrmsr       ;write model specific register 

    ;Configuring Control Register CR0   (enables paging (bit 31) and protected mode (bit 0) )
    mov ebx, cr0    ;extract value of cr0
    or ebx,0x80000001 ;set bit 31(paging) and bit 0 (protected) to 1
    mov cr0, ebx        ;store in cr0 after modifying 
    
    ret