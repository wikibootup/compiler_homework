%{
    #include <stdio.h>
    void yyerror(char *);
    int yylex(void);

    int sym[26];
%}

%token NUMBER LETTER NL EQL IDENT
%left '+' '-'
%left '*' '/'

%%

program:
        program statement '\n'
        | /* NULL */
        ;

statement:
        expression                      { printf("%d\n", $1); }
        | LETTER EQL expression         { sym[$1] = $3; }
        ;

expression:
        expression '+' term             { $$ = $1 + $3; }
        | term
        ;

term:
        term '*' factor                 { $$ = $1 * $3; }
        | factor
        ;

factor:
        '(' expression ')'              { $$ = $2; }
        | LETTER                        { $$ = sym[$1]; }
        | NUMBER                        { $$ = $1; }
        ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}
