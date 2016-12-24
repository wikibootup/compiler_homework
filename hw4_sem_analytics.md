1. 실행 이전의 이슈들
---

**1) 중복 선언**

`syntax.c`와 `sementic.c`의 함수 중 중복되는 것이 있다. `BOOLEAN isPointerOrArrayType(A_TYPE *)` 함수에 대하여 이름에 1을 더해주어 별도의 함수로 구분하였다.

**2) 중복 정의**

`type.h`는 `sementic.c`에서도 추가하는 라이브러리이므로 중복 정의의 문제를 일으킨다. 따라서 `type.h`의 상단에 `#pragma once`를 추가하였다.

**3) 선언부, 정의부 분리**

`sementic.c`를 직접 `main.c`에서 사용할 때에 재정의의 문제나 정의되지 않은 함수 등 여러 문제점들이 발생한다. 따라서 헤더파일을 만들어 분리하였다. 이 때, 전역 변수는 `.c`에 옮겨놓아야 컴파일에 지장이 없다.

**4) atof 선언 제거**

`stdlib.h`로 인하여 atof 선언은 필요가 없으며, 재정의 문제를 일으킨다. 따라서 제거하였다.
```
In file included from main.c:4:0:
sementic.c:8:7: error: conflicting types for ‘atof’
 float atof();
```

2. 테스트
---

**1) 배열이면서, 인덱스가 생략된 선언이면서 초기화 안된 경우**

```
$ cat tests/var_array_global_no_init_fail.c
int a[];

$ ./a.out tests/var_array_global_no_init_fail.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="a") TYPE:8faf998 KIND:VAR SPEC=AUTO LEV=0
| | TYPE
| | | ARRAY
| | | | INDEX
| | | | | (none)
| | | | ELEMENT_TYPE
| | | | | (int)
No more node at s==3
start semantic analysis
Segmentation fault (core dumped)
```

expr이 비어있으나 우선 허용이 되어야 한다고 생각했는데, 세그먼테이션 오류가 발생한다. 신택스 분석에서 발생한 오류로 세맨틱 오류 여부는 확인되지 않았다.

**2) 배열이면서, 인덱스가 명시된 선언이면서 초기화 안된 경우**

```sh
$ cat tests/var_array_global_ok.c
int a[5];

main()
{
}

$ ./a.out tests/var_array_global_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="a") TYPE:86d39b8 KIND:VAR SPEC=AUTO LEV=0
| | TYPE
| | | ARRAY
| | | | INDEX
| | | | | N_EXP_INT_CONST
| | | | | | 5
| | | | ELEMENT_TYPE
| | | | | (int)
No more node at s==3
| (ID="main") TYPE:86d3a20 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
======= semantic tree ==========
N_PROGRAM
| (ID="a") TYPE:86d39b8 KIND:VAR SPEC=AUTO LEV=0 VAL=0 ADDR=12
| | TYPE
| | | ARRAY
| | | | INDEX
| | | | | INT=5
| | | | ELEMENT_TYPE
| | | | | (int)
| (ID="main") TYPE:86d3a20 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST_NIL
```

신택스 분석에서는 N_EXP_INT_CONST라는 노드에 있던 인덱스 값이 INDEX(T_ARRAY)에 대하여 바로 나옴을 알 수 있다. 메인 함수에 대해서는 주소 12에서 시작함을 알 수 있다. 또한 리턴 타입이 명시되지 않아 정수형으로 자동 지정되어 있다. 몸체는 복합문이나, 내용이 없어 그 STATEMENT은 NIL이 되었다.

**3) 배열이면서, 인덱스가 명시된 선언이면서 인덱스가 수식으로 이루어진 경우**

