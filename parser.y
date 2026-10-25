%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex(void);
%}

%union {
    int ival;
    char *sval;
}

%token AUTO EXTRN CASE IF ELSE WHILE SWITCH GOTO RETURN
%token <sval> NAME STRING
%token <ival> NUMBER CONSTANT
%token EQ NE LE GE LSHIFT RSHIFT INC DEC

%%

program:
    /* empty */
    | program statement
    ;

statement:
    expression ';'
    | RETURN expression ';'
    ;

expression:
    NUMBER
    | NAME
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    return yyparse();
}