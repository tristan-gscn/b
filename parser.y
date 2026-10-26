%{
#include <stdio.h>
int yylex(void);
void yyerror(const char *message);
%}

%union {
    int ival;
    char *sval;
}

%token AUTO EXTRN CASE IF ELSE WHILE SWITCH GOTO RETURN
%token <sval> NAME STRING
%token <ival> NUMBER CONSTANT
%token EQ NE LE GE LSHIFT RSHIFT INC DEC

%right '='
%right '?' ':'
%left '|'
%left '^'
%left '&'
%left EQ NE
%left '<' '>' LE GE
%left LSHIFT RSHIFT
%left '+' '-'
%left '*' '/' '%'
%right '!' UMINUS
%left INC DEC
%left '(' '['
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

program:
    /* empty */
    | program definition
    ;

definition:
    NAME '(' parameters ')' statement
    | NAME '(' ')' statement
    | EXTRN names ';'
    ;

parameters:
    NAME
    | parameters ',' NAME
    ;

statement:
    expression ';'
    | RETURN ';'
    | RETURN expression ';'
    | compound_statement
    | AUTO declarations ';'
    | EXTRN names ';'
    | NAME ':' statement
    | CASE constant_or_name ':' statement
    | GOTO expression ';'
    | IF '(' expression ')' statement %prec LOWER_THAN_ELSE
    | IF '(' expression ')' statement ELSE statement
    | WHILE '(' expression ')' statement
    | SWITCH expression statement
    | ';'
    ;

compound_statement:
    '{' statement_list '}'
    ;

statement_list:
    /* empty */
    | statement_list statement
    ;

declarations:
    declaration
    | declarations ',' declaration
    ;

declaration:
    NAME
    | NAME constant_or_name
    ;

names:
    NAME
    | names ',' NAME
    ;

expression:
    NUMBER
    | NAME
    | STRING
    | CONSTANT
    | '(' expression ')'
    | NAME '=' expression
    | NAME '(' expr_list ')'
    | NAME '(' ')'
    | expression '(' expr_list ')'
    | expression '(' ')'
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
    | '-' expression %prec '@'
    | '*' expression %prec '@'
    | '&' expression %prec '@'
    ;

expr_list:
    expression
    | expr_list ',' expression
    ;

constant_or_name:
    NUMBER
    | CONSTANT
    | STRING
    | NAME
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    return yyparse();
}