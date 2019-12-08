; The Command Register and trhe BASE I/O ports can be retrieved from the PCI BARs, but they are kind of standard and we will define them here for better code presentability
; When we write it is considered CR, and when we read what is returned is the AS Register
%define ATA_PRIMARY_CR_AS        0x3F6 ; ATA Primary Control Register/Alternate Status Port
%define ATA_SECONDARY_CR_AS      0x376 ; ATA Secondary Control Register/Alternate Status Port

%define ATA_PRIMARY_BASE_IO          0x1F0 ; ATA Primary Base I/O Port, up to 8 ports available to 0x1F7
%define ATA_SECONDARY_BASE_IO          0x170 ; ATA Primary Base I/O Port, up to 8 ports available to 0x177

%define ATA_MASTER              0x0     ; Mastrer Drive Indicator
%define ATA_SLAVE               0x1     ; SLave Drive Indicator

%define ATA_MASTER_DRV_SELECTOR    0xA0     ; Sent to ATA_REG_HDDEVSEL for master
%define ATA_SLAVE_DRV_SELECTOR     0xB0     ; sent to ATA_REG_HDDEVSEL for slave

; Commands to issue to the controller channels
%define ATA_CMD_READ_PIO          0x20      ; PIO LBA-28 Read
%define ATA_CMD_READ_PIO_EXT      0x24      ; PIO LBA-48 Read
%define ATA_CMD_READ_DMA          0xC8      ; DMA LBA-28 Read
%define ATA_CMD_READ_DMA_EXT      0x25      ; DMA LBA-48 Read
%define ATA_CMD_WRITE_PIO         0x30      ; PIO LBA-28 Write
%define ATA_CMD_WRITE_PIO_EXT     0x34      ; PIO LBA-48 Write
%define ATA_CMD_WRITE_DMA         0xCA      ; DMA LBA-28 Write
%define ATA_CMD_WRITE_DMA_EXT     0x35      ; DMA LBA-48 Write
%define ATA_CMD_IDENTIFY          0xEC      ; Identify Command

; Different Status values where each bit represents a status
%define ATA_SR_BSY 0x80             ; 10000000b     Busy
%define ATA_SR_DRDY 0x40            ; 01000000b     Drive Ready
%define ATA_SR_DF 0x20              ; 00100000b     Drive Fault
%define ATA_SR_DSC 0x10             ; 00010000b     Overlapped mde
%define ATA_SR_DRQ 0x08             ; 00001000b     Set when the drive has PIO data to transfer
%define ATA_SR_CORR 0x04            ; 00000100b     Corrected Data; always set to zero
%define ATA_SR_IDX 0x02             ; 00000010b     Index Status always set to Zero
%define ATA_SR_ERR 0x01             ; 00000001b     Error


; Ports offsets that can be used relative to the I/O base ports above.
; The use of the offset is defined by the ATA data sheet specifications.
%define ATA_REG_DATA       0x00
%define ATA_REG_ERROR      0x01
%define ATA_REG_FEATURES   0x01
%define ATA_REG_SECCOUNT0  0x02     ; Used to send the number of sectors to read, max 256
%define ATA_REG_LBA0       0x03     ; LBA0,1,2 are used to store the address of the first sector (24-bits)
%define ATA_REG_LBA1       0x04     ; Incase of LBA-28 the remaining 4 bits are sent as the higher 4 bits of
%define ATA_REG_LBA2       0x05     ; ATA_REG_HDDEVSEL when selecting the drive
%define ATA_REG_SECCOUNT1  0x02     ; Used for LBA-48 which allows 16 bit for the number of sector to be read, max 65536 
%define ATA_REG_LBA3       0x03     ; The rmaining 20-bit to acheive LBA-48 and nothing is written to  ATA_REG_HDDEVSEL
%define ATA_REG_LBA4       0x04
%define ATA_REG_LBA5       0x05
%define ATA_REG_HDDEVSEL   0x06     ; The register for selecting the drive, master of slave
%define ATA_REG_COMMAND    0x07     ; This register for sending the command to be performed after filling up the rest of the registers
%define ATA_REG_STATUS     0x07     ; This register is used to read the status of the channel


%define DISK_SECTOR_ADDRESS         137
%define DATABASE_MEMORY_ADDRESS     0x1400000



ata_pci_header times 256 db 0  ; A memroy space to store ATA Controller PCI Header (4*256)
; storing the chars after the conversion in a memory location after the database by 1 mega bytes
CHAR_CONVERSION_MEMORY_ADDRESS     dq       0x3724f80

