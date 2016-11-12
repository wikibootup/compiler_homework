%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

    void yyerror(char *);
    void binToDec(char digit);
    void binInit();             // initialize dec to 0 when '\n' inserted 
    int yylex(void);
    int dec;                    // decimal value
    const int OFFSET = 48;      // for ascii 0
%}

%token BIN NL

%%

program:
        program converter
        | /* NULL */
        ;

converter:
    BIN                 { printf("%c", $1); binToDec($1); }
    | NL                { printf(" -> %d\n", dec); binInit(); }
    ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}

void binToDec(char digit)
{
    dec = dec << 1;         // already inserted value LS 1
    dec += (digit-OFFSET);  // input value is inserted
}

void binInit()
{
    dec = 0;
}
