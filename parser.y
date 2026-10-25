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

/* Déclaration des priorités et de l'associativité (du plus bas au plus haut) */
%right '='
%left '|'
%left '^'
%left '&'
%left EQ NE
%left '<' '>' LE GE
%left LSHIFT RSHIFT
%left '+' '-'
%left '*' '/' '%'
%right INC DEC

%%

program:
    /* empty */
    | program extdef
    ;

extdef:
    NAME '(' arg_list ')' statement
    | NAME '(' ')' statement
    | EXTRN var_list ';'
    ;

arg_list:
    NAME
    | arg_list ',' NAME
    ;

statement:
    expression ';'
    | RETURN expression ';'
    | compound_statement
    | IF '(' expression ')' statement
    | IF '(' expression ')' statement ELSE statement
    | WHILE '(' expression ')' statement
    | ';'
    ;

compound_statement:
    '{' statement_list '}'
    | '{' declaration_list statement_list '}'
    ;

declaration_list:
    AUTO var_list ';'
    | declaration_list AUTO var_list ';'
    ;

var_list:
    NAME
    | var_list ',' NAME
    ;

statement_list:
    statement
    | statement_list statement
    ;

expression:
    NUMBER
    | NAME
    | STRING
    | CONSTANT
    | '(' expression ')'
    | NAME '=' expression
    | expression '+' expression
    | expression '-' expression
    | expression '*' expression
    | expression '/' expression
    | expression '%' expression
    | expression LSHIFT expression
    | expression RSHIFT expression
    | expression '<' expression
    | expression '>' expression
    | expression LE expression
    | expression GE expression
    | expression EQ expression
    | expression NE expression
    | expression '&' expression
    | expression '^' expression
    | expression '|' expression
    | INC expression
    | DEC expression
    | expression INC
    | expression DEC
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    return yyparse();
}