; Indexed values
;semi-macros
ata_control_ports dw ATA_PRIMARY_CR_AS,ATA_SECONDARY_CR_AS,0 ;ATA control port --> primary &secondary control register and alternate status port
ata_base_io_ports dw ATA_PRIMARY_BASE_IO,ATA_SECONDARY_BASE_IO,0 ; I/O ports --> primary/secondary bases of ports
ata_slave_identifier db ATA_MASTER,ATA_SLAVE,0; Ata identifier --> whether its a master or slave
ata_drv_selector db ATA_MASTER_DRV_SELECTOR,ATA_SLAVE_DRV_SELECTOR,0 ; whether its a master or slave drive


;messages to be used
ata_error_msg       db "Error Identifying Drive",13,10,0
ata_identify_msg    db "Found Drive: ",0
lba_48_supported db 'LBA-48 Supported',0

search_key db '8086',0
ata_identify_buffer times 2048 db 0  ; A memroy space to store the 4 ATA devices identify details (4*512)
ata_identify_buffer_index dw 0x0
ata_channel db 0
ata_slave db 0  
str_found db 0

align 4


struc ATA_IDENTIFY_DEV_DUMP                     ; Starts at
.device_type                resw              1
.cylinders                  resw              1 ; 1
.gap0                       resw              1 ; 2
.heads                      resw              1 ; 3
.gap1                       resw              2 ; 4
.sectors                    resw              1 ; 6
.gap2                       resw              3 ; 7
.serial                     resw              10 ; 10
.gap3                       resw              3  ; 20
.fw_version                 resw              4  ; 23
.model_number               resw              20 ; 27
.gap4                       resw              2  ; 47
.capabilities               resw              1  ; 49       Bit-9 set for LBA Support, Bit-8 for DMA Support
.gap5                       resw              3  ; 50
.avail_bf                   resw              1  ; 53
.current_cyl                resw              1  ; 54
.current_hdr                resw              1  ; 55
.current_sec                resw              1  ; 56
.total_sec_obs              resd              1  ; 57
.gap6                       resw              1  ; 59
.total_sec                  resd              1  ; 60       Number of sectors when in LBA-28 mode
.gap7                       resw              1  ; 62
.dma_mode                   resw              1  ; 63
.gap8                       resw              16 ; 64
.major_ver_num              resw              1  ; 80
.minor_ver_num              resw              1  ; 81
.command_set1               resw              1  ; 82
.command_set2               resw              1  ; 83
.command_set3               resw              1  ; 84
.command_set4               resw              1  ; 85
.command_set5               resw              1  ; 86       Bit-10 is set if LBA-48 is supported
.command_set6               resw              1  ; 87
.ultra_dma_reporting        resw              1  ; 88
.gap9                       resw              11 ; 89
.lba_48_sectors             resq              1  ; 100      Number of sectors when in LBA-48 mode
.gap10                      resw              23 ; 104
.rem_media_status_notif     resw              1  ; 127
.gap11                      resw              48 ; 128
.curret_media_serial_number resw              1  ; 176
.gap12                      resw              78 ; 177
.integrity_word             resw              1  ; 255      Checksum
endstruc


ata_copy_pci_header:
;copy pci header to ata pci header
    pushaq
        mov rdi,ata_pci_header ;moves the ata pci header in to rdi
        mov rsi,pci_header ; moves the pci header in to rsi
        mov rcx, 0x20 ; preparing to repeat it 512 times using rep stosq
        xor rax, rax
        cld ; clears the direction flag --> decrementing rcx
        rep stosq
    popaq
    ret

select_ata_disk:              ; rdi = channel, rsi = master/slave
;write to channel port with offset hddevsel a number depending if its master or slave
    pushaq
        xor rax,rax ; makes sure that rax is empty
        mov dx,[ata_base_io_ports+rdi] ; moves the ATA IO ports into dx with the channel as an offset (rdi)
        add dx,ATA_REG_HDDEVSEL ; adding to dx the offset for selecting whether its master or slave
        mov al,byte [ata_drv_selector+rsi] ; Fetch the corresponding drive value, master/slave
        out dx,al ;writing dx on to the port
    popaq
    ret

