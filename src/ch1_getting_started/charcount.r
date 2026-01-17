# charcount -- count the number of characters in standard input
    character getc
    character c
    integer nc

    nc = 0
    while(getc(c) ~= EOF)
        nc=nc+1
    call putdec(nc,1)    
    call putc(NEWLINE)
    stop 
    end