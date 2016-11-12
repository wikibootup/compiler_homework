BIN_DIGIT                   [0-1]
NEW_LINE                    [\n]

%{
    #include "y.tab.h"
    #include <stdlib.h>
    void    yyerror(char *);
%}

%%

{BIN_DIGIT}                 { yylval = *yytext; return BIN; }
{NEW_LINE}                  { return NL; }

%%

int yywrap(void) {
    return 1;
}
