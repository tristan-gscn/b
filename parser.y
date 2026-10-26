%{
#include <stdio.h>
#include <stdlib.h>
#include "src/codegen/codegen.h"

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
    NAME '(' parameters ')' {
        codegen_function_start($1);
    } statement {
        codegen_function_end();
        free($1);
    }
    | NAME '(' ')' {
        codegen_function_start($1);
    } statement {
        codegen_function_end();
        free($1);
    }
    | EXTRN names ';'
    | NAME initializers ';'
    ;

parameters:
    NAME
    | parameters ',' NAME
    ;

initializers:
    initializer
    | initializers ',' initializer
    ;

initializer:
    constant_or_name
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
    assignment
    ;

assignment:
    conditional
    | unary '=' assignment
    ;

conditional:
    bitwise_or
    | bitwise_or '?' expression ':' conditional
    ;

bitwise_or:
    bitwise_xor
    | bitwise_or '|' bitwise_xor
    ;

bitwise_xor:
    bitwise_and %prec '^'
    | bitwise_xor '^' bitwise_and
    ;

bitwise_and:
    equality
    | bitwise_and '&' equality
    ;

equality:
    relational
    | equality EQ relational
    | equality NE relational
    ;

relational:
    shift
    | relational '<' shift
    | relational '>' shift
    | relational LE shift
    | relational GE shift
    ;

shift:
    additive %prec '<'
    | shift LSHIFT additive
    | shift RSHIFT additive
    ;

additive:
    multiplicative %prec '+'
    | additive '+' multiplicative
    | additive '-' multiplicative
    ;

multiplicative:
    unary
    | multiplicative '*' unary
    | multiplicative '/' unary
    | multiplicative '%' unary
    ;

unary:
    postfix %prec '!'
    | INC unary
    | DEC unary
    | '!' unary
    | '-' unary %prec UMINUS
    | '*' unary
    | '&' unary
    ;

postfix:
    primary
    | postfix INC
    | postfix DEC
    | postfix '[' expression ']'
    | postfix '(' arguments ')'
    | postfix '(' ')'
    ;

arguments:
    expression
    | arguments ',' expression
    ;

primary:
    NUMBER
    | CONSTANT
    | STRING
    | NAME
    | '(' expression ')'
    ;

constant_or_name:
    NUMBER
    | CONSTANT
    | STRING
    | NAME
    ;

%%

void yyerror(const char *message) {
    fprintf(stderr, "%s\n", message);
}

int main(void) {
    return yyparse() == 0 ? 0 : 1;
}