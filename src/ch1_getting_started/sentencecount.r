# count - count sentences in standard input
driver
    integer nsent
    integer nset # function to perform counting

    nsent = nset(0)
    call putdec(nsent, 1)
    call putc(NEWLINE)
end

# nset - the actual sentence counting logic
integer function nset(dummy)
    character c, nextc
    integer n

    n = 0
    while (getc(c) != EOF) {
        if (c == PERIOD | c == QUEST | c == EXCLAM) {
            if (getc(nextc) == EOF) {
                n = n + 1
                break
            }
            if (nextc == BLANK | nextc == NEWLINE | nextc == TAB)
                n = n + 1
            # Put the lookahead character back if it wasn't the end
            # though Ratfor usually handled this with a peek/buffer
        }
    }
    return (n)
end