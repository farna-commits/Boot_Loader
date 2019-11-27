[ORG 0x10000]




[BITS 64]


Kernel:



channel_loop:
    mov qword [ata_master_var],0x0
    master_slave_loop:
        mov rdi,[ata_channel_var]
        mov rsi,[ata_master_var]
        call ata_identify_disk
        inc qword [ata_master_var]
        cmp qword [ata_master_var],0x2
        jl master_slave_loop

    inc qword [ata_channel_var]
    inc qword [ata_channel_var]
    cmp qword [ata_channel_var],0x4
    jl channel_loop



call video_cls
call init_idt
call setup_idt


call page_table         ;call page table function
call video_cls
mov rsi,msg_scan_device
call video_print
bus_loop:
    device_loop:
        function_loop:
            call get_pci_device
            check:
            mov ax, word[pci_header + PCI_CONF_SPACE.device_id]
            cmp ax, 0xffff
            je noCopy
            ;call copy_to_memory
            mov r14, qword[pci_header_memory]
            add r14, qword[pci_header_memory_offset]
            mov r15,r14
            mov r14, pci_header
            mov rcx, 32
            .loop:
            mov r10,qword[r14]
            mov qword[r15], r10
            dec rcx
            cmp rcx,0
            je .exit
            jmp .loop

            .exit:
            ; mov rdi, qword[r15 + PCI_CONF_SPACE.device_id]
            ; call bios_print_hexa
            ; mov rsi,newline
            ; call video_print
            mov rsi, msg_new_device
            call video_print
            call print_deviceID
            call print_vendorID
            add qword[pci_header_memory_offset], 0xff     ;increment by 8 bytes (2 rows)

            noCopy:
            inc byte [function]
            cmp byte [function],8
            jne function_loop

        inc byte [device]
        mov byte [function],0x0
        cmp byte [device],32
        jne device_loop
    inc byte [bus]
    mov byte [device],0x0
    cmp byte [bus],255
    jne bus_loop

    ; mov qword[pci_header_memory_offset] , 0
    ; mov r9, 32
    ; loop6:
    ; mov r15, qword[pci_header_memory]
    ; add r15, qword[pci_header_memory_offset]
    ; mov r8, qword[r15+ PCI_CONF_SPACE.vendor_id]
    ; mov rdi, r8
    ; call bios_print_hexa
    ; ; mov rsi, newline
    ; ; call video_print

    ; add qword[pci_header_memory_offset],255
    ; dec r9
    ; cmp r9,0
    ; je exit3
    ; jmp loop6
    exit3:

    


;call video_cls
; mov rsi, hello_world_str
; call video_print

;done
;mov rsi, newline
;call video_print
;mov rsi, hello_world_str2
;call video_print

kernel_halt: 
    hlt
    jmp kernel_halt


;*******************************************************************************************************************
      %include "sources/includes/third_stage/pushaq.asm"
      %include "sources/includes/third_stage/pic.asm"
      %include "sources/includes/third_stage/idt.asm"
      %include "sources/includes/third_stage/pci.asm"
      %include "sources/includes/third_stage/video.asm"
      %include "sources/includes/third_stage/pit.asm"
      %include "sources/includes/third_stage/ata.asm"
      %include "sources/includes/third_stage/pagetable2.asm"
    
;*******************************************************************************************************************


colon db ':',0
comma db ',',0
newline db 13,0

end_of_string  db 13        ; The end of the string indicator
start_location   dq  0x0  ; A default start position (Line # 8)

    hello_world_str db 'bypassed page table',13, 0   ;indication that we reached the third stage
    msg_mapping db ' Mapping the whole memory: ',13, 0   ;indication that we reached the third stage

    memory_tester_success db 'Memory Tester Succeeded!',13, 0   ;indication that we reached the third stage
    idt_default_msg db 'idt default handler!',13, 0   ;indication that we reached the third stage
    dot db '.'

    ata_channel_var dq 0
    ata_master_var dq 0

    bus db 0
    device db 0
    function db 0
    offset db 0
    hexa_digits       db "0123456789ABCDEF"         ; An array for displaying hexa decimal numbers
    ALIGN 4


;times 8192-($-$$) db 0