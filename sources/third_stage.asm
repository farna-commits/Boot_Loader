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
call video_cls

;Memory Tester Function
xor r12,r12
mov rbx, qword[after_PTE_ptr]   ;starting the test at location 0x104000
xor rax,rax
mov rax,rbx
.testLoop:

mov byte[rax],'T'
inc rax
mov byte[rax],13
inc rax
mov rsi, qword[after_PTE_ptr]

call video_print               ;uncomment this to see a letter for each memory location

inc r12
cmp r12, 2000
jge gohere
cmp rax, qword[max]
jl .testLoop
; mov rdi, 0xAAA
; ;for checking hexa only scrollll
; looop:
; mov rdi, 13
; call bios_print_hexa
; mov rdi, 20
; call bios_print_hexa
; add r12, 2
; cmp r12, 170
; je gohere
; jmp looop

; ;test message to show that we mapped the whole memory to the max without page faults
 gohere:
mov rdi,0xFFFFFFFFF
call bios_print_hexa
; ; mov rdi,0xFFFFFFFFF
; ; call bios_print_hexa
; ; mov rdi,0xFFFFFFFFF
; ; call bios_print_hexa
; ; mov rdi,0xFFFFFFFFF
; ; call bios_print_hexa
; ; mov rdi,0xFFFFFFFFF
; ; call bios_print_hexa
; ; mov rdi,0xFFFFFFFFF
; ; call bios_print_hexa
; mov r13, 0
; ;for testing video w hexa m3 b3dehom
; looooop:
; mov rsi, memory_tester_success
; call video_print
; mov rdi,0xFFFFFFFFF
; call bios_print_hexa
; mov rsi, memory_tester_success
; call video_print
; add r13, 2
; cmp r13, 40
; jl looooop
; ;for extra checking en kolo tmam
; mov rsi, hello_world_str2
; call video_print

; mov rdi,0xFFFFFFFFF
; call bios_print_hexa


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
    hello_world_str2 db 'reached the end',13, 0   ;indication that we reached the third stage
    hello_world_str3 db 'finished pdt loopp',13, 0   ;indication that we reached the third stage
    hello_world_str4 db 'start pdt loopp',13, 0   ;indication that we reached the third stage
    hello_world_str5 db '512 testt',13, 0   ;indication that we reached the third stage
    memory_tester_success db 'Memory Tester Succeeded!',13, 0   ;indication that we reached the third stage

    ata_channel_var dq 0
    ata_master_var dq 0

    bus db 0
    device db 0
    function db 0
    offset db 0
    hexa_digits       db "0123456789ABCDEF"         ; An array for displaying hexa decimal numbers
    ALIGN 4


times 8192-($-$$) db 0