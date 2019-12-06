%define MASTER_PIC_COMMAND_PORT     0x20
%define SLAVE_PIC_COMMAND_PORT      0xA0
%define MASTER_PIC_DATA_PORT        0x21
%define SLAVE_PIC_DATA_PORT         0xA1


    configure_pic:
        pushaq
            mov al,11111111b
            out MASTER_PIC_DATA_PORT,al
            out SLAVE_PIC_DATA_PORT,al
            mov al,00010001b
            out MASTER_PIC_COMMAND_PORT,al
            out SLAVE_PIC_COMMAND_PORT,al

            mov al,0x20
            out MASTER_PIC_DATA_PORT,al
            mov al,0x28
            out SLAVE_PIC_DATA_PORT,al

            mov al,00000100b
            out MASTER_PIC_DATA_PORT,al
            mov al,00000010b
            out SLAVE_PIC_DATA_PORT,al

            mov al,00000001b
            out MASTER_PIC_DATA_PORT,al
            out SLAVE_PIC_DATA_PORT,al
            mov al,0x0
            out MASTER_PIC_DATA_PORT,al
            out SLAVE_PIC_DATA_PORT,al

        popaq
        ret


    set_irq_mask:
        pushaq                              ;Save general purpose registers on the stack
        
        mov rdx,MASTER_PIC_DATA_PORT
        cmp rdi,15
        jg .out
        cmp rdi,8
        jl .master
        sub rdi,8
        mov rdx,SLAVE_PIC_DATA_PORT

        .master:
        in eax,dx
        mov rcx,rdi
        mov rdi,0x1
        shl rdi,cl
        or rax,rdi
        out dx,eax

        .out:    
        popaq
        ret


     clear_irq_mask:
        pushaq
        
        mov rdx,MASTER_PIC_DATA_PORT
        cmp rdi,15
        jg .out
        cmp rdi,8
        jl .master
        sub rdi,8
        mov rdx,SLAVE_PIC_DATA_PORT

        .master:
        in eax,dx
        mov rcx,rdi
        mov rdi,0x1
        shl rdi,cl
        not rdi         ;to unmask
        or rax,rdi
        out dx,eax

        .out:    
        popaq
        ret

