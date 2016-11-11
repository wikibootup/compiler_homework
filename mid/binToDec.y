%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

    void yyerror(char *);
    int yylex(void);

    typedef struct id {
       char *name;
       int value;
       struct id *link;
    } A_ID;
    A_ID *searchIdent();
    void insertIdent();
    int getValue();
    A_ID *head = NULL;
%}

%token NUMBER EQL IDENT LETTER

%%

program:
        program statement '\n'
        | /* NULL */
        ;

statement:
        expression                      { printf("%d\n", $1); }
        | IDENT EQL expression          { insertIdent($1, $3); }
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
        | IDENT                         { $$ = getValue($1); }
        | NUMBER                        { $$ = $1; }
        ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}

void insertIdent(char *s, int val)
{
    A_ID *id;
    id = searchIdent(s);

    if(id)
    {
        id ->value = val;
    }
    else
    {
        id = malloc(sizeof(A_ID));

        id ->name = s;
        id ->value = val;
        id ->link = head;
        head = id;
    }
}

int getValue(char *s)
{
    A_ID *id = searchIdent(s);
    if(!id)
    {
        printf("Undefined value : %s\n", s);
        return 0;
    }

    return id ->value;
}

A_ID *searchIdent(char *s)
{
    A_ID *id;
    id = head;

    while(id && strcmp(id ->name, s) != 0)
    {
        id = id ->link;
    }

    return id;
}
