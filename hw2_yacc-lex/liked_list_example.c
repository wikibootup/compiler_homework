#include <stdio.h>
#include <string.h>
#include <stdlib.h>
void yyerror(char *);
int yylex(void);

typedef struct id {
   char *name;
   int value;
   struct id *link;
} A_ID;
A_ID *searchIdent();
void insertIdent();
int getValue();
A_ID *head = NULL;

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    insertIdent("aa", 10);
    insertIdent("ab", 13);
    insertIdent("ac", 15);
    insertIdent("ad", 17);

    printf("aa= %d\n", getValue("aa"));
    printf("ab= %d\n", getValue("ab"));
    printf("aa= %d\n", getValue("aa"));
    printf("ac= %d\n", getValue("ac"));
    printf("ad= %d\n", getValue("ad"));

    insertIdent("ac", 3);
    
    printf("after: ac <- 3\n");
    printf("aa= %d\n", getValue("aa"));
    printf("ab= %d\n", getValue("ab"));
    printf("aa= %d\n", getValue("aa"));
    printf("ac= %d\n", getValue("ac"));
    printf("ad= %d\n", getValue("ad"));

    insertIdent("aa", 4);
    
    printf("after: aa <- 4\n");
    printf("aa= %d\n", getValue("aa"));
    printf("ab= %d\n", getValue("ab"));
    printf("aa= %d\n", getValue("aa"));
    printf("ac= %d\n", getValue("ac"));
    printf("ad= %d\n", getValue("ad"));

    return 0;
}

void insertIdent(char *s, int val)
{
    A_ID *id;
    id = searchIdent(s);

    if(id)
    {
        id ->value = val;
        return;
    }

    id = malloc(sizeof(A_ID));
    if (!id)
        return; //  Error handling needed

    id ->name = malloc(sizeof(s));
    id ->name = s;
    id ->value = val;
    id ->link = NULL;

    if(!head)
    {
        head = malloc(sizeof(A_ID));
        head = id;
        return;
    }

    id ->link = malloc(sizeof(A_ID));
    id ->link = head;
    head = id;
}

int getValue(char *s)
{
    A_ID *id = searchIdent(s);
    if(id == NULL)
    {
        return 2;
    }
    return id ->value;
}

A_ID *searchIdent(char *s)
{
    A_ID *id;
    id = malloc(sizeof(A_ID));
    id = head;

    while(id)
    {
        if(strcmp(id ->name, s) == 0)
            break;
        id = id ->link;
    }

    return id;
}
