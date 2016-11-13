* 본 소스코드 중 제공된 소스코드는 저작권법에 따라 보호된 저작물이므로 무단전제와 무단복제를 금지합니다.  "C & Compiler C 언어와 컴파일러", SSU Press, 2015.02

1. 개요
===

이번 과제는 의미 검사(sementics)를 제외한 문법 검사(syntax tree)를 수행하여 파싱트리를 생성하는 코드로부터 원시코드를 생성하는 것을 목적으로 한다. 프로그램의 사용자는 그림에서 lex의 규칙과 yacc의 문법 규칙을 만드는 작업을 해야 한다. 이전 과제에서는 바로 위의 lex, yacc 파일과 그것으로부터 파생되는 lex.yy.c, yy.tab.c 만을 이용했다면, 이번 과제에서는 문법 검사를 위한 syntax.c가 추가된 점이 가장 다른 점이라 할 수 있다.

2. 상세설계
===

2-1. 파서 처리 과정
---

LR 파서를 기본으로 하기 때문에 문법 검사 시에 최하위 요소로부터 상위 요소로 합쳐진다. 이것을 만드는 문법을 거꾸로 적어보면 아래와 같다.

예)

- 요소(변수=IDENTIFIER, 인자=ARG) -> 요소들
- 요소들 -> 식
- 식 -> 문장(STATEMENT)
- 문장 -> 문장들(STATEMENT LIST)
- 문장들 -> 몸체(BODY)
- 몸체 -> 프로그램(N_PROGRAM)

이것을 거꾸로 수행하면 그것이 원래의 문법이고, 현재 `print.c`가 파싱트리를 생성하는 방법이다.

2-2. 오류 잡기
---

주어진 코드를 타이핑하는 과정에서 발생한 오류는 다음과 같다.

1. 문법 오류 : yywrap의 리턴 인자 1 대신 0
2. 출력 오류 : 존재하지 않는 하위 노드 출력

1. yywrap은 토큰을 다 읽었을 때(프로세스 종료시), 0을 반환하면 추가적인 동작을 요구하기 때문에 이 부분이 구현되어 있지 않으면 무한 루프에 빠진다. 반면, 1은 수행을 마쳤음을 의미한다. (http://epaperpress.com/lexandyacc/prl.html 참조)
2. `print.c`에서 `void prt_initializer(A_NODE *node, int s)` 함수는 하위 노드를 위한 함수를 재귀적으로 호출하기 때문에 더이상 존재하지 않는 노드에 대한 예외처리가 필요하다. 본 코드에서는 이것을 명시하기 위하여 트리 중간에 해당 정보를 트리 레벨과 함께 출력해주었다.

```c
void prt_initializer(A_NODE *node, int s) {
    if(!node)
        printf("No more node at s==%d\n", s);
        return;
    ...
```

2-3. 파싱 트리 사례 분석
---

**1) 메인 함수만 존재**

```c
$ cat test5.c
main()
{}
```

```sh
$ ./a.out test5.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:8b27988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST_NIL
No more node at s==3
```
- N_PROGRAM으로부터 시작된 노드는 메인 함수를 ID로 확인하여 타입 노드로 접근
- 타입 노드로부터 타입은 함수, 리턴 타입은 정수형, 몸체로는 STATEMENT COMPOUND를 가짐을 확인
- 리스트의 각 원소들을 확인하다가(여기서는 한개도 없다) 종료.


**2) 메인함수 + 변수 선언 및 초기화**

```c
$ cat test4.c
main()
{
    int a, b = 10;
}
```


```sh
$ ./a.out test4.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:89f7988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:89f25a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | (ID="b") TYPE:89f25a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | | INIT
| | | | | | N_STMT_LIST_NIL
No more node at s==3
```

- `N_STMT_COMPOUND` 아래로 정수형 변수 a와 b가 같은 레벨에서 선언
- b는 init declarator 형태로 변수값이 함께 할당

**3) 메인함수 + 변수 대입**

```c
$ cat test4.c
$ cat test3.c
main()
{
    int a, b = 10;
	int c, d;

    a = b;
    b = a+b;
    }
```


```sh
$ ./a.out test3.c

start syntax analysis
======= syntax tree ==========
1),2) 중복 생략
...
N_PROGRAM
| (ID="main") TYPE:95df988 KIND:FUNC SPEC=NULL LEV=0
...
| | | | | | (ID="c") TYPE:95da5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | (ID="d") TYPE:95da5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_EXPRESSION
| | | | | | | | N_EXP_ASSIGN
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="a") TYPE:95da5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="b") TYPE:95da5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | N_STMT_LIST
| | | | | | | | N_STMT_EXPRESSION
| | | | | | | | | N_EXP_ASSIGN
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="b") TYPE:95da5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | | | N_EXP_ADD
| | | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | | (ID="a") TYPE:95da5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | | (ID="b") TYPE:95da5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | N_STMT_LIST_NIL
No more node at s==3
```

