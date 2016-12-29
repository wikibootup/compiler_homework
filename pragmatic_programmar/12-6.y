%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

    void yyerror(char *);
    int yylex(void);

%}

%token DIGIT TWO_DIGITS COLON

%%
program:
        program time '\n'
        |
        ;

time:
        hour
        ;

hour:
        DIGIT                         { $$ = $1; }
        | TWO_DIGITS                    { $$ = $1; }
        ;
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}
