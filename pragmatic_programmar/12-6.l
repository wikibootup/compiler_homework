digit [0-9]

%{
    #include "y.tab.h"

    extern int yylval;
%}

%%

{digit}    { 
    return DIGIT;
}

"\:"    {
    return COLON;
}

(am)|(pm)|(AM)|(PM) {
    return AMPM;
}

%%

yywrap()
{
    return(1); 
    // 1 means done, 0 means need more implementation
    // WARNING :: 0 causes infinite loop when token exausted.
}
