flex -l hw2.l
yacc -vd hw2.y
gcc lex.yy.c y.tab.c -lm -ll
