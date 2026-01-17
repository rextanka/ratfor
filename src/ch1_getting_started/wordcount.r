# wordcount -- count the words in standard input
    character getc
    character c
    integer inword, wc

    wc = 0
    inword = NO
    while(getc(c)~=EOF)
        if(c == BLANK | c == NEWLINE | c == TAB)
            inword = NO
        else if(inword==NO)
        {
            inword = YES
            wc = wc + 1
        }
    call putdec(wc,1)
    call putc(NEWLINE)
    stop
    end