ata_print_size:
    pushaq
        mov byte [ata_identify_buffer+39],0x0 ; move a zero in to byte #39 starting from ata_identify_buffer space
        ; printing the serial using video print
        mov rsi, ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.serial
        call video_print
        mov rsi,comma
        call video_print
        mov byte [ata_identify_buffer+54],0x0  ; move a zero in to byte #50 starting from ata_identify_buffer space
         ; printing the firmware version using video print
        mov rsi, ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.fw_version
        call video_print
        mov rsi,comma
        call video_print
        ; printing the number of LBA sectors using video print
        xor rdi,rdi
        mov rdi, qword [ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.lba_48_sectors]
        call video_print_hexa
        ;checking if LBA is supported or not
        mov ax, 0000010000000000b
        and ax,word [ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.command_set5]
        cmp ax,0x0
        je .out ; jump if LBA  is not supported
        ;else LBA  is supported
        mov rsi,comma
        call video_print 
        mov rsi,lba_48_supported
        call video_print
        .out:
        mov rsi,newline
        call video_print
    popaq
    ret


ata_identify_disk:              ; rdi = channel, rsi = master/slave
    pushaq
        
        ;move 0 to control port
        xor rax,00000000b                           ;disabling interrupts (refresh)
        mov dx,[ata_control_ports+rdi]              ;moving control ports (0->7) to dx
        out dx,al                                   ;write in control port the lower 8 bits of rax 

        ;return modified base port
        call select_ata_disk                        ;call the select disk function to identify the packet

        ;send out zero to sector count, lba0, lba1 and lba2
        ;to use lba28 mode
        xor rax,rax                                 ;zeroing rax
        mov dx,[ata_base_io_ports+rdi]              ;set the ports to be written into 
        add dx,ATA_REG_SECCOUNT0                    ;number of sectors to read
        out dx,al                                   ;write to the port to read number of sectors
        mov dx,[ata_base_io_ports+rdi]              ;change dx to write in the port to get lba
        add dx,ATA_REG_LBA0                         ;add lba0 offset (store address of 1st sector in 0x03)
        out dx,al                                   ;write to the port to get 1st 8 bits of 1st sector
        mov dx,[ata_base_io_ports+rdi]              ;change dx to write in the port to get lba
        add dx,ATA_REG_LBA1                         ;add lba1 offset (store address of 1st sector in 0x04)
        out dx,al                                   ;write to the port to get 2nd 8 bits of 1st sector
        mov dx,[ata_base_io_ports+rdi]              ;change dx to write in the port to get lba
        add dx,ATA_REG_LBA2                         ;add lba2 offset (Store address of 1st sector in 0x05)
        out dx,al                                   ;write to the port to get 3rd 8 bits of 1st sector
        
        ;set identify command
        mov dx,[ata_base_io_ports+rdi]              ;change dx to write in the port to get lba
        add dx,ATA_REG_COMMAND                      ;adding command offset
        mov al,ATA_CMD_IDENTIFY                     ;move the identify command 
        out dx,al                                   ;write in the port to get the identity
        
        ;read the status for the first time
        mov dx,[ata_base_io_ports+rdi]              ;change dx to get identity 
        add dx,ATA_REG_STATUS                       ;add offset of status
        in al, dx                                   ;read from port the status of ata
        cmp al, ATA_SR_ERR                          ;if less than 2, then an error occured
        je .error                                   ;goto error label

    .check_ready:
    ;loop to check if PIO is ready or there was an error

        ;check if error 0x01
        mov dx,[ata_base_io_ports+rdi]              ;change dx to read identity if ata
        add dx,ATA_REG_STATUS                       ;adding offset of status
        in al, dx                                   ;read from port the status
        xor rcx,rcx                                 ;zeroing rcx
        mov cl,ATA_SR_ERR                           ;move 1 in cl 
        and cl,al                                   ;and with the status
        cmp cl,ATA_SR_ERR                           ;compare, as if the lsb is one then there was an error
        je .error                                   ;goto error label
        
        ;check for PIO
        mov cl,ATA_SR_DRQ                           ;move 8 in cl
        and cl,al                                   ;and with status
        cmp cl,ATA_SR_DRQ                           ;compare, if this (4th bit from left) is 1 then go to check if read
    jne .check_ready                                ;goto check ready if 4th bit isnt 1
    
    jmp .ready                                      ;else, go to ready label

    .error:
    ;in case of error
        mov rsi,ata_error_msg                       ;move to rsi the error message to print
        call video_print                            ;call printing function
        jmp .out                                    ;goto out label and return from function

    .ready:
    ;in case of being ready
        mov rsi,ata_identify_msg                    ;move to rsi the identify message             
        call video_print                            ;call printing function
        mov rdx,[ata_base_io_ports+rdi]             ;move to rdx base io added to rdi offset
        mov si,word [ata_identify_buffer_index]     ;move identity buffer index to si
        mov rdi,ata_identify_buffer                 ;move identity buffer to rdi
        mov rcx, 256                                ;start a counter with 256
        xor rbx,rbx                                 ;zeroing rbx
        rep insw                                    ;loop in store word 
        add word [ata_identify_buffer_index],256    ;increment buffer by 256
        call ata_print_size                         ;call print size function
           
    .out:
        popaq
        ret

