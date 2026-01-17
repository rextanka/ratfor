# detab -- convert tabs to and equivalent number of spaces
    character getc
    character c
    integer tabpos
    integer col, i, tabs(MAXLINE)

    call settab(tabs) # set initial tab stops
    col = 1
    while(getc(c)~=EOF)
        if(c==TAB)
            repeat {
                call putc(BLANK)
                col = col + 1
            } until(tabpos(col,tabs)==YES)
        else if(c == NEWLINE) {
            call putc(NEWLINE)
            col = 1
        }
        else {
            call putc(c)
            col=col+1
        }
    stop
    end

# tabpos -- return YES if col is a tab stop
    integer function tabpos(col, tabs)
    integer col, i, tabs(MAXLINE)

    if(col>MAXLINE)
        tabpos = YES
    else
        tabpos = tabs(col)
    return
    end

# settab -- set initial tab stops
    subroutine settab(tabs)
    integed mod
    integer i, tabs(MAXLINE)

    for(i=1;i<=MAXLINE;i=i+1)
        if(mod(i,8)==1)
            tabs(i)=YES
        else
            tabs(i)=NO
    return
    end
    