```sh
$ cat tests/var_array_global_expr_cal_ok.c
int a[1+2+3+4+5*5];
$ ./a.out tests/var_array_global_expr_cal_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="a") TYPE:8426af8 KIND:VAR SPEC=AUTO LEV=0
| | TYPE
| | | ARRAY
| | | | INDEX
| | | | | N_EXP_ADD
| | | | | | N_EXP_ADD
| | | | | | | N_EXP_ADD
| | | | | | | | N_EXP_ADD
| | | | | | | | | N_EXP_INT_CONST
| | | | | | | | | | 1
| | | | | | | | | N_EXP_INT_CONST
| | | | | | | | | | 2
| | | | | | | | N_EXP_INT_CONST
| | | | | | | | | 3
| | | | | | | N_EXP_INT_CONST
| | | | | | | | 4
| | | | | | N_EXP_MUL
| | | | | | | N_EXP_INT_CONST
| | | | | | | | 5
| | | | | | | N_EXP_INT_CONST
| | | | | | | | 5
| | | | ELEMENT_TYPE
| | | | | (int)
No more node at s==3
start semantic analysis
======= semantic tree ==========
N_PROGRAM
| (ID="a") TYPE:8426af8 KIND:VAR SPEC=AUTO LEV=0 VAL=0 ADDR=12
| | TYPE
| | | ARRAY
| | | | INDEX
| | | | | INT=35
| | | | ELEMENT_TYPE
| | | | | (int)
```

신택스 분석으로 보면 N_EXP_INT_CONST 노드가 연산 노드들(N_EXP_ADD 등)과 복잡하게 이어져있지만 세멘틱 분석 이후 이것이 계산되어 35라는 값으로 바로 정의되어 있음을 알 수 있다.

**4) 지역 변수**

```sh
$ ./a.out tests/var_array_local_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:9fcc988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:9fcca30 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | ARRAY
| | | | | | | | | INDEX
| | | | | | | | | | N_EXP_INT_CONST
| | | | | | | | | | | 5
| | | | | | | | | ELEMENT_TYPE
| | | | | | | | | | (int)
No more node at s==8
| | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
======= semantic tree ==========
N_PROGRAM
| (ID="main") TYPE:9fcc988 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:9fcca30 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | TYPE
| | | | | | | | ARRAY
| | | | | | | | | INDEX
| | | | | | | | | | INT=5
| | | | | | | | | ELEMENT_TYPE
| | | | | | | | | | (int)
| | | | | | N_STMT_LIST_NIL
```

지역 변수로 정수형 배열을 선언한 모습이다. 주소 12에 VAL은 0으로 되어있다.

**5) 함수 선언

```sh
$ cat tests/var_func_dec_ok.c
void fun()
{
}

$ ./a.out tests/var_func_dec_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="fun") TYPE:8870998 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (void)| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
======= semantic tree ==========
N_PROGRAM
| (ID="fun") TYPE:8870998 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (void)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST_NIL
```

함수 선언은 신택스 분석과 노드가 다르지 않지만 호환되는 타입인지 등의 검사를 수행한다.

**6) 함수 호출**

```sh
$ cat tests/var_func_call_ok.c
void fun(int a){}

main()
{
    fun(1);
}

$ ./a.out tests/var_func_call_ok.c

start semantic analysis
ERROR num: 21, line: 5, identifier: �*��hAg     hAg     hAg     hAg     �Ag     hAg     hAg     hEg
======= semantic tree ==========
N_PROGRAM
| (ID="fun") TYPE:96799e8 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | | (ID="a") TYPE:96745a0 KIND:PARM SPEC=NULL LEV=1 VAL=0 ADDR=12
| | | | | | TYPE
| | | | | | | (int)
| | | | TYPE
| | | | | (void)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST_NIL
| (ID="main") TYPE:9679a90 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_EXPRESSION
| | | | | | | | N_EXP_FUNCTION_CALL
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="fun") TYPE:96799e8 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | | | | | | | | N_ARG_LIST
| | | | | | | | | | N_EXP_INT_CONST
| | | | | | | | | | | INT=1
| | | | | | | | | | N_ARG_LIST_NIL
| | | | | | | N_STMT_LIST_NIL
```

함수 호출은 정상적으로 이루어져야 하지만 21번 오류가 발생하였다.

**7) 구조체 필드 함수형 선언**

