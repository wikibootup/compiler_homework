(2)  0 과 1 로 이루어진 이진수를 입력으로 10진수를 출력하는 lex 와 yacc 프로그램을 작성하시오. Lex 프로그램은 토큰으로 간단히 문자 한개 만을 잘라 보내도록 한다. 

---

**제약조건**

1. 이진수 입력
2. lex는 '문자' 토큰 단위로 파서에 전달

**아이디어**

- 이진수 숫자 또는 공백문자를 입력받는 문법규칙 생성

**검증 방법**

- 랜덤 생성한 50개의 이진수 값이 저장된 텍스트로 대조

결과
---

```sh
$ cat test.txt | ./a.out
00000001 -> 1
10000110 -> 134
11011100 -> 220
00001110 -> 14
11100001 -> 225
11100101 -> 229
00001111 -> 15
10110101  -> 181
00000010 -> 2
10111010 -> 186
11101001 -> 233
10001010 -> 138
00010001 -> 17
11011111 -> 223
01011100 -> 92
01000111  -> 71
11101001 -> 233
10011010 -> 154
00000010 -> 2
01001110 -> 78
11110110 -> 246
11010111 -> 215
10100110 -> 166
01010011  -> 83
00111110 -> 62
01000011 -> 67
11100001 -> 225
10011111 -> 159
11111000 -> 248
01111010 -> 122
10010001 -> 145
10011011  -> 155
11110010 -> 242
10001110 -> 142
01111100 -> 124
00001001 -> 9
01000100 -> 68
00001110 -> 14
10111000 -> 184
01101100  -> 108
10000111 -> 135
01001010 -> 74
10110100 -> 180
11100010 -> 226
01100110 -> 102
10100101 -> 165
10110111 -> 183
10110111  -> 183
10010100 -> 148
00001101 -> 13
```

소스코드
---

- binToDec.l

```lex
BIN_DIGIT                   [0-1]
NEW_LINE                    [\n]

%{
    #include "y.tab.h"
    #include <stdlib.h>
    void    yyerror(char *);
%}

%%

{BIN_DIGIT}                 { yylval = *yytext; return BIN; }
{NEW_LINE}                  { return NL; }

%%

int yywrap(void) {
    return 1;
}
```

---

- binToDec.y

```yacc
%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

    void yyerror(char *);
    void binToDec(char digit);
    void binInit();             // initialize dec to 0 when '\n' inserted 
    int yylex(void);
    int dec;                    // decimal value
    const int OFFSET = 48;      // for ascii 0
%}

%token BIN NL

%%

program:
        program converter
        | /* NULL */
        ;

converter:
    BIN                 { printf("%c", $1); binToDec($1); }
    | NL                { printf(" -> %d\n", dec); binInit(); }
    ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}

void binToDec(char digit)
{
    dec = dec << 1;         // already inserted value LS 1
    dec += (digit-OFFSET);  // input value is inserted
}

void binInit()
{
    dec = 0;
}
```