read_disk_sectors:
pushaq

xor rax, rax 
xor rdi, rdi
xor rsi, rsi
;1) Disable interrupts
xor rax, 00000010b
mov dx, [ata_control_ports+rdi]
add dx, ATA_REG_COMMAND
out dx, al
;2) Select disk, move left most 4 bits of sector address to right most bits of HDDEVSEL register
call select_ata_disk
mov rbx, 137   ;sector address 
mov al, 0x0
shr rbx, 24
and rbx, 0x0F
mov al, bl
xor rdi, rdi 
mov dx,[ata_base_io_ports+rdi] ; moves the ATA IO ports into dx with the channel as an offset (rdi)
add dx,ATA_REG_HDDEVSEL ; adding to dx the offset 
out dx, al

;3)move 24 bits of the sector address in to LBA0, LBA1, LBA2
;4) move the maximum number of sectors (256 --> LBA 28) in to ATA_REG_SECCOUNT0
mov rax,256
mov dx,[ata_base_io_ports+rdi]
add dx, ATA_REG_SECCOUNT0
out dx, al

mov rax,DISK_SECTOR_ADDRESS
and rax,0xFF
mov dx,[ata_base_io_ports+rdi]
add dx, ATA_REG_LBA0
out dx, al

mov rax,DISK_SECTOR_ADDRESS
shr rax,8
and rax,0xFF
mov dx,[ata_base_io_ports+rdi]
add dx, ATA_REG_LBA1
out dx, al

mov rax,DISK_SECTOR_ADDRESS
shr rax,16
and rax,0xFF
mov dx,[ata_base_io_ports+rdi]
add dx, ATA_REG_LBA2
out dx, al

mov dx,[ata_base_io_ports+rdi]              ;change dx to write in the port to get lba
add dx,ATA_REG_COMMAND                      ;adding command offset
mov al,ATA_CMD_READ_PIO                     ;move the write command for LBA28
out dx,al
mov r9, 2336            ;number of sectors to read 
mov r13, 137            ;First sector address 
xor r11, r11            ;memory offset

read_loop:
mov r10, 65536          ;loop counter (number of words in 256 sectors)
check_ready:
    ;loop to check if PIO is ready or there was an error

        ;check if error 0x01
        mov dx,[ata_base_io_ports+rdi]              ;change dx to read identity if ata
        add dx,ATA_REG_STATUS                       ;adding offset of status
        in al, dx                                   ;read from port the status
        xor rcx,rcx                                 ;zeroing rcx
        mov cl,ATA_SR_ERR                           ;move 1 in cl 
        and cl,al                                   ;and with the status
        cmp cl,ATA_SR_ERR                           ;compare, as if the lsb is one then there was an error
        je error                                   ;goto error label
        
        ;check for PIO
        mov cl,ATA_SR_DRQ                           ;move 8 in cl
        and cl,al                                   ;and with status
        cmp cl,ATA_SR_DRQ                           ;compare, if this (4th bit from left) is 1 then go to check if read
    jne check_ready                                ;goto check ready if 4th bit isnt 1
    
    jmp ready_to_read                                      ;else, go to ready label

ready_to_read:
mov dx, [ata_base_io_ports+rdi] 
in ax, dx 
mov word[DATABASE_MEMORY_ADDRESS+r11], ax
dec r10
add r11, 2
cmp r10, 0
jg ready_to_read

mov r12, 256
sub r9, r12           ;number of sectors 
cmp r9, 0
jl end1
;Put number of sectors to read in SECCOUNT0
mov rax,256
mov dx,[ata_base_io_ports+rdi]
add dx, ATA_REG_SECCOUNT0
out dx, al

