%{
    #include <stdio.h>
    #include <string.h>

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
        | LETTER EQL expression         { insertIdent($1, $3); }
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
        | LETTER                        { $$ = getValue($1); }
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
    A_ID *id;// = NULL;
    id = searchIdent(s);

    if (id)
    {
        id ->value = val;
        return;
    }
 
    id = malloc(sizeof(A_ID));

    id ->name = s;
    id ->value = val;
    id ->link = NULL;

    if (!head)
    {
        head = id;
        return;
    }

    id ->link = head;
    head = id;
}

int getValue(char *s)
{
    return searchIdent(s) ->value;
}

A_ID *searchIdent(char *s)
{
    A_ID *id = head;

    while(id)
    {
        if (id ->name == s)
            return id;
        id = id ->link;
    }

    return NULL;
}
