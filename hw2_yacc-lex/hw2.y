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
        program statement_list '\n'
        | /* NULL */
        ;

statement_list  : statement_list statement
        | statement
        ;

statement:
        | IDENT EQL expression          { sym[$1] = $3; }
        expression                      { printf("%d\n", $1); }
        ;

expression:
        | expression '+' term           { $$ = $1 + $3; }
        | term
        ;

term:
        term '*' factor                 { $$ = $1 * $3; }
        | factor
        ;

factor:
        '(' expression ')'              { $$ = $2; }
        | IDENT                         { $$ = sym[$1]; }
        | NUMBER                        { $$ = $1; }
        ;

expression:
        | VARIABLE                      { $$ = sym[$1]; }
        | expression '+' expression     { $$ = $1 + $3; }
        | expression '-' expression     { $$ = $1 - $3; }
        | expression '*' expression     { $$ = $1 * $3; }
        | expression '/' expression     { $$ = $1 / $3; }
        | '(' expression ')'            { $$ = $2; }
        ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}
