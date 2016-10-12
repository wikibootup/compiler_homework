#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef struct id {
   char *name;
   int value;
   struct id *link;
} A_ID;
A_ID *searchIdent();
void insertIdent();
int getValue();
A_ID *head = NULL;

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
    }
    else
    {    
        id = malloc(sizeof(A_ID));

        id ->name = s;
        id ->value = val;
        id ->link = head;
        head = id;
    }
}

int getValue(char *s)
{
    A_ID *id = searchIdent(s);
    if(!id)
    {
        printf("Undefined value : %s\n", s);
        return 0;
    }

    return id ->value;
}

A_ID *searchIdent(char *s)
{
    A_ID *id;
    id = head;

    while(id && strcmp(id ->name, s) != 0)
    {
        id = id ->link;
    }

    return id;
}
