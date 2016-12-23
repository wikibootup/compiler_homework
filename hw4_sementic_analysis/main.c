#include <stdio.h>
#include <stdlib.h>
#include "type.h"
#include "sementic.h"

extern FILE *yyin;
extern int syntax_err;
extern A_NODE *root;
FILE *fout;
void initialize();
void print_ast();
extern FILE *yyin;

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("source file not given\n");
        exit(1);
    }
    
    if ((yyin = fopen(argv[argc-1],"r")) == NULL) {
        printf("can not open input file: %s\n",argv[argc-1]);
        exit(1);
    }
    
    printf("\nstart syntax analysis\n"); 
    initialize();
    
    yyparse();
    
    if (syntax_err)
        exit(1);
//    print_ast(root);// for syntax parse tree    

    printf("start semantic analysis\n"); 
    semantic_analysis(root);

    exit(0);

    return 0;
}
