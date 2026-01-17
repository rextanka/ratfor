# copy -- copy input characters to output
     integer getc
     integer c

     while(getc(c) != EOF)
           call putc(c)
     stop
     end