- `N_EXP_ASSIGN` `N_EXP_ADD` 등 식과 할당 연산 노드가 추가


**4) 메인함수 + 변수 초기화, 대수비교 함수 정의, 호출**

```c
$ cat test2.c
int bigger(int p1, int p2)
{
    if(p1 > p2)
        return p1;
    else
        return p2;
}

func()
{

}

main()
{
    int a = 5, b = 10;
    func();
	bigger(a, b);
}
```

```sh
$ ./a.out test2.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="bigger") TYPE:93afa38 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | | (ID="p1") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | TYPE
| | | | | | | (int)
No more node at s==7
| | | | | (ID="p2") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | TYPE
| | | | | | | (int)
No more node at s==7
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_IF_ELSE
| | | | | | | | N_EXP_GTR
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="p1") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="p2") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | | | N_STMT_RETURN
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="p1") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | | | N_STMT_RETURN
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="p2") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | | N_STMT_LIST_NIL
No more node at s==3
| (ID="func") TYPE:93afc00 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST_NIL
No more node at s==3
| (ID="main") TYPE:93afcb8 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:93aa5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | | INIT
| | | | | | (ID="b") TYPE:93aa5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | | INIT
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_EXPRESSION
| | | | | | | | N_EXP_FUNCTION_CALL
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="func") TYPE:93afc00 KIND:FUNC SPEC=NULL LEV=0
| | | | | | | | | N_ARG_LIST_NIL
| | | | | | | N_STMT_LIST
| | | | | | | | N_STMT_EXPRESSION
| | | | | | | | | N_EXP_FUNCTION_CALL
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="bigger") TYPE:93afa38 KIND:FUNC SPEC=NULL LEV=0
| | | | | | | | | | N_ARG_LIST
| | | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | | (ID="a") TYPE:93aa5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | | | | N_ARG_LIST
| | | | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | | | (ID="b") TYPE:93aa5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | | | | | N_ARG_LIST_NIL
| | | | | | | | N_STMT_LIST_NIL
No more node at s==3
```

- 추가된 함수 역시 메인 함수와 동일한 문법규칙으로 같은 노드 명칭을 가지지만, 대소 비교 함수에서는 조건문과 리턴(STMT_RETURN) 등의 노드가 추가(아래 참조)

```sh
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_IF_ELSE
| | | | | | | | N_EXP_GTR
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="p1") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="p2") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | | | N_STMT_RETURN
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="p1") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | | | N_STMT_RETURN
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="p2") TYPE:93aa5a0 KIND:PARM SPEC=NULL LEV=1
| | | | | | | N_STMT_LIST_NIL

```

2-4. 원시 코드 변경 아이디어

기존에 파싱트리의 구조를 유지하되, 노드명을 출력하는 대신 명칭과 값을 출력하는 방식을 택하기로 하였다. 즉, 넌터미널 기호 대신 터미널 기호로 대체하기로 하였다.다르게 말해서 메타 정보 대신 정보 그 자체를 출력해주기로 하였다. 예를 들면, 타입 노드로부터 그 타입의 명칭 등 메타 정보를 출력하는 대신 타입 이름과 그 사이에 필요한 정보, 예를 들면 괄호 등을 넣어주었다. 그 실제 구현의 예는 아래와 같다.

```c
case T_FUNC: t->prt=TRUE;
    printf("(");
    //printf("FUNCTION\n");
    //print_space(s);
    //printf("| PARAMETER\n");
    prt_A_ID_LIST(t->field,s+2);
    printf(")");
```

4. 결과
===

* 테스트 파일은 위의 파싱트리 테스트의 경우와 동일하다.

```sh
$ ./a.out test5.c

start syntax analysis
======= syntax tree ==========
main ()<RETURN TYPE: int>
{
}
```

- 메인 함수의 이름, 
- 인자를 위한 괄호, 
- 리턴 타입 정수형의 명시
- compound statement의 중괄호 및 개행

```sh
$ ./a.out test4.c

start syntax analysis
======= syntax tree ==========
main ()<RETURN TYPE: int>
{
a      int, b      int}
```

- 정수형 변수 a, b의 선언

```sh
$ ./a.out test3.c

start syntax analysis
======= syntax tree ==========
main ()<RETURN TYPE: int>
{
a      int, b      int, c      int, d      int}
```

- 초기화 연산 및 대입 연산이 아직 구현되지 않았다.
- 생각보다도 어려웠다.

```sh
$ ./a.out test2.c

start syntax analysis
======= syntax tree ==========
bigger (p1     int, p2     int)<RETURN TYPE: int>
{
}
, func ()<RETURN TYPE: int>
{
}
, main ()<RETURN TYPE: int>
{
a      int, b      int}
```

- 함수 호출과 파라미터 괄호에 담긴 변수 리스트(ID_LIST)에 대한 명칭 및 타입
- 각 함수는 분리되어있으며 독립된 compound statement을 가짐

---

