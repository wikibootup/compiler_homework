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

{LETTER}        {
                    yylval = *yytext - 'a';
                    return LETTER;
                }

{DIGIT}+        {
                    yylval = atoi(yytext);
                    return NUMBER;
                }

{WS}            { }     /* skip whitespace */
"//"[^\n]*      { }

{LINE}          { return(NL);}
"\+"            { return(PLUS); }
"\-"            { return(MINUS); }
"\/"            { return(DIVIDE); }
"\*"            { return(STAR); }
"\("            { return(LPAREN); }
"\)"            { return(RPAREN); }
"\="            { return(EQL); }

.               yyerror("Unknown character");

%%

int yywrap(void) {
    return 1;
}
