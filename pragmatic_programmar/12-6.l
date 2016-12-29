digit [0-9] 
letter [a-zA-Z_] 
ws {delim}+

%{
    #include "y.tab.h"
    extern int yylval;
%}

%%

"\:"		{ return(COLON); } 

{digit}    { 
    yylval = atoi(yytext); 
    return DIGIT;
}

{digit}{digit}    { 
    yylval = atoi(yytext); 
    return TWO_DIGITS;
}

%%


yywrap()
{
    return(1); 
    // 1 means done, 0 means need more implementation
    // WARNING :: 0 causes infinite loop when token exausted.
}