```sh
$ cat tests/var_struct_field_func_type_fail.c
struct s
{
    void func();
};
$ ./a.out tests/var_struct_field_func_type_fail.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="") TYPE:95fa988 KIND:VAR SPEC=AUTO LEV=0
| | TYPE
| | | STRUCT
| | | | FIELD
| | | | | (ID="func") TYPE:95fa9f0 KIND:FIELD SPEC=NULL LEV=1
| | | | | | TYPE
| | | | | | | FUNCTION
| | | | | | | | PARAMETER
| | | | | | | | TYPE
| | | | | | | | | (void)No more node at s==7
No more node at s==3
start semantic analysis
ERROR num: 84, line: 3, identifier: ��
======= semantic tree ==========
N_PROGRAM
| (ID="") TYPE:95fa988 KIND:VAR SPEC=AUTO LEV=0 VAL=0 ADDR=12
| | TYPE
| | | STRUCT
| | | | FIELD
| | | | | (ID="func") TYPE:95fa9f0 KIND:FIELD SPEC=NULL LEV=1 VAL=0 ADDR=0
| | | | | | TYPE
| | | | | | | FUNCTION
| | | | | | | | PARAMETER
| | | | | | | | TYPE
| | | | | | | | | (void)
```

구조체 필드 타입은 함수일 수 없다. 따라서 84번 오류가 발생하였다.

**8) 구조체 필드 변수들**

```sh
$ cat tests/var_struct_field_ok.c
struct s
{
    int i;
    float f;
    char c;
};
wikibootup@wikibootup-VirtualBox:~/git/compiler_homework/hw4_sementic_analysis$ ./a.out tests/var_struct_field_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="") TYPE:97b1988 KIND:VAR SPEC=AUTO LEV=0
| | TYPE
| | | STRUCT
| | | | FIELD
| | | | | (ID="i") TYPE:97ac5a0 KIND:FIELD SPEC=NULL LEV=1
| | | | | | TYPE
| | | | | | | (int)
No more node at s==7
| | | | | (ID="f") TYPE:97ac5f8 KIND:FIELD SPEC=NULL LEV=1
| | | | | | TYPE
| | | | | | | (float)
No more node at s==7
| | | | | (ID="c") TYPE:97ac650 KIND:FIELD SPEC=NULL LEV=1
| | | | | | TYPE
| | | | | | | (char 1)
No more node at s==7
No more node at s==3
start semantic analysis
======= semantic tree ==========
N_PROGRAM
| (ID="") TYPE:97b1988 KIND:VAR SPEC=AUTO LEV=0 VAL=0 ADDR=12
| | TYPE
| | | STRUCT
| | | | FIELD
| | | | | (ID="i") TYPE:97ac5a0 KIND:FIELD SPEC=NULL LEV=1 VAL=0 ADDR=0
| | | | | | TYPE
| | | | | | | (int)
| | | | | (ID="f") TYPE:97ac5f8 KIND:FIELD SPEC=NULL LEV=1 VAL=0 ADDR=4
| | | | | | TYPE
| | | | | | | (float)
| | | | | (ID="c") TYPE:97ac650 KIND:FIELD SPEC=NULL LEV=1 VAL=0 ADDR=8
| | | | | | TYPE
| | | | | | | (char 1)
```

글로벌 스코프로 선언된 구조체에 대한 구조체 필드 변수들은 주소 0에서부터 4씩 증가하며 정의됨을 알 수 있다.

**9) 스태틱 변수**

```sh
$ cat tests/var_static_local_level_ok.c
main()
{
    static int a;
    int b;
}
$ ./a.out tests/var_static_local_level_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:9170988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:916b5a0 KIND:VAR SPEC=TYPEDEF LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | (ID="b") TYPE:916b5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
======= semantic tree ==========
N_PROGRAM
| (ID="main") TYPE:9170988 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:916b5a0 KIND:VAR SPEC=TYPEDEF LEV=0 VAL=0 ADDR=12
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | (ID="b") TYPE:916b5a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | N_STMT_LIST_NIL
```

스태틱 변수는 메인 함수 안에 있음에도 스코프 레벨이 0임을 확인하였다. 이는 다른 지역 변수(b)와 비교된다.


**10) enum 상수**

```sh
$ cat tests/enum_ok.c
enum t {a, b, c=1.5, d=15, e='e', f};
wikibootup@wikibootup-VirtualBox:~/git/compiler_homework/hw4_sementic_analysis$ ./a.out tests/enum_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="") TYPE:862b988 KIND:VAR SPEC=AUTO LEV=0
| | TYPE
| | | ENUM
| | | | ENUMERATORS
| | | | | (ID="a") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0
No more node at s==7
| | | | | (ID="b") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0
No more node at s==7
| | | | | (ID="c") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0
| | | | | | INIT
| | | | | | | N_EXP_FLOAT_CONST
| | | | | | | | 1.5
| | | | | (ID="d") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0
| | | | | | INIT
| | | | | | | N_EXP_INT_CONST
| | | | | | | | 15
| | | | | (ID="e") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0
| | | | | | INIT
| | | | | | | N_EXP_CHAR_CONST
| | | | | | | | 101
| | | | | (ID="f") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0
No more node at s==7
No more node at s==3
start semantic analysis
ERROR num: 81, line: 1, identifier: `�p���@�b
ERROR num: 81, line: 1, identifier: `�p����b
======= semantic tree ==========
N_PROGRAM
| (ID="") TYPE:862b988 KIND:VAR SPEC=AUTO LEV=0 VAL=0 ADDR=12
| | TYPE
| | | ENUM
| | | | ENUMERATORS
| | | | | (ID="a") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0 VAL=0 ADDR=0
| | | | | (ID="b") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0 VAL=0 ADDR=0
| | | | | | INIT
| | | | | | | INT=1
| | | | | (ID="c") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0 VAL=0 ADDR=0
| | | | | | INIT
| | | | | | | INT=1224736768
| | | | | (ID="d") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0 VAL=0 ADDR=0
| | | | | | INIT
| | | | | | | INT=15
| | | | | (ID="e") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0 VAL=0 ADDR=0
| | | | | | INIT
| | | | | | | INT=101
| | | | | (ID="f") TYPE:0 KIND:ENUM _LITERAL SPEC=NULL LEV=0 VAL=0 ADDR=0
| | | | | | INIT
| | | | | | | INT=102
```

enum 상수 같은 경우 0부터 그 값이 차례로 증가하는데, 중간에 값을 명시해주면 그 값에서부터 다시 1씩 증가함을 볼 수 있다. 중간에 실수형 타입이 선언되면 그 값이 실수 타입이 아니라, 주소같은 `INT=1224736768`으로 정의되는데, 오류로 보인다.

**11) 반복문 for**

```sh
$ cat tests/exp_for_ok.c
main()
{
    int i;
    for( ; i < 10 ; i++);
}
$ ./a.out tests/exp_for_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:928d988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="i") TYPE:92885a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_FOR
| | | | | | | | N_FOR_EXP
| | | | | | | | | N_EXP_LSS
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="i") TYPE:92885a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | | | N_EXP_INT_CONST
| | | | | | | | | | | 10
| | | | | | | | | N_EXP_POST_INC
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="i") TYPE:92885a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | N_STMT_EMPTY
| | | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
======= semantic tree ==========
N_PROGRAM
| (ID="main") TYPE:928d988 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="i") TYPE:92885a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_FOR
| | | | | | | | N_FOR_EXP
| | | | | | | | | N_EXP_LSS
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="i") TYPE:92885a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | | | | N_EXP_INT_CONST
| | | | | | | | | | | INT=10
| | | | | | | | | N_EXP_POST_INC
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="i") TYPE:92885a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | | N_STMT_EMPTY
| | | | | | | N_STMT_LIST_NIL
```

처음 정수값 0부터 10까지 수행될 것임을(`N_EXP_INT_CONST||..|INT=10`) 알 수 있다.

**12) while 문 호환성 경고하는 경우**

```sh
$ cat tests/exp_while_fail.c
// should be in main
main()
{
while(1.5)
{

}
}
$ ./a.out tests/exp_while_fail.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:98d7988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_WHILE
| | | | | | | | N_EXP_FLOAT_CONST
| | | | | | | | | 1.5
| | | | | | | | N_STMT_COMPOUND
| | | | | | | | | N_STMT_LIST_NIL
| | | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
WARNING num: 16, line: 4
======= semantic tree ==========
N_PROGRAM
| (ID="main") TYPE:98d7988 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_WHILE
| | | | | | | | N_EXP_CAST
****semantic tree error******| | | | | | | | N_STMT_COMPOUND
| | | | | | | | | N_STMT_LIST_NIL
| | | | | | | N_STMT_LIST_NIL
```

while 인자에 실수형이 오는 경우 신택스 구문은 통과하지만 세맨틱 분석 결과 16번 경고를 내보낸다.

**13) 증감 연산**

```sh
$ cat tests/exp_post_op_ok.c
main()
{
    int a;
    a++;
    a--;
}
$ ./a.out tests/exp_post_op_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:8c52988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:8c4d5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_EXPRESSION
| | | | | | | | N_EXP_POST_INC
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="a") TYPE:8c4d5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | N_STMT_LIST
| | | | | | | | N_STMT_EXPRESSION
| | | | | | | | | N_EXP_POST_DEC
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="a") TYPE:8c4d5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
======= semantic tree ==========
N_PROGRAM
| (ID="main") TYPE:8c52988 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:8c4d5a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_EXPRESSION
| | | | | | | | N_EXP_POST_INC
| | | | | | | | | N_EXP_IDENT
| | | | | | | | | | (ID="a") TYPE:8c4d5a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | N_STMT_LIST
| | | | | | | | N_STMT_EXPRESSION
| | | | | | | | | N_EXP_POST_DEC
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="a") TYPE:8c4d5a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | | N_STMT_LIST_NIL
```

증감 연산은 N_EXP_POST_INC, N_EXP_POST_DEC의 노드로 정상 분석한다. 신택스 분석과 차이가 없어보인다.

**14) 구조체 참조**


```sh
$ cat tests/exp_post_struct_ref_ok.c
struct s {
    int a;
    struct s *b;
};
main()
{
    s var, var2;
    var->b = var2;
}

$ ./a.out tests/exp_post_struct_ref_ok.c

start syntax analysis
Segmentation fault (core dumped)
```

구조체 참조는 허용되어야 할 것 같은데, 이미 구조체를 선언하는 부분에서 신택스 오류가 발생한다.

**15) switch case 오류**

```sh
$ cat tests/selection_switch_ok.c
main()
{
    int i;
    switch(i)
    {
        case 0: {
            break;
        }
        default: {
            break;
        }
    }
}
$ ./a.out tests/selection_switch_ok.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:8eb4988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="i") TYPE:8eaf5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_SWITCH
| | | | | | | | N_EXP_IDENT
| | | | | | | | | (ID="i") TYPE:8eaf5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | N_STMT_COMPOUND
| | | | | | | | | N_STMT_LIST
| | | | | | | | | | N_STMT_LABEL_CASE
| | | | | | | | | | | N_EXP_INT_CONST
| | | | | | | | | | | | 0
| | | | | | | | | | | N_STMT_COMPOUND
| | | | | | | | | | | | N_STMT_LIST
| | | | | | | | | | | | | N_STMT_BREAK
| | | | | | | | | | | | | N_STMT_LIST_NIL
| | | | | | | | | | N_STMT_LIST
| | | | | | | | | | | N_STMT_LABEL_DEFAULT
| | | | | | | | | | | | N_STMT_COMPOUND
| | | | | | | | | | | | | N_STMT_LIST
| | | | | | | | | | | | | | N_STMT_BREAK
| | | | | | | | | | | | | | N_STMT_LIST_NIL
| | | | | | | | | | | N_STMT_LIST_NIL
| | | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
ERROR num: 71, line: 8, identifier: �vֿt
Segmentation fault (core dumped)
```

케이스 문이 스위치 문 안에 있는 대도 71번 오류가 발생하였다.

**16) break 문 오류**

