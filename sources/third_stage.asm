[ORG 0x10000]




[BITS 64]


Kernel:

bus_loop:
    device_loop:
        function_loop:
            call get_pci_device
            inc byte [function]
            cmp byte [function],8
        jne device_loop
        inc byte [device]
        mov byte [function],0x0
        cmp byte [device],32
        jne device_loop
    inc byte [bus]
    mov byte [device],0x0
    cmp byte [bus],255
    jne bus_loop

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
    

call init_idt
call setup_idt
call page_table         ;call page table function 

;a code to test
mov r12,0
mov rbx, qword[after_PTE_ptr]
.testLoop:
mov rax,rbx
mov byte[rax],'A'
inc rax
mov byte[rax],13
inc rax
mov rsi, qword[after_PTE_ptr]
call video_print

inc r12
cmp r12,qword[max]
je gohere
cmp rax, qword[max]
jl .testLoop

;test message to show that we made out elhamdulellah
gohere:
mov rsi,hello_world_str6
call video_print




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
      ;%include "sources/includes/third_stage/full_page_table.asm"
      %include "sources/includes/third_stage/pagetable2.asm"
      ;%include "sources/includes/third_stage/page3.asm"

;*******************************************************************************************************************


colon db ':',0
comma db ',',0
newline db 13,0

end_of_string  db 13        ; The end of the string indicator
start_location   dq  0x0  ; A default start position (Line # 8)

    hello_world_str db 'bypassed page table',13, 0   ;indication that we reached the third stage
    hello_world_str2 db 'reached the end',13, 0   ;indication that we reached the third stage
    hello_world_str3 db 'finished pdt loopp',13, 0   ;indication that we reached the third stage
    hello_world_str4 db 'start pdt loopp',13, 0   ;indication that we reached the third stage
    hello_world_str5 db '512 testt',13, 0   ;indication that we reached the third stage
    hello_world_str6 db 'Memory Tester Succeed',13, 0   ;indication that we reached the third stage

    ata_channel_var dq 0
    ata_master_var dq 0

    bus db 0
    device db 0
    function db 0
    offset db 0
    hexa_digits       db "0123456789ABCDEF"         ; An array for displaying hexa decimal numbers
    ALIGN 4


times 8192-($-$$) db 0