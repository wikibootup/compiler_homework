digit [0-9] letter [a-zA-Z_] delim [ \t]
line [\n]
ws {delim}+
%{
#include "y.tab.h" #include "type.h"
extern int yylval;
extern int line_no;
extern A_ID *current_id;
char *makeString();
int checkIdentifier(); %}
%%
{}
{ line_no++;}
{ return(AUTO_SYM); } { return(BREAK_SYM); } { return(CASE_SYM); }
{ws} {}
{line} { line_no++;}
auto { return(AUTO_SYM); } { return(BREAK_SYM); } { return(CASE_SYM); }
break { return(BREAK_SYM); }case { return(CASE_SYM); }
continue { return(CONTINUE_SYM); } default { return(DEFAULT_SYM); } do { return(DO_SYM); }
else { return(ELSE_SYM); } enum { return(ENUM_SYM); } for { return(FOR_SYM); }
if { return(IF_SYM); }
return { return(RETURN_SYM); } 
sizeof { return(SIZEOF_SYM); } 
static { return(STATIC_SYM); } 
struct { return(STRUCT_SYM); } switch { return(SWITCH_SYM); } typedef { return(TYPEDEF_SYM); } union { return(UNION_SYM); } while { return(WHILE_SYM); }
"\+\+" { return(PLUSPLUS); }
"\-\-" { return(MINUSMINUS); } "\->" { return(ARROW); }
"<" { return(LSS); }
">" { return(GTR); }
"<=" { return(LEQ); }
">=" { return(GEQ); }
"==" { return(EQL); }
"!=" { return(NEQ); } "&&" { return(AMPAMP); } "||" { return(BARBAR); } "\.\.\." { return(DOTDOTDOT); }
"\(" { return(LP); }
"\)" { return(RP); }
"\[" { return(LB); }
"\]" { return(RB); }
"\{" { return(LR); }
"\}" { return(RR); }
"\:" { return(COLON); } "\." { return(PERIOD); } "\," { return(COMMA); } "\!" { return(EXCL); } "\*" { return(STAR); } "\/" { return(SLASH); } "\%" { return(PERCENT); } "\&" { return(AMP); }
"\;" { return(SEMICOLON); } "\+" { return(PLUS); }
"\-" { return(MINUS); }
"\=" { return(ASSIGN); }
{digit}+
{digit}+\.{digit}+
{letter}({letter}|{digit})*
\"([^"\n]|\\["\n])*\"
return(STRING_LITERAL);}
\'([^'\n]|\'\')\' { yylval=*(yytext+1); return(CHARACTER_CONSTANT);}
"//"[^\n]* %%
char *makeString(char *s) {
{ }
{ yylval=atoi(yytext); return(INTEGER_CONSTANT);}
{ yylval=makeString(yytext); return(FLOAT_CONSTANT);} { return(checkIdentifier(yytext)); }
{ yylval=makeString(yytext);
}
}
yywrap() {
}
char *t; t=malloc(strlen(s)+1); strcpy(t,s);
return(t);
int checkIdentifier(char *s) {
A_ID *id; char *t; id=current_id; while (id) {
if (strcmp(id->name,s)==0) break;
id=id->prev; } if (id==0) {
yylval=makeString(s);
return(IDENTIFIER); } else if (id->kind==ID_TYPE) {
yylval=id->type;
return(TYPE_IDENTIFIER); } else {
yylval=id->name; return(IDENTIFIER);}
return(1);