하지만 이전 형태의 구현에서는 대입 연산을 수행할 수 가 없었다. 따라서 해당 부분
에 대한 코드를 추가하여 다시 테스트를 해보았다.

in test2.c
```c
int bigger(int p1, int p2)
{
    if(p1 > p2)
        return p1;
    else
        return p2;
}

func()
{

}

main()
{
    int a = 5, b = 10;
    func();
	bigger(a, b);
}
```
$ ./a.out test2.c
```sh

start syntax analysis
======= syntax tree ==========
bigger (p1 int, p2 int)<RETURN TYPE: int>
{
}
func ()<RETURN TYPE: int>
{
}
main ()<RETURN TYPE: int>
{
a int <set as 5>;
b int <set as 10>;
}
```
in test3.c
```c
main()
{
    int a, b = 10;
	int c, d;

    a = b;
    b = a+b;
}
```
$ ./a.out test3.c
```sh

start syntax analysis
======= syntax tree ==========
main ()<RETURN TYPE: int>
{
a int;
b int <set as 10>;
c int;
d int;
}
```
in test4.c
```c
main()
{
    int a, b = 10;
}
```
$ ./a.out test4.c
```sh

start syntax analysis
======= syntax tree ==========
main ()<RETURN TYPE: int>
{
a int;
b int <set as 10>;
}
```
in test5.c
```c
main()
{}
```
$ ./a.out test5.c
```sh

start syntax analysis
======= syntax tree ==========
main ()<RETURN TYPE: int>
{
}
```
```
in test7.c
```c
main(int argc, char *argv[])
{
    int a, b = 10;
    return 0;
}
```
$ ./a.out test7.c
```sh

start syntax analysis
======= syntax tree ==========
main (argc int, argv  char 1)<RETURN TYPE: int>
{
a int;
b int <set as 10>;
}
```
in test8.c
```c
main()
{
    char *a = "THIS IS STRING\n";
}
```
$ ./a.out test8.c
```sh

start syntax analysis
======= syntax tree ==========
main ()<RETURN TYPE: int>
{
a char 1 <set as "THIS IS STRING\n">;
}
```
in test9.c
```c
switch (kim) {
    case 10+1: kim=kim*2+1;
    default: for (i=0;i<5;i++);
}
```
$ ./a.out test9.c
```sh

start syntax analysis
line 1: syntax error near switch
```
in test10.c
```c
int i = 0;
switch(i)
{
    case 0: break;
    default: break;
}
```
$ ./a.out test10.c
```sh

start syntax analysis
line 2: syntax error near switch
```
in test11.c
```c
main()
{
    int a = 10;
    float pi = 3.14;
    char* hello = "hello";
    int* ip = &a;
    char symbol = 's';
}
```
$ ./a.out test11.c
```sh

start syntax analysis
======= syntax tree ==========
main ()<RETURN TYPE: int>
{
a int <set as 10>;
pi float <float set as 0.000000>;
hello char 1 <set as "hello">;
ip int <set as 136853472>;
symbol char 1 <set as s>;
}
```

그 결과 정수형과 문자를 저장하는 데에는 문제가 없었으나, 같은 방법으로 실수형을 저장할 때에는 값이 나오지 않았다. 또한 포인터 형을 파악하기 위해 ID의 타입이 T_POINTER일 것이라 생각하였는데 존재하지 않았다. 스위치 문, 구조체 정의, 함수 프로토타입 지정 시에 오류가 발생한 부분은 제공된 기존 로직을 수정하지 않는 하에 아직 해결하지 못하였다.

5. 소스코드

5-1. 이전 버전 ( 초기화 연산 대입 이전 )
```c
#include <stdio.h>

#include "type.h"
char * node_name[] = {
"N_NULL",
"N_PROGRAM", "N_EXP_IDENT", "N_EXP_INT_CONST", "N_EXP_FLOAT_CONST", "N_EXP_CHAR_CONST", 
"N_EXP_STRING_LITERAL", "N_EXP_ARRAY", "N_EXP_FUNCTION_CALL", "N_EXP_STRUCT", "N_EXP_ARROW", 
"N_EXP_POST_INC", "N_EXP_POST_DEC", "N_EXP_PRE_INC", "N_EXP_PRE_DEC", "N_EXP_AMP", "N_EXP_STAR", 
"N_EXP_NOT", "N_EXP_PLUS", "N_EXP_MINUS", "N_EXP_SIZE_EXP", "N_EXP_SIZE_TYPE", "N_EXP_CAST", 
"N_EXP_MUL", "N_EXP_DIV", "N_EXP_MOD", "N_EXP_ADD", "N_EXP_SUB", "N_EXP_LSS", "N_EXP_GTR", 
"N_EXP_LEQ", "N_EXP_GEQ", "N_EXP_NEQ", "N_EXP_EQL", "N_EXP_AND", "N_EXP_OR", "N_EXP_ASSIGN",
"N_ARG_LIST",
"N_ARG_LIST_NIL",
"N_STMT_LABEL_CASE", "N_STMT_LABEL_DEFAULT", "N_STMT_COMPOUND", "N_STMT_EMPTY", 
"N_STMT_EXPRESSION", "N_STMT_IF", "N_STMT_IF_ELSE", "N_STMT_SWITCH", "N_STMT_WHILE", 
"N_STMT_DO", "N_STMT_FOR", "N_STMT_RETURN", "N_STMT_CONTINUE", "N_STMT_BREAK",
"N_FOR_EXP", "N_STMT_LIST", "N_STMT_LIST_NIL",
"N_INIT_LIST", "N_INIT_LIST_ONE", "N_INIT_LIST_NIL"
};

void print_ast(A_NODE *);
void prt_program(A_NODE *, int);
void prt_initializer(A_NODE *, int);
void prt_arg_expr_list(A_NODE *, int);
void prt_statement(A_NODE *, int);
void prt_statement_list(A_NODE *, int);
void prt_for_expression(A_NODE *, int);
void prt_expression(A_NODE *, int);
void prt_A_TYPE(A_TYPE *, int);
void prt_A_ID_LIST(A_ID *, int);
void prt_A_ID(A_ID *, int);
void prt_A_ID_NAME(A_ID *, int);
void prt_STRING(char *, int);
void prt_integer(int, int);
void print_node(A_NODE *,int);
void print_space(int);
extern A_TYPE *int_type, *float_type, *char_type, *void_type, *string_type;
void print_node(A_NODE *node, int s) {
    //print_space(s);
    //printf("%s\n", node_name[node->name]);
}
void print_space(int s) {
    int i;
    for(i=1; i<=s; i++) printf(" ");
}
void print_ast(A_NODE *node) {
    printf("======= syntax tree ==========\n"); 
    prt_program(node,0);
}
void prt_program(A_NODE *node, int s) {
    print_node(node,s); 
    switch(node->name) { 
        case N_PROGRAM:
            prt_A_ID_LIST(node->clink, s+1);
            break; 
        default :
            printf("****syntax tree error******");
    } 
}

void prt_initializer(A_NODE *node, int s) {
    if(!node)
        return;

    print_node(node,s);
    switch(node->name) {
    case N_INIT_LIST: 
        prt_initializer(node->llink, s+1); 
        prt_initializer(node->rlink, s+1); 
        break;
    case N_INIT_LIST_ONE: 
        prt_expression(node->clink, s+1);
        break;
    case N_INIT_LIST_NIL: 
        break;
    default :
        printf("****syntax tree error******");
    } 
}
void prt_expression(A_NODE *node, int s) {
    print_node(node,s);
    switch(node->name) 
    {
        case N_EXP_IDENT : prt_A_ID_NAME(node->clink, s+1); break;
        case N_EXP_INT_CONST : prt_integer(node->clink, s+1); break;
        case N_EXP_FLOAT_CONST : prt_STRING(node->clink, s+1); break;
        case N_EXP_CHAR_CONST : prt_integer(node->clink, s+1); break;
        case N_EXP_STRING_LITERAL : prt_STRING(node->clink, s+1); break;
        case N_EXP_ARRAY : prt_expression(node->llink, s+1); prt_expression(node->rlink, s+1); break;
        case N_EXP_FUNCTION_CALL : prt_expression(node->llink, s+1); prt_arg_expr_list(node->rlink, s+1); break;
        case N_EXP_STRUCT :
        case N_EXP_ARROW : prt_expression(node->llink, s+1); prt_STRING(node->rlink, s+1); break;
        case N_EXP_POST_INC :
        case N_EXP_POST_DEC :
        case N_EXP_PRE_INC :
        case N_EXP_PRE_DEC :
        case N_EXP_AMP :
        case N_EXP_STAR :
        case N_EXP_NOT :
        case N_EXP_PLUS :
        case N_EXP_MINUS :
        case N_EXP_SIZE_EXP : prt_expression(node->clink, s+1); break;
        case N_EXP_SIZE_TYPE : prt_A_TYPE(node->clink, s+1); break;
        case N_EXP_CAST : prt_A_TYPE(node->llink, s+1); prt_expression(node->rlink, s+1); break;
        case N_EXP_MUL :
        case N_EXP_DIV :
        case N_EXP_MOD :
        case N_EXP_ADD :
        case N_EXP_SUB :
        case N_EXP_LSS :
        case N_EXP_GTR :
        case N_EXP_LEQ :
        case N_EXP_GEQ :
        case N_EXP_NEQ :
        case N_EXP_EQL :
        case N_EXP_AND :
        case N_EXP_OR :
        case N_EXP_ASSIGN : prt_expression(node->llink, s+1); prt_expression(node->rlink, s+1); break;
        default :
            printf("****syntax tree error******");
    }
}
void prt_arg_expr_list(A_NODE *node, int s) {
    print_node(node,s); 
    switch(node->name) {
        case N_ARG_LIST : prt_expression(node->llink, s+1); prt_arg_expr_list(node->rlink, s+1); break;
        case N_ARG_LIST_NIL : break;
        default :
            printf("****syntax tree error******");
    }
}
void prt_statement(A_NODE *node, int s) {
print_node(node,s); 
switch(node->name) {
    case N_STMT_LABEL_CASE : prt_expression(node->llink, s+1); prt_statement(node->rlink, s+1); break;
    case N_STMT_LABEL_DEFAULT : prt_statement(node->clink, s+1); break;
    case N_STMT_COMPOUND: printf("{\n"); if(node->llink) prt_A_ID_LIST(node->llink, s+1); prt_statement_list(node->rlink, s+1); printf("}\n");break;
    case N_STMT_EMPTY: break;
    case N_STMT_EXPRESSION: prt_expression(node->clink, s+1); break;
    case N_STMT_IF_ELSE: prt_expression(node->llink, s+1); prt_statement(node->clink, s+1); prt_statement(node->rlink, s+1); break;
    case N_STMT_IF: 
    case N_STMT_SWITCH: prt_expression(node->llink, s+1); prt_statement(node->rlink, s+1); break;
    case N_STMT_WHILE: prt_expression(node->llink, s+1); prt_statement(node->rlink, s+1); break; 
    case N_STMT_DO: prt_statement(node->llink, s+1); prt_expression(node->rlink, s+1); break;
    case N_STMT_FOR: prt_for_expression(node->llink, s+1); prt_statement(node->rlink, s+1); break;
    case N_STMT_CONTINUE: break;
    case N_STMT_BREAK: break;
    case N_STMT_RETURN: if(node->clink) prt_expression(node->clink, s+1); break;
    default : printf("****syntax tree error******");
    }
}
void prt_statement_list(A_NODE *node, int s) {
print_node(node,s); 
switch(node->name) { 
    case N_STMT_LIST: prt_statement(node->llink, s+1); prt_statement_list(node->rlink, s+1); break;
    case N_STMT_LIST_NIL: break;
    default :
    printf("****syntax tree error******");
    } 
}
void prt_for_expression(A_NODE *node, int s) {
    print_node(node,s); 
    switch(node->name) {
    case N_FOR_EXP : 
        if(node->llink) prt_expression(node->llink, s+1); 
        if(node->clink) prt_expression(node->clink, s+1); 
        if(node->rlink) prt_expression(node->rlink, s+1); 
        break;
    default :
        printf("****syntax tree error******");
    }
}
void prt_integer(int a, int s) {
    //print_space(s); 
    //printf("%d", a);
}
void prt_STRING(char *str, int s) {
    //print_space(s); 
    //printf("%s", str);
} 

