%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

    void yyerror(char *);
    int yylex(void);

%}

%token DIGIT COLON AMPM

%%
program:
        H '\n'
        |
        ;

H:
        DIGIT COLON M
        | DIGIT T
        ;

M:
        DIGIT T
        ;

T:
        AMPM
        |
        ;
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}
