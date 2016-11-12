lex binToDec.l
yacc -d binToDec.y
cc lex.yy.c y.tab.c