cont1:
xor rdi, rdi 
call select_ata_disk
add r13,256
mov rbx, r13           ;sector address   
mov al, 0x0
shr rbx, 24
and rbx, 0x0F
mov al, bl
xor rdi, rdi 
mov dx,[ata_base_io_ports+rdi] ; moves the ATA IO ports into dx with the channel as an offset (rdi)
add dx,ATA_REG_HDDEVSEL ; adding to dx the offset 
out dx, al

mov rax,r13
and rax,0xFF
mov dx,[ata_base_io_ports+rdi]
add dx, ATA_REG_LBA0
out dx, al

mov rax,r13
shr rax,8
and rax,0xFF
mov dx,[ata_base_io_ports+rdi]
add dx, ATA_REG_LBA1
out dx, al

mov rax,r13
shr rax,16
and rax,0xFF
mov dx,[ata_base_io_ports+rdi]
add dx, ATA_REG_LBA2
out dx, al

mov dx,[ata_base_io_ports+rdi]              ;change dx to write in the port to get lba
add dx,ATA_REG_COMMAND                      ;adding command offset
mov al,ATA_CMD_READ_PIO                     ;move the write command for LBA28
out dx,al
jmp read_loop

error:
    ;in case of error
        mov rsi,ata_error_msg                       ;move to rsi the error message to print
        call video_print                            ;call printing function

end1:
;getting the vendor id
mov r15, qword[pci_header_memory + PCI_CONF_SPACE.vendor_id]
;mov r15 ,0x0010
;add r15, PCI_CONF_SPACE.vendor_id

mov r10, 2 ; counter for the following loop (4 chars)
xor rax, rax
xor r12, r12
xor r13 , r13 ; offset for the CHAR_CONVERSION_MEMORY_ADDRESS
convert_to_char:
mov al, byte[r15]
;Check upper 4bits then lower 4 bits


mov r8b, al
; mov rdi, r8
; call video_print_hexa
and r8b, 1111b ;Get the lower 4 bits
call check_char ;takes value in r8b and converts it and stores it
inc r13
mov r8b, al
shr r8b, 4 ;Get the upper 4 bits
call check_char ;takes value in r8b and converts it and stores it


cont_convert_to_char:
inc r15 ; inc r15 by 1 to get the next byte
inc r13
;add r13, 8
dec r10 ; dec counter
cmp r10, 1 
jge convert_to_char

xor rsi, rsi ; make sure rsi is empty
mov rsi,  msg_finished_conv ; move the vendor id from the memory location to rsi 
call video_print ; print it to make sure the conversion was correct

xor rsi, rsi ; make sure rsi is empty
mov rsi,  newline ; move the vendor id from the memory location to rsi 
call video_print ; print it to make sure the conversion was correct


xor rsi, rsi ; make sure rsi is empty
mov rsi,  msg_char ; move the vendor id from the memory location to rsi 
call video_print ; print it to make sure the conversion was correct

xor rsi, rsi ; make sure rsi is empty
mov rsi, qword[CHAR_CONVERSION_MEMORY_ADDRESS] ; move the vendor id from the memory location to rsi 
call video_print ; print it to make sure the conversion was correct
; mov rsi, qword[CHAR_CONVERSION_MEMORY_ADDRESS] ; move the vendor id from the memory location to rsi 
; call video_print ; print it to make sure the conversion was correct

xor rsi, rsi ; make sure rsi is empty
mov rsi,  newline ; move the vendor id from the memory location to rsi 
call video_print ; print it to make sure the conversion was correct


jmp begin_comparison  ; begin the comparison between the found vendor id (from pci) and the database
    check_char:
        pushaq
        cmp r8b, 9
        ;cmp al, 9
        jle number
        character: ;if not then number is a hexa
        sub r8b,10 ;make a->0 b->1 c->2 d->3 e->4 f->5
        add r8b,97 ;add by 97 to get equivalent lower case
        ; sub al,10 ;make a->0 b->1 c->2 d->3 e->4 f->5
        ; add al,'a' ;add by 97 to get equivalent lower case
        jmp next
        number:
        add r8b, 48 ; add the ascii of 0
        ;add al,48 ; add the ascii of 0
        next:
        mov byte[CHAR_CONVERSION_MEMORY_ADDRESS+r13], r8b
        ;mov byte[CHAR_CONVERSION_MEMORY_ADDRESS+r13], al
        popaq
        ret
;------------------------------------------------------------------------------------------------------------------------------;              
; mov edi, dword[r15] 
; call video_print_hexa
;lea rsi, [search_key]
;------------------------------------------------------------------------------------------------------------------------------;              

begin_comparison:
xor rsi, rsi ; make sure rsi is empty
mov rsi, msg_begin_comp ; move the vendor id from the memory location to rsi 
call video_print ; print it to make sure the conversion was correct

xor rsi, rsi ; make sure rsi is empty
mov rsi,  newline ; move the vendor id from the memory location to rsi 
call video_print ; print it to make sure the conversion was correct

xor rsi, rsi ; make sure rsi is empty
mov rsi, CHAR_CONVERSION_MEMORY_ADDRESS ; store the vendor id address in rsi 
mov rdi, DATABASE_MEMORY_ADDRESS ; store the address of the database in rdi ;TEMP COMMENT
;mov rdi, search_key


mov r14, rdi
add r14, 0x123ef9c ; adding the size of the database to its base address (stopping condition)


loop2:
mov rcx,4
call comp_str 
cmp byte[str_found], 0x1
je found
inc rdi
cmp rdi,r14
jl loop2

jmp not_found

comp_str:
pushaq
        mov byte[str_found],0x0
        loop:
            mov rax,rdi
            mov rbx,rsi
            add rax,rcx
            add rbx,rcx
            dec rax
            dec rbx
            mov dl,byte[rax]
            cmp dl,byte[rbx]
            jne quit
            dec rcx
            cmp rcx,0
        jne loop
        mov byte[str_found],0x1
        jmp quit

        quit:
popaq
ret

    found:
    xor rax, rax
    xor rsi, rsi
    mov rsi, msg_found_deviceID3
    call video_print

    xor rsi, rsi
    mov rsi, newline
    call video_print

    xor rsi, rsi
    xor rax, rax
    mov al,byte[rdi+3]
    ;mov ax, word[rdi+1]
    ;mov word[rsi], ax
    mov byte[rsi], al
    call video_print

    xor rsi, rsi
    xor rax, rax
    mov al,byte[rdi+2]
    ;mov ax, word[rdi+1]
    ;mov word[rsi], ax
    mov byte[rsi], al
    call video_print

    xor rsi, rsi
    xor rax, rax
    mov al,byte[rdi+1]
    ;mov ax, word[rdi+1]
    ;mov word[rsi], ax
    mov byte[rsi], al
    call video_print

    xor rsi, rsi
    xor rax, rax
    mov al,byte[rdi]
    ;mov ax, word[rdi+1]
    ;mov word[rsi], ax
    mov byte[rsi], al
    call video_print

    xor rsi, rsi
    mov rsi, newline
    call video_print


    xor rsi, rsi
    mov rsi, newline
    call video_print    

    xor rsi, rsi
    xor rax, rax
    mov rax,vendor_name
    mov rsi, rax
    call video_print
    

    xor rsi, rsi
    mov rsi, newline
    call video_print


    xor rsi, rsi
    xor rax, rax
    mov rax,msg_no_devices
    mov rsi, rax
    call video_print


    xor rsi, rsi
    mov rsi, newline
    call video_print  

    jmp EXIT

    not_found:
    mov rsi, msg_found_deviceID4
    call video_print
    xor rsi, rsi  
    jmp EXIT

    ;loop2:
; mov rcx,4
; call comp_str
; cmp byte[skip_line], 0x1
; call skipLine
; cmp byte[str_found], 0x1
; je found
; inc rdi
; cmp rdi,r14
; jl loop2

; jmp not_found

; comp_str:
; pushaq
;         mov byte[str_found],0x0
;         mov byte[skip_line], 0x0
;         loop:
;             mov rax,rdi
;             mov rbx,rsi
;             add rax,rcx
;             add rbx,rcx
;             dec rax
;             dec rbx
;             mov dl,byte[rax]
;             cmp dl, 10
;              je check_tab
;              return:
;             ; cmp dl, 0xF
;             ; jle letter
;             ;cont8:
;             cmp dl,byte[rbx]
;             jne quit
;             dec rcx
;             cmp rcx,4
;         jne loop
;         mov byte[str_found],0x1
;         jmp quit
;         check_tab:
;         inc rax
;         mov dl, byte[rax]
;         cmp dl, '   '
;         je skip 
;         dec rax
;         mov dl, byte[rax]
;         jmp return

;         skip:
;         mov byte[skip_line], 0x1
;         popaq
;         ret

;         quit:
; popaq
; ret
; skipLine:
; pushaq
; skiploop:
;     inc rdi
;     mov bl, byte[rdi]
;     cmp bl, 10
;     jne skiploop

; popaq
; ret


EXIT:
popaq
ret


