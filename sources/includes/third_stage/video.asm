;*******************************************************************************************************************
bios_print_hexa:  ; A routine to print a 16-bit value stored in di in hexa decimal (4 hexa digits)
pushaq
xor r12, r12
mov rbx,0x0B8000          ; set BX to the start of the video RAM
  mov r9, 0
    mov r10, r9  ;first row
    add r9, 160  ;second row
    mov r13, 3998
    mov r12, 0     ;counter for scroll
    cmp [start_location], r13
    mov rcx,0x10 ;to avoid disruption of the loop if newline was detected in the middle of the loop
    jg scroll
   
                                   ; Set loop counter for 4 iterations, one for each digit
    cont3:
;mov es,bx               ; Set ES to the start of teh video RAM
    mov rbx,0x0B8000 
    add bx,[start_location] ; Store the start location for printing in BX
    
    ;mov rbx,rdi                                 ; DI has the value to be printed and we move it to bx so we do not change ot
    .loop:                                    ; Loop on all 4 digits
            mov rsi,rdi                           ; Move current bx into si
            shr rsi,0x3C                          ; Shift SI 60 bits right 
            mov al,[hexa_digits+rsi]             ; get the right hexadcimal digit from the array           
            mov byte [rbx],al     ; Else Store the charcater into current video location
            inc rbx                ; Increment current video location
            mov byte [rbx],1Fh    ; Store Blue Backgroun, Yellow font color
            inc rbx                ; Increment current video location
            inc qword[start_location]   ;for the character
            inc qword[start_location]   ;for the color
            
            shl rdi,0x4                          ; Shift bx 4 bits left so the next digits is in the right place to be processed
            dec rcx                              ; decrement loop counter
            cmp [start_location], r13
            jg scroll
            cmp rcx,0x0                          ; compare loop counter with zero.
            jg .loop                            ; Loop again we did not yet finish the 4 digits
    jmp end
    scroll:
    xor r12, r12
    mov r14, 0xB8000
    mov r15, 0xB8000
    add r14, r10
    add r15, r9 ;Add 160 to move to next line
    scroll_loop:
        mov al, byte[r15] ;place what is in next line 
        mov byte[r14], al ;place it in previous line
        inc r14 ;increment both to advance to next character
        inc r15
        inc r12
        cmp r12, 4000       ;msh 3aref leh msh 3998 (79,24)
        jl scroll_loop
        ;sub qword[start_location], 160
        mov qword[start_location], 3840     ;offset to start from the last letter of the last line
        jmp cont3
end:
    ;add [start_location],word 0x20
    popaq
    ret
;*******************************************************************************************************************


video_print:
    pushaq
    mov rbx,0x0B8000          ; set BX to the start of the video RAM
    ;mov es,bx               ; Set ES to the start of teh video RAM
    add bx,[start_location] ; Store the start location for printing in BX

    xor rcx,rcx
video_print_loop:           ; Loop for a character by charcater processing
    lodsb                   ; Load character pointer to by SI into al
    cmp al,13               ; Check  new line character to stop printing
    je out_video_print_loop ; If so get out
    cmp al,0                ; Check  new line character to stop printing
    je out_video_print_loop1 ; If so get out
    mov byte [rbx],al     ; Else Store the charcater into current video location
    inc rbx                ; Increment current video location
    mov byte [rbx],1Fh    ; Store Blue Backgroun, Yellow font color
    inc rbx                ; Increment current video location
                            ; Each position on the screen is represented by 2 bytes
                            ; The first byte stores the ascii code of the character
                            ; and the second one stores the color attributes
                            ; Foreground and background colors (16 colors) stores in the
                            ; lower and higher 4-bits
    inc rcx
    inc rcx
    jmp video_print_loop    ; Loop to print next character
out_video_print_loop:
    xor rax,rax
    mov ax,[start_location] ; Store the start location for printing in AX
    mov r8,160
    xor rdx,rdx
    add ax,0xA0             ; Add a line to the value of start location (80 x 2 bytes)
    div r8
    xor rdx,rdx
    mul r8
    mov [start_location],ax
    jmp finish_video_print_loop
out_video_print_loop1:
    mov ax,[start_location] ; Store the start location for printing in AX
    add ax,cx             ; Add a line to the value of start location (80 x 2 bytes)
    mov [start_location],ax

finish_video_print_loop:
    popaq
ret