char *type_kind_name[]={"NULL","ENUM","ARRAY","STRUCT","UNION","FUNC","POINTER","VOI D"};

void prt_A_TYPE(A_TYPE *t, int s) {
//    print_space(s); 
    if (t==int_type)
        printf("int"); 
    else if (t==float_type)
        printf("float"); 
    else if (t==char_type)
        printf("char %d",t->size); 
    else if (t==void_type)
        printf("void"); 
    else if (t->kind==T_NULL)
        printf("null"); 
    else if (t->prt)
        printf("DONE:%x",t);
    else
        switch (t->kind) {
            case T_ENUM: t->prt=TRUE;
                //printf("ENUM\n");
                //print_space(s); 
                //printf("| ENUMERATORS\n"); 
                prt_A_ID_LIST(t->field,s+2);
                break;
            case T_POINTER: t->prt=TRUE;
                printf("*");
                //printf("POINTER\n");
                //print_space(s); printf("| ELEMENT_TYPE\n"); 
                prt_A_TYPE(t->element_type,s+2);
                break;
            case T_ARRAY: t->prt=TRUE;
                //printf("ARRAY\n");
                print_space(s); 
                //printf("| INDEX\n"); 
                if (t->expr)
                    prt_expression(t->expr,s+2); 
                else {
                //print_space(s+2); 
                //printf("(none)\n");} print_space(s); printf("| ELEMENT_TYPE\n"); 
                prt_A_TYPE(t->element_type,s+2);
                break;
            case T_STRUCT: t->prt=TRUE;
                //printf("STRUCT\n");
                //print_space(s); printf("| FIELD\n"); 
                prt_A_ID_LIST(t->field,s+2);
                break;
            case T_UNION: t->prt=TRUE;
                //printf("UNION\n");
                //print_space(s); printf("| FIELD\n"); 
                prt_A_ID_LIST(t->field,s+2);
                break;
            case T_FUNC: t->prt=TRUE;
                printf("(");
                //printf("FUNCTION\n");
                //print_space(s); 
                //printf("| PARAMETER\n");
                prt_A_ID_LIST(t->field,s+2); 
                printf(")");
                //print_space(s); 
                //printf("| TYPE\n"); 
                printf("<RETURN TYPE: ");
                prt_A_TYPE(t->element_type,s+2); 
                printf(">");
                printf("\n");
                if (t->expr) {
                    //print_space(s); 
                    //printf("| BODY\n"); 
                    prt_statement(t->expr,s+2);
                }
            }
        }
}

void prt_A_ID_LIST(A_ID *id, int s) {
    while (id) {
        prt_A_ID(id,s);
        id=id->link;
        if(id)
            printf(", ");
    } 
}

char *id_kind_name[]={"NULL","VAR","FUNC","PARM","FIELD","TYPE","ENUM","STRUCT","ENUM _LITERAL"};

char *spec_name[]={"NULL","AUTO","TYPEDEF","STATIC"};

void prt_A_ID_NAME(A_ID *id, int s) {
    //print_space(s);
    //printf("(ID=\"%s\") TYPE:%x KIND:%s SPEC=%s LEV=%d \n", id->name, id->type,
    //id_kind_name[id->kind], spec_name[id->specifier],id->level);
}

void prt_A_ID(A_ID *id, int s) {
//    print_space(s);
    printf("%s", id->name);
    print_space(s);
   
    if (id->type) {
        //print_space(s);
        //printf("| TYPE\n"); 
        prt_A_TYPE(id->type,s+2);
    }
    if (id->init) 
    { 
        //print_space(s);
        //printf("| INIT\n");
        if (id->kind==ID_ENUM_LITERAL)
           prt_expression(id->init,s+2);
    }
    else

    
    prt_initializer(id->init,s+2);
    //printf("\n");

    
    }
```

5-2. 초기화 연산 수정 버전

```c
#include <stdio.h>

#include "type.h"
char * node_name[] = {
"N_NULL",
"N_PROGRAM", "N_EXP_IDENT", "N_EXP_INT_CONST", "N_EXP_FLOAT_CONST", "N_EXP_CHAR_CONST", 
"N_EXP_STRING_LITERAL", "N_EXP_ARRAY", "N_EXP_FUNCTION_CALL", "N_EXP_STRUCT", "N_EXP_ARROW", 
"N_EXP_POST_INC", "N_EXP_POST_DEC", "N_EXP_PRE_INC", "N_EXP_PRE_DEC", "N_EXP_AMP", "N_EXP_STAR", 
"N_EXP_NOT", "N_EXP_PLUS", "N_EXP_MINUS", "N_EXP_SIZE_EXP", "N_EXP_SIZE_TYPE", "N_EXP_CAST", 
"N_EXP_MUL", "N_EXP_DIV", "N_EXP_MOD", "N_EXP_ADD", "N_EXP_SUB", "N_EXP_LSS", "N_EXP_GTR", 
"N_EXP_LEQ", "N_EXP_GEQ", "N_EXP_NEQ", "N_EXP_EQL", "N_EXP_AND", "N_EXP_OR", "N_EXP_ASSIGN",
"N_ARG_LIST",
"N_ARG_LIST_NIL",
"N_STMT_LABEL_CASE", "N_STMT_LABEL_DEFAULT", "N_STMT_COMPOUND", "N_STMT_EMPTY", 
"N_STMT_EXPRESSION", "N_STMT_IF", "N_STMT_IF_ELSE", "N_STMT_SWITCH", "N_STMT_WHILE", 
"N_STMT_DO", "N_STMT_FOR", "N_STMT_RETURN", "N_STMT_CONTINUE", "N_STMT_BREAK",
"N_FOR_EXP", "N_STMT_LIST", "N_STMT_LIST_NIL",
"N_INIT_LIST", "N_INIT_LIST_ONE", "N_INIT_LIST_NIL"
};

void print_ast(A_NODE *);
void prt_program(A_NODE *, int);
void prt_initializer(A_NODE *, int);
void prt_arg_expr_list(A_NODE *, int);
void prt_statement(A_NODE *, int);
void prt_statement_list(A_NODE *, int);
void prt_for_expression(A_NODE *, int);
void prt_expression(A_NODE *, int);
void prt_A_TYPE(A_TYPE *, int);
void prt_A_ID_LIST(A_ID *, int);
void prt_A_ID(A_ID *, int);
void prt_A_ID_NAME(A_ID *, int);
void prt_STRING(char *, int);
void prt_integer(int, int);
void print_node(A_NODE *,int);
void print_space(int);
extern A_TYPE *int_type, *float_type, *char_type, *void_type, *string_type;
void print_node(A_NODE *node, int s) {
    //print_space(s);
    //printf("%s\n", node_name[node->name]);
}
void print_space(int s) {
    int i;
//    for(i=1; i<=s; i++) printf(" ");
printf(" ");
}
void print_ast(A_NODE *node) {
    printf("======= syntax tree ==========\n"); 
    prt_program(node,0);
}
void prt_program(A_NODE *node, int s) {
    print_node(node,s); 
    switch(node->name) { 
        case N_PROGRAM:
            prt_A_ID_LIST(node->clink, s+1);
            break; 
        default :
            printf("****syntax tree error******");
    } 
}

void prt_initializer(A_NODE *node, int s) {
    if(!node)
        return;

    print_node(node,s);
    switch(node->name) {
    case N_INIT_LIST: 
        prt_initializer(node->llink, s+1); 
        prt_initializer(node->rlink, s+1); 
        break;
    case N_INIT_LIST_ONE: 
        prt_expression(node->clink, s+1);
        break;
    case N_INIT_LIST_NIL: 
        break;
    default :
        printf("****syntax tree error******");
    } 
}
void prt_expression(A_NODE *node, int s) {
    print_node(node,s);
    switch(node->name) 
    {
        case N_EXP_IDENT : prt_A_ID_NAME(node->clink, s+1); break;
        case N_EXP_INT_CONST : prt_integer(node->clink, s+1); break;
        case N_EXP_FLOAT_CONST : prt_STRING(node->clink, s+1); break;
        case N_EXP_CHAR_CONST : prt_integer(node->clink, s+1); break;
        case N_EXP_STRING_LITERAL : prt_STRING(node->clink, s+1); break;
        case N_EXP_ARRAY : prt_expression(node->llink, s+1); prt_expression(node->rlink, s+1); break;
        case N_EXP_FUNCTION_CALL : prt_expression(node->llink, s+1); prt_arg_expr_list(node->rlink, s+1); break;
        case N_EXP_STRUCT :
        case N_EXP_ARROW : prt_expression(node->llink, s+1); prt_STRING(node->rlink, s+1); break;
        case N_EXP_POST_INC :
        case N_EXP_POST_DEC :
        case N_EXP_PRE_INC :
        case N_EXP_PRE_DEC :
        case N_EXP_AMP :
        case N_EXP_STAR :
        case N_EXP_NOT :
        case N_EXP_PLUS :
        case N_EXP_MINUS :
        case N_EXP_SIZE_EXP : prt_expression(node->clink, s+1); break;
        case N_EXP_SIZE_TYPE : prt_A_TYPE(node->clink, s+1); break;
        case N_EXP_CAST : prt_A_TYPE(node->llink, s+1); prt_expression(node->rlink, s+1); break;
        case N_EXP_MUL :
        case N_EXP_DIV :
        case N_EXP_MOD :
        case N_EXP_ADD :
        case N_EXP_SUB :
        case N_EXP_LSS :
        case N_EXP_GTR :
        case N_EXP_LEQ :
        case N_EXP_GEQ :
        case N_EXP_NEQ :
        case N_EXP_EQL :
        case N_EXP_AND :
        case N_EXP_OR :
        case N_EXP_ASSIGN : prt_expression(node->llink, s+1); prt_expression(node->rlink, s+1); break;
        default :
            printf("****syntax tree error******");
    }
}
void prt_arg_expr_list(A_NODE *node, int s) {
    print_node(node,s); 
    switch(node->name) {
        case N_ARG_LIST : prt_expression(node->llink, s+1); prt_arg_expr_list(node->rlink, s+1); break;
        case N_ARG_LIST_NIL : break;
        default :
            printf("****syntax tree error******");
    }
}
void prt_statement(A_NODE *node, int s) {
print_node(node,s); 
switch(node->name) {
    case N_STMT_LABEL_CASE : prt_expression(node->llink, s+1); prt_statement(node->rlink, s+1); break;
    case N_STMT_LABEL_DEFAULT : prt_statement(node->clink, s+1); break;
    case N_STMT_COMPOUND: printf("{\n"); if(node->llink) prt_A_ID_LIST(node->llink, s+1); prt_statement_list(node->rlink, s+1); printf("}\n");break;
    case N_STMT_EMPTY: break;
    case N_STMT_EXPRESSION: prt_expression(node->clink, s+1); break;
    case N_STMT_IF_ELSE: prt_expression(node->llink, s+1); prt_statement(node->clink, s+1); prt_statement(node->rlink, s+1); break;
    case N_STMT_IF: 
    case N_STMT_SWITCH: prt_expression(node->llink, s+1); prt_statement(node->rlink, s+1); break;
    case N_STMT_WHILE: prt_expression(node->llink, s+1); prt_statement(node->rlink, s+1); break; 
    case N_STMT_DO: prt_statement(node->llink, s+1); prt_expression(node->rlink, s+1); break;
    case N_STMT_FOR: prt_for_expression(node->llink, s+1); prt_statement(node->rlink, s+1); break;
    case N_STMT_CONTINUE: break;
    case N_STMT_BREAK: break;
    case N_STMT_RETURN: if(node->clink) prt_expression(node->clink, s+1); break;
    default : printf("****syntax tree error******");
    }
}
void prt_statement_list(A_NODE *node, int s) {
print_node(node,s); 
switch(node->name) { 
    case N_STMT_LIST: prt_statement(node->llink, s+1); prt_statement_list(node->rlink, s+1); break;
    case N_STMT_LIST_NIL: break;
    default :
    printf("****syntax tree error******");
    } 
}
void prt_for_expression(A_NODE *node, int s) {
    print_node(node,s); 
    switch(node->name) {
    case N_FOR_EXP : 
        if(node->llink) prt_expression(node->llink, s+1); 
        if(node->clink) prt_expression(node->clink, s+1); 
        if(node->rlink) prt_expression(node->rlink, s+1); 
        break;
    default :
        printf("****syntax tree error******");
    }
}
void prt_integer(int a, int s) {
    //print_space(s);
    //printf("%d", a);
}
void prt_STRING(char *str, int s) {
    //print_space(s); 
    //printf("%s", str);
} 

