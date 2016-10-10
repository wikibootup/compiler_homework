flex -l hw2-2.l
yacc -vd hw2-2.y
gcc lex.yy.c y.tab.c -lm -ll