```sh
$ cat tests/statement_break_fail.c
main()
{
    if(1)
    {
        break;
    }
}
$ ./a.out tests/statement_break_fail.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:91fd988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_IF
| | | | | | | | N_EXP_INT_CONST
| | | | | | | | | 1
| | | | | | | | N_STMT_COMPOUND
| | | | | | | | | N_STMT_LIST
| | | | | | | | | | N_STMT_BREAK
| | | | | | | | | | N_STMT_LIST_NIL
| | | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
ERROR num: 73, line: 5, identifier: )
======= semantic tree ==========
N_PROGRAM
| (ID="main") TYPE:91fd988 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_IF
| | | | | | | | N_EXP_INT_CONST
| | | | | | | | | INT=1
| | | | | | | | N_STMT_COMPOUND
| | | | | | | | | N_STMT_LIST
| | | | | | | | | | N_STMT_BREAK
| | | | | | | | | | N_STMT_LIST_NIL
| | | | | | | N_STMT_LIST_NIL
```

브레이크 문은 조건문에는 나올 수 없다. 따라서 오류가 발생하는 것이 정상이다.


**17) continue 문 오류**

```sh
$ cat tests/statement_continue_fail.c
main()
{
continue;
}
$ ./a.out tests/statement_continue_fail.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:894e988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_CONTINUE
| | | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
ERROR num: 74, line: 3, identifier: �*��h�h�h�h���h�h�h��
======= semantic tree ==========
N_PROGRAM
| (ID="main") TYPE:894e988 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_CONTINUE
| | | | | | | N_STMT_LIST_NIL
```

continue 문이 반복문이 아닌 곳에, 복합문에 바로 나오는 것은 오류가 발생함을 확인하였다.

**18) lvalue 오류**

```sh
$ cat tests/exp_post_op_lvalue_fail.c
main()
{
    int a, b;
    a++ = (int)b;
}
$ ./a.out tests/exp_post_op_lvalue_fail.c

start syntax analysis
======= syntax tree ==========
N_PROGRAM
| (ID="main") TYPE:8e50988 KIND:FUNC SPEC=NULL LEV=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:8e4b5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | (ID="b") TYPE:8e4b5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | TYPE
| | | | | | | | (int)
No more node at s==8
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_EXPRESSION
| | | | | | | | N_EXP_ASSIGN
| | | | | | | | | N_EXP_POST_INC
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="a") TYPE:8e4b5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | | | N_EXP_CAST
| | | | | | | | | | (int)
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="b") TYPE:8e4b5a0 KIND:VAR SPEC=AUTO LEV=1
| | | | | | | N_STMT_LIST_NIL
No more node at s==3
start semantic analysis
ERROR num: 60, line: 4, identifier: �*��h�h�h�h���h�h�h�
ERROR num: 58, line: 4, identifier:
======= semantic tree ==========
N_PROGRAM
| (ID="main") TYPE:8e50988 KIND:FUNC SPEC=NULL LEV=0 VAL=0 ADDR=0
| | TYPE
| | | FUNCTION
| | | | PARAMETER
| | | | TYPE
| | | | | (int)
| | | | BODY
| | | | | N_STMT_COMPOUND
| | | | | | (ID="a") TYPE:8e4b5a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | (ID="b") TYPE:8e4b5a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=16
| | | | | | | TYPE
| | | | | | | | (int)
| | | | | | N_STMT_LIST
| | | | | | | N_STMT_EXPRESSION
| | | | | | | | N_EXP_ASSIGN
| | | | | | | | | N_EXP_POST_INC
| | | | | | | | | | N_EXP_IDENT
| | | | | | | | | | | (ID="a") TYPE:8e4b5a0 KIND:VAR SPEC=AUTO LEV=1 VAL=0 ADDR=12
| | | | | | | | | N_EXP_CAST
****semantic tree error******| | | | | | | N_STMT_LIST_NIL
```

증감연산자(후위수식postfix-expression)은 lvalue일 수 없다. 그에 대한 테스트이다. 하지만 대입 과정에서 58번 오류(타입 캐스팅 오류)가 함께 발생한다. 타입이 같음에도 이런 오류가 발생하는 것이 의아하다.
