DIGIT                   [0-9]
LETTER                  [a-zA-Z_]
DELIM                   [ \t]
LINE                    [\n]
WS                      {DELIM}+

%{
    #include "y.tab.h"
    #include <stdlib.h>
    void    yyerror(char *);
    char    *makeString();
%}

%%

{DIGIT}+        {
                    yylval = atoi(yytext);
                    return NUMBER;
                }

{LETTER}({LETTER}|{DIGIT})* {
                                yylval = makeString(yytext);
                                return(IDENT);
                            }

[-+()/*\n]      { return *yytext; }
"\="            { return EQL; }

{WS}            { }     /* skip whitespace */
"//"[^\n]*      { }

.               yyerror("Unknown character");

%%

int yywrap(void) {
    return 1;
}

char *makeString(char *s)
{
    char *t;
    printf("PRINT MAKE STRING\n");
    t = malloc(strlen(s) + 1);
    strcpy(t, s);

    return t;
}