char *type_kind_name[]={"NULL","ENUM","ARRAY","STRUCT","UNION","FUNC","POINTER","VOI D"};

void prt_A_TYPE(A_TYPE *t, int s) {
//    print_space(s); 
    if (t==int_type)
        printf("int"); 
    else if (t==float_type)
        printf("float"); 
    else if (t==char_type)
        printf("char %d",t->size); 
    else if (t==void_type)
        printf("void"); 
    else if (t->kind==T_NULL)
        printf("null"); 
    else if (t->prt)
        printf("DONE:%x",t);
    else
        switch (t->kind) {
            case T_ENUM: t->prt=TRUE;
                //printf("ENUM\n");
                //print_space(s); 
                //printf("| ENUMERATORS\n"); 
                prt_A_ID_LIST(t->field,s+2);
                break;
            case T_POINTER: t->prt=TRUE;
                printf("*");
                //printf("POINTER\n");
                //print_space(s); printf("| ELEMENT_TYPE\n"); 
                prt_A_TYPE(t->element_type,s+2);
                break;
            case T_ARRAY: t->prt=TRUE;
                //printf("ARRAY\n");
                print_space(s); 
                //printf("| INDEX\n"); 
                if (t->expr)
                    prt_expression(t->expr,s+2); 
                else {
                //print_space(s+2); 
                //printf("(none)\n");} print_space(s); printf("| ELEMENT_TYPE\n"); 
                prt_A_TYPE(t->element_type,s+2);
                break;
            case T_STRUCT: t->prt=TRUE;
                //printf("STRUCT\n");
                //print_space(s); printf("| FIELD\n"); 
                prt_A_ID_LIST(t->field,s+2);
                break;
            case T_UNION: t->prt=TRUE;
                //printf("UNION\n");
                //print_space(s); printf("| FIELD\n"); 
                prt_A_ID_LIST(t->field,s+2);
                break;
            case T_FUNC: t->prt=TRUE;
                printf("(");
                //printf("FUNCTION\n");
                //print_space(s); 
                //printf("| PARAMETER\n");
                prt_A_ID_LIST(t->field,s+2); 
                printf(")");
                //print_space(s); 
                //printf("| TYPE\n"); 
                printf("<RETURN TYPE: ");
                prt_A_TYPE(t->element_type,s+2); 
                printf(">");
                printf("\n");
                if (t->expr) {
                    //print_space(s); 
                    //printf("| BODY\n"); 
                    prt_statement(t->expr,s+2);
                }
            }
        }
}

void prt_A_ID_LIST(A_ID *id, int s) {
    while (id) {
        prt_A_ID(id,s);
        if(id->kind == ID_VAR)
            printf(";\n");
        id=id->link;
       
        if(id)
        {
            if(id->kind == ID_PARM)
                printf(", ");
//            printf("kind : %d\n", id->kind);
        }
    } 
}

char *id_kind_name[]={"NULL","VAR","FUNC","PARM","FIELD","TYPE","ENUM","STRUCT","ENUM _LITERAL"};

char *spec_name[]={"NULL","AUTO","TYPEDEF","STATIC"};

void prt_A_ID_NAME(A_ID *id, int s) {
    //print_space(s);
    //printf("(ID=\"%s\") TYPE:%x KIND:%s SPEC=%s LEV=%d \n", id->name, id->type,
    //id_kind_name[id->kind], spec_name[id->specifier],id->level);
}

void prt_A_ID(A_ID *id, int s) {
//    print_space(s);
    printf("%s", id->name);
    // print_space(s);
   
    if (id->type) {
        print_space(s);
        //printf("| TYPE\n"); 
        prt_A_TYPE(id->type,s+2);
    }
    if (id->init) 
    { 
        print_space(s);
//        printf("| INIT\n");
        A_TYPE *temp_type = id->type;
            if(temp_type == 0)
                printf("<set as NULL>", id->init->clink->clink);
            else if(temp_type == int_type)
                printf("<set as %d>", id->init->clink->clink);
            else if(temp_type == float_type)
                printf("<float set as %f>", id->init->clink->clink);
            else if(temp_type == char_type)
                if(id->init->clink->clink > 255) // char or char*
                    printf("<set as %s>", id->init->clink->clink);
                else
                    printf("<set as %c>", id->init->clink->clink);

        if (id->kind==ID_ENUM_LITERAL)
        {
           prt_expression(id->init,s+2);
        }
    }
    else
    prt_initializer(id->init,s+2);
    //printf("\n");
}
```
