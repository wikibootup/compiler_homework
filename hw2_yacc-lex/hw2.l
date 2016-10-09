DIGIT                   [0-9]
LETTER                  [a-zA-Z_]
DELIM                   [ \t]
LINE                    [\n]
WS                      {DELIM}+

%{
    #include "y.tab.h"
    #include <stdlib.h>
    void yyerror(char *);
%}

%%

{LETTER}+        {
                    yylval = *yytext - 'a';
                    return LETTER;
                }

{DIGIT}+        {
                    yylval = atoi(yytext);
                    return NUMBER;
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
