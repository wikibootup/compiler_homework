flex -l calc2.l
yacc -vd calc2.y
gcc lex.yy.c y.tab.c -lm -ll
