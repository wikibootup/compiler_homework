(3) C언어 문법에서 declarator 및 parameter_type_ list 는 어떻게 구성되어 있는지 설명하시오. 

```yacc
declarator
    : pointer direct_declarator                 {$$ = setDeclaratorElementType(
$2,$1);}
    | direct_declarator                         {$$ = $1;}
    ;
pointer
    : STAR
    | STAR pointer                              {$$ = setTypeElementType($2,mak
eType(T_POINTER));}
    ;
direct_declarator
    : IDENTIFIER                                {$$=makeIdentifier($1);}
    | LP declarator RP {$$ = $2;}
    | direct_declarator LB constant_expression_opt RB
                                                {$$ = setDeclaratorElementType(
$1, setTypeExpr(makeType(T_ARRAY),$3));}
    | direct_declarator LP                      {$$ = current_id; current_level
++;} parameter_type_list_opt RP              {checkForwardReference(); current_
id=$3; current_level--; $$ = setDeclaratorElementType($1,setTypeField(makeType(
T_FUNC),$4));}
    ;
```

선언자(declarartor)는 포인터와 직접선언자의 합으로 분해된다. 포인터가 있는 경우 직접선언자 앞에 붙는다. 직접 선언자는 identifier 자체이거나 괄호에 둘러쌓인 indentifier이거나 좌측에 직접지시자를 두고 우측에 중괄호로 둘러쌓인 constant_expression_opt가 있는 경우이다.

```yacc
parameter_list
    : parameter_declaration                     {$$=$1;}
    | parameter_list COMMA parameter_declaration
                                                {$$=linkDeclaratorList($1,$3);}
    ;
parameter_declaration
    : declaration_specifiers declarator         {$$=setParameterDeclaratorSpeci
fier($2,$1);}
    | declaration_specifiers abstract_declarator_opt
                                                {$$=setParameterDeclaratorSpeci
fier(setDeclaratorType(makeDummyIdentifier(),$2),$1) ;}
    ;

```

인자리스트(parameter_list)는 인자가 하나인 경우 parameter_declaration의 형태로 선언명시자와 지시자의 합으로 분해되거나, 콤마(COMMA)를 구분자로 인자와 또다른 인자리스트의 합으로 분해된다.
