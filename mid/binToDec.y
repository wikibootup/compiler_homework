%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

    void yyerror(char *);
    int binToDec(char digit);
    void binInit();
    int yylex(void);
    int decVal;
    int binUnit;
%}

%token BIN NL

%%

program:
        program converter
        | /* NULL */
        ;

converter:
    BIN                 { printf("wow\n"); }
    | NL              { printf("no\n"); }
    ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}

int binToDec(char digit)
{
//    printf("digit = %c", digit);
//    decVal += atoi(digit) << binUnit++;
    return 50;
}

void binInit()
{
    decVal = 0;
    binUnit = 0;
}
