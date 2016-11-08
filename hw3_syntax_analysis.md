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

3. 구현 방법

4. 결과

5. 소스코드
