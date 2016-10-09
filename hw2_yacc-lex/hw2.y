%{
    #include <stdio.h>
    void yyerror(char *);
    int yylex(void);

    int sym[26];
%}

%token NUMBER LETTER EQL NL LPAREN RPAREN
%left PLUS MINUS
%left STAR DIVIDE

%%

program:
        program statement_list
        | /* NULL */
        ;

statement_list:
        statement_list statement
        | statement
        ;

statement:
        expression                          { printf("%d\n", $1); }
        | LETTER EQL expression             { sym[$1] = $3; }
        ;

expression:
        NUMBER
        | LETTER                      { $$ = sym[$1]; }
        | expression PLUS expression     { $$ = $1 + $3; }
        | expression MINUS expression     { $$ = $1 - $3; }
        | expression STAR expression     { $$ = $1 * $3; }
        | expression DIVIDE expression     { $$ = $1 / $3; }
        | LPAREN expression RPAREN            { $$ = $2; }
        ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}
