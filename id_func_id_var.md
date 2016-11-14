(5) C 언어 프로그램에서 선언되는 함수의 명칭이 ID_FUNC 로 정해지는 시기와 방법, 이때 호출하는 함수와 하는 일을 간단히 설명하시오.

```yacc
setDeclaratorListSpecifier


declaration
    : declaration_specifiers init_declarator_list_opt SEMICOLON
                                            {$$ = setDeclaratorListSpecifier($2
,$1);}
    ;
```

명칭(identifier)을 발견하였고, 그 뒤에 괄호가 있다면 `setDeclaratorListSpecifier` 함수를 호출하여 ID_FUNC로 지정한다.

이 때 setDeclaratorListSpecifier 함수는 심볼테이블을 검사하여 중복여부 판단, 명칭 종류 지정(함수, 구조체, 변수 등 구분을 위한), 기억장소 명시자인 경우 auto와 static 여부도 지정한다.

---

(6) 프로그램에서 선언되는 변수 명칭이 (그 종류가 ID_VAR 인 경우만) 심볼 테이블에 등록되고 중복 선언되는지를 검사하는 시기와 방법을 설명하시오. 

```yacc
setDeclaratorListSpecifier


declaration
    : declaration_specifiers init_declarator_list_opt SEMICOLON
                                            {$$ = setDeclaratorListSpecifier($2
,$1);}
    ;
```

명칭(identifier)을 발견하였고, 그 뒤에 괄호가 없고 storage class specifier가 TYPEDEF의 형태가 아닌 경우 ID_VAR으로 지정된다. 이 때, `setDeclaratorListSpecifier` 함수를 호출하여 지정된다.
