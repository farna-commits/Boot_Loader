%define PIT_DATA0       0x40
%define PIT_DATA1       0x41
%define PIT_DATA2       0x42
%define PIT_COMMAND     0x43
%define PIT_COUNT       1000


pit_counter       dq    0x0               ; A variable for counting the PIT ticks
print_counter     dq    0x0               ; counter for incrementing the print

handle_pit:
      pushaq
            
            mov rdi,[pit_counter]         ; Value to be printed in hexa
            cmp qword[pit_counter], PIT_COUNT
            jne .skip

            add qword[print_counter],PIT_COUNT
            mov rdi, qword[print_counter]
            call video_print_hexa          ; Print pit_counter in hexa
            mov rsi,newline
            call video_print
            mov qword[pit_counter],0
            .skip:
            inc qword [pit_counter]       ; Increment pit_counter
      popaq
      ret



configure_pit:
    pushaq
      mov rdi,32
      mov rsi, handle_pit
      call register_idt_handler
      mov al,00110110b
      out PIT_COMMAND,al
      xor rdx,rdx
      mov rcx,50
      mov rax,1193180
      div rcx
      out PIT_DATA0,al
      mov al,ah
      out PIT_DATA0,al
    popaq
    ret