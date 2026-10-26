%{
#include <stdio.h>
#include "src/codegen/codegen.h"
#include <stdlib.h>
#include "src/symbols/symbols.h"

int yylex(void);
void yyerror(const char *message);
%}

%union {
    int ival;
    char *sval;
}

%type <ival> while_start while_condition
%type <ival> arguments

%token AUTO EXTRN CASE IF ELSE WHILE SWITCH GOTO RETURN
%token <sval> NAME STRING
%token <ival> NUMBER CONSTANT
%token EQ NE LE GE LSHIFT RSHIFT INC DEC

%nonassoc NAME_EXPR
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
    NAME {
        symbols_begin_function();
    } '(' optional_parameters ')' {
        codegen_function_start($1);
    } statement {
        codegen_function_end();
        free($1);
    }
    | EXTRN names ';'
    | NAME initializers ';'
    ;

parameters:
    NAME {
        symbols_add_parameter($1);
        free($1);
    }
    | parameters ',' NAME {
        symbols_add_parameter($3);
        free($3);
    }
    ;

optional_parameters:
    /* empty */
    | parameters
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
    | RETURN expression ';' {
        codegen_return();
    }
    | compound_statement
    | AUTO declarations ';'
    | EXTRN names ';'
    | NAME ':' statement
    | CASE constant_or_name ':' statement
    | GOTO expression ';'
    | IF '(' expression ')' if_start statement if_tail
    | WHILE while_start '(' expression ')' while_condition statement {
        codegen_while_end($2, $6);
    }
    | SWITCH expression statement
    | ';'
    ;

if_start:
    {
        codegen_if_start(codegen_new_label());
    }
    ;

if_tail:
    ELSE {
        codegen_if_else();
    } statement {
        codegen_if_end();
    }
    | %prec LOWER_THAN_ELSE {
        codegen_if_no_else();
    }
    ;

while_start:
    {
        $$ = codegen_new_label();
        codegen_emit_label($$);
    }
    ;

while_condition:
    {
        $$ = codegen_new_label();
        codegen_jump_zero($$);
    }
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
    NAME {
        if (symbols_add_local($1) != -1)
            codegen_allocate_local();
        free($1);
    }
    | NAME constant_or_name {
        if (symbols_add_local($1) != -1)
            codegen_allocate_local();
        free($1);
    }
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
    | '*' unary '=' assignment {
        codegen_store_indirect();
    }
    | NAME '=' assignment {
        int offset = symbols_local_offset($1);
        if (offset != -1)
            codegen_store_local(offset);
        free($1);
    }
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
    | equality EQ relational { codegen_compare_equal(); }
    | equality NE relational { codegen_compare_not_equal(); }
    ;

relational:
    shift
    | relational '<' shift { codegen_compare_less(); }
    | relational '>' shift { codegen_compare_greater(); }
    | relational LE shift { codegen_compare_less_equal(); }
    | relational GE shift { codegen_compare_greater_equal(); }
    ;

shift:
    additive %prec '<'
    | shift LSHIFT additive
    | shift RSHIFT additive
    ;

additive:
    multiplicative %prec '+'
    | additive '+' multiplicative {
        codegen_add();
    }
    | additive '-' multiplicative {
        codegen_subtract();
    }
    ;

multiplicative:
    unary
    | multiplicative '*' unary {
        codegen_multiply();
    }
    | multiplicative '/' unary {
        codegen_divide();
    }
    | multiplicative '%' unary {
        codegen_modulo();
    }
    ;

unary:
    postfix %prec '!'
    | INC unary
    | DEC unary
    | '!' unary { codegen_logical_not(); }
    | '-' unary %prec UMINUS { codegen_negate(); }
    | '*' unary %prec NAME_EXPR { codegen_load_indirect(); }
    | '&' NAME {
        int offset = symbols_parameter_offset($2);
        if (offset != -1)
            codegen_push_parameter_address(offset);
        else {
            offset = symbols_local_offset($2);
            if (offset != -1)
                codegen_push_local_address(offset);
        }
        free($2);
    }
    ;

postfix:
    primary
    | postfix INC
    | postfix DEC
    | postfix '[' expression ']' {
        codegen_index();
    }
    | postfix '(' arguments ')' {
        codegen_call($3);
    }
    | postfix '(' ')' {
        codegen_call(0);
    }
    ;

arguments:
    expression {
        $$ = 1;
    }
    | arguments ',' expression {
        $$ = $1 + 1;
    }
    ;

primary:
    NUMBER {
        codegen_push_immediate($1);
    }
    | CONSTANT
    | STRING
    | NAME %prec NAME_EXPR {
        int offset = symbols_parameter_offset($1);
        if (offset != -1) {
            codegen_push_parameter(offset);
        } else {
            offset = symbols_local_offset($1);
            if (offset != -1)
                codegen_push_local(offset);
            else
                codegen_push_name($1);
        }
        free($1);
    }
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