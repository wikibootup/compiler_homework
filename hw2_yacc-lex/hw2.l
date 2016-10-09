DIGIT                   [0-9]
LETTER                  [a-zA-Z_]
DELIM                   [ \t]
LINE                    [\n]
WS                      {DELIM}+

%{
    #include "y.tab.h"
    #include <stdlib.h>
    void yyerror(char *);
    char    *makeString();
    extern int yylval;
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

{LETTER}({LETTER}|{DIGIT})* { yylval = makeString(yytext); return(IDENT);}

[-+()/*\n]      { return *yytext; }
"\="            { return EQL; }

{WS}            { }     /* skip whitespace */
"//"[^\n]*      { }

.               yyerror("Unknown character");

%%

char *makeString(char *s)
{
   char *t;
   t = malloc(strlen(s) + 1);
   strcpy(t, s);
   return t;
}

int yywrap(void) {
    return 1;
}
