#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define NUMBER          256
#define PLUS            257
#define STAR            258
#define LPAREN          259
#define RPAREN          260
#define END             261
#define EXPRESSION      0
#define TERM            1
#define FACTOR          2
#define ACC             999

/*
1 row : n th state number table
+[n]: S[n], that is "Shift n"
-[n]: R[n], that is "Reduce n"

action: each cases for each states, that is S, R, ERROR, ACC
go_to: state numbers when reduce.
*/

int action[12][6] = {
    {5, 0, 0, 4, 0, 0}, {0, 6, 0, 0, 0, ACC}, {0, -2, 7, 0, -2 -2},
    {0, -4, -4, 0, -4, -4}, {5, 0, 0, 4, 0, 0}, {0, -6, -6, 0, -6, -6},
    {5, 0, 0, 4, 0, 0}, {5, 0, 0, 4, 0, 0}, {0, 6, 0, 0, 11, 0},
    {0, -1, 7, 0, -1, -1}, {0, -3, -3, 0, -3, -3}, {0, -5, -5, 0, -5, -5}
};

int go_to[12][3] = {
    {1, 2, 3}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {8, 2, 3}, {0, 0, 0},
    {0, 9, 3}, {0, 0, 10}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}
};

int prod_left[7] = {0, EXPRESSION, EXPRESSION, TERM, TERM, FACTOR, FACTOR};
int prod_length[7] = {0, 3, 1, 3, 1, 3, 1};

int stack[1000];
int top = -1;
int sym;

void push(int);
void shift(int);
void reduce(int);
void yyerror();
void lex_error();
void yyparse();
int yylex();


int main() {
    while(1) {
        memset(stack, 0, sizeof(stack));
        top = -1;
        yyparse();
    }
    return 0;
}


void yyparse() {
    int i;
    stack[++top] = 0;                       // initial state
    sym = yylex();
    do {
        i = action[stack[top]][sym-256];     // get relation

        if (i == ACC)
            printf("success\n");
        else if (i > 0) {
            shift(i);
        }
        else if (i < 0) {
            reduce(-i);
        }
        else
            yyerror();
    }
    while (i != ACC);
}

void push(int i) {
    top++;
    stack[top] = i;
}

void shift(int i) {
    push(i);
    sym = yylex();
}

void reduce(int i) {
    int old_top;
    top -= prod_length[i];
    old_top = top;
    push(go_to[stack[old_top]][prod_left[i]]);
}

void yyerror() {
    printf("syntax error\n");
    exit(1);
}

int yylex() {
    static char ch = ' ';
    int i = 0;
    int symbol_value;

    while(ch == ' ' || ch == '\t')
        ch = getchar();

    printf("%c", ch);

    if (isdigit(ch)) {
        do
            ch = getchar();
        while (isdigit(ch));
        symbol_value = NUMBER;
    }
    else if (ch == '+') {
        ch = getchar();
        symbol_value = PLUS;
    }
    else if (ch == '*') {
        ch = getchar();
        symbol_value = STAR;
    }
    else if (ch == '(') {
        ch = getchar();
        symbol_value = LPAREN;
    }
    else if (ch == ')') {
        ch = getchar();
        symbol_value = RPAREN;
    }
    else if (ch == '\n') {
        ch = getchar();
        symbol_value = END;
    }
    else if (ch == EOF) {
        printf("END OF FILE.");
        exit(1);
    }   
    else {
        lex_error();
    }

    return symbol_value;
}

void lex_error() {
    printf("illegal token\n");
    exit(1);
}
