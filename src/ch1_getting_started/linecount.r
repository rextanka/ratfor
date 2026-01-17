# linecount -- count lines in standard input
    character getc
    character c
    integer nl

    nl = 0
    while(getc(c) ~= EOF)
        if(c==NEWLINE)
            nl = nl + 1
    call putdec(nl,1)
    call putc(NEWLINE)
    stop
    end