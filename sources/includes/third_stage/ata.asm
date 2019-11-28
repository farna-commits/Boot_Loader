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

ata_pci_header times 256 db 0  ; A memroy space to store ATA Controller PCI Header (4*256)
; Indexed values
;semi-macros
ata_control_ports dw ATA_PRIMARY_CR_AS,ATA_SECONDARY_CR_AS,0
ata_base_io_ports dw ATA_PRIMARY_BASE_IO,ATA_SECONDARY_BASE_IO,0
ata_slave_identifier db ATA_MASTER,ATA_SLAVE,0
ata_drv_selector db ATA_MASTER_DRV_SELECTOR,ATA_SLAVE_DRV_SELECTOR,0


;messages to be used
ata_error_msg       db "Error Identifying Drive",13,10,0
ata_identify_msg    db "Found Drive: ",0
lba_48_supported db 'LBA-48 Supported',0


ata_identify_buffer times 2048 db 0  ; A memroy space to store the 4 ATA devices identify details (4*512)
ata_identify_buffer_index dw 0x0
ata_channel db 0
ata_slave db 0  

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
        mov rdi,ata_pci_header
        mov rsi,pci_header
        mov rcx, 0x20
        xor rax, rax
        cld
        rep stosq
    popaq
    ret

select_ata_disk:              ; rdi = channel, rsi = master/slave
;write to channel port with offset hddevsel a number depending if its master or slave
    pushaq
        xor rax,rax
        mov dx,[ata_base_io_ports+rdi]
        add dx,ATA_REG_HDDEVSEL
        mov al,byte [ata_drv_selector+rsi] ; Fetch the corresponding drive value, master/slave
        out dx,al
    popaq
    ret

ata_print_size:
    pushaq
        mov byte [ata_identify_buffer+39],0x0
        mov rsi, ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.serial
        call video_print
        mov rsi,comma
        call video_print
        mov byte [ata_identify_buffer+50],0x0
        mov rsi, ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.fw_version
        call video_print
        mov rsi,comma
        call video_print
        xor rdi,rdi
        mov rdi, qword [ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.lba_48_sectors]
        call bios_print_hexa
        mov ax, 0000010000000000b
        and ax,word [ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.command_set5]
        cmp ax,0x0
        je .out
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