#ifndef TOOLS_H
#define TOOLS_H

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

// 1. Type Mappings
// We use 'int' for character to safely handle EOF (-1)
typedef int character;
typedef int integer;
typedef int bool; // if needed

#define TRUE 1
#define FALSE 0
#define EOS '\0' 
#define NEWLINE '\n'
#define BLANK ' '
#define TAB '\t'
#define YES TRUE
#define NO FALSE
#define MAXLINE 1000


// 2. The "Software Tools" Primitives
// K&P primitives often don't match stdio 1:1.

// putc: K&P puts char to standard output
#define putc(c) putchar(c)

// Ensure this macro is present for the "mod" calls
#define mod(a,b) ((a)%(b))

// getc: K&P gets char from stdin.
// In K&P, getc(c) returns the character in c and returns EOF status as function result.
// BUT in some versions, it just returns the char. 
// We will assume the C standard: c = getc(stdin)
#define getc(c) ((c) = getchar())

// error: Print message and die
void error(char *s) {
    fprintf(stderr, "Error: %s\n", s);
    exit(1);
}

// putdec: print integer n in field width w
void putdec(int n, int w) {
    printf("%*d", w, n);
}

// max/min: K&P often assumes these exist
#define max(a,b) (((a)>(b))?(a):(b))
#define min(a,b) (((a)<(b))?(a):(b))

// 3. String handling helpers
// Ratfor strings are primitive. You might need a helper 
// to convert C strings "foo" to integer arrays if the code demands it.
// For now, standard C strings usually suffice.

#endif