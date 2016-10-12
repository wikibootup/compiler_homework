yacc -d hw2-2.y
flex hw2-2.l
gcc lex.yy.c y.tab.c
