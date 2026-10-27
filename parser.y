%{
#include <stdio.h>
#include "src/codegen/codegen.h"
#include <stdlib.h>
#include <string.h>
#include "src/symbols/symbols.h"

int yylex(void);
void yyerror(const char *message);
static int parse_error;
#define MAX_LABELS 64
static char *labels[MAX_LABELS];
static char *gotos[MAX_LABELS];
#define MAX_SWITCHES 64
static int switch_cases[MAX_SWITCHES][MAX_LABELS];
static int switch_case_counts[MAX_LABELS];
static int label_count;
static int goto_count;
static int switch_depth;

static void begin_labels(void)
{
    label_count = 0;
    goto_count = 0;
    switch_depth = 0;
}

static int find_label(const char *name)
{
    int i;

    for (i = 0; i < label_count; ++i)
        if (strcmp(labels[i], name) == 0)
            return 1;
    return 0;
}

static void define_label(const char *name)
{
    if (find_label(name)) {
        fprintf(stderr, "duplicate label: %s\n", name);
        parse_error = 1;
        return;
    }
    if (label_count < MAX_LABELS)
        labels[label_count++] = strdup(name);
}

static void record_goto(const char *name)
{
    if (goto_count < MAX_LABELS)
        gotos[goto_count++] = strdup(name);
}

static void validate_gotos(void)
{
    int i;

    for (i = 0; i < goto_count; ++i) {
        if (!find_label(gotos[i])) {
            fprintf(stderr, "unknown label: %s\n", gotos[i]);
            parse_error = 1;
        }
        free(gotos[i]);
    }
    for (i = 0; i < label_count; ++i)
        free(labels[i]);
    label_count = 0;
    goto_count = 0;
}

static void report_unknown(const char *name)
{
    if (!symbols_is_global(name))
        fprintf(stderr, "unknown symbol: %s\n", name);
    if (!symbols_is_global(name))
        parse_error = 1;
}
%}

%union {
    int ival;
    char *sval;
}

%type <ival> while_start while_condition
%type <ival> arguments

%token AUTO EXTRN CASE DEFAULT IF ELSE WHILE SWITCH GOTO RETURN
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
%right INC DEC
%left ')'
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
        if (!symbols_add_global($1)) {
            fprintf(stderr, "duplicate global: %s\n", $1);
            parse_error = 1;
        }
        symbols_begin_function();
        begin_labels();
    } '(' optional_parameters ')' {
        codegen_function_start($1);
    } statement {
        validate_gotos();
        codegen_function_end();
        free($1);
    }
    | EXTRN external_names ';'
    | NAME {
        symbols_add_global($1);
    } initializers ';' {
        free($1);
    }
    ;

parameters:
    NAME {
        if (!symbols_add_parameter($1)) {
            fprintf(stderr, "duplicate parameter: %s\n", $1);
            parse_error = 1;
        }
        free($1);
    }
    | parameters ',' NAME {
        if (!symbols_add_parameter($3)) {
            fprintf(stderr, "duplicate parameter: %s\n", $3);
            parse_error = 1;
        }
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
    | RETURN ';' {
        codegen_return_zero();
    }
    | RETURN expression ';' {
        codegen_return();
    }
    | compound_statement
    | AUTO declarations ';'
    | EXTRN names ';'
    | NAME ':' {
        define_label($1);
        codegen_emit_named_label($1);
        free($1);
    } statement
    | CASE NUMBER ':' {
        int i;
        for (i = 0; i < switch_case_counts[switch_depth - 1]; ++i)
            if (switch_cases[switch_depth - 1][i] == $2) {
                fprintf(stderr, "duplicate case: %d\n", $2);
                parse_error = 1;
            }
        if (switch_case_counts[switch_depth - 1] < MAX_LABELS)
            switch_cases[switch_depth - 1]
                [switch_case_counts[switch_depth - 1]++] = $2;
        codegen_switch_case($2);
    } statement
    | CASE CONSTANT ':' {
        int i;
        for (i = 0; i < switch_case_counts[switch_depth - 1]; ++i)
            if (switch_cases[switch_depth - 1][i] == $2) {
                fprintf(stderr, "duplicate case: %d\n", $2);
                parse_error = 1;
            }
        if (switch_case_counts[switch_depth - 1] < MAX_LABELS)
            switch_cases[switch_depth - 1]
                [switch_case_counts[switch_depth - 1]++] = $2;
        codegen_switch_case($2);
    } statement
    | DEFAULT ':' {
        codegen_switch_default();
    } statement
    | GOTO NAME ';' {
        record_goto($2);
        codegen_goto_named($2);
        free($2);
    }
    | IF '(' expression ')' if_start statement if_tail
    | WHILE while_start '(' expression ')' while_condition statement {
        codegen_while_end($2, $6);
    }
    | SWITCH expression {
        codegen_switch_start();
        switch_case_counts[switch_depth++] = 0;
    } statement {
        codegen_switch_end();
        --switch_depth;
    }
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
        else {
            fprintf(stderr, "duplicate local: %s\n", $1);
            parse_error = 1;
        }
        free($1);
    }
    | NAME {
        if (symbols_add_local($1) != -1)
            codegen_allocate_local();
        else {
            fprintf(stderr, "duplicate local: %s\n", $1);
            parse_error = 1;
        }
    } auto_initializer {
        int offset = symbols_local_offset($1);

        if (offset != -1)
            codegen_store_local(offset);
        free($1);
    }
    ;

auto_initializer:
    NUMBER {
        codegen_push_immediate($1);
    }
    | CONSTANT {
        codegen_push_immediate($1);
    }
    | STRING {
        codegen_push_string($1);
        free($1);
    }
    | NAME {
        int offset = symbols_parameter_offset($1);

        if (offset != -1)
            codegen_push_parameter(offset);
        else {
            offset = symbols_local_offset($1);
            if (offset != -1)
                codegen_push_local(offset);
            else {
                report_unknown($1);
                codegen_push_name($1);
            }
        }
        free($1);
    }
    ;

names:
    NAME
    | names ',' NAME
    ;

external_names:
    NAME {
        if (!symbols_add_external($1)) {
            fprintf(stderr, "duplicate global: %s\n", $1);
            parse_error = 1;
        }
        free($1);
    }
    | external_names ',' NAME {
        if (!symbols_add_external($3)) {
            fprintf(stderr, "duplicate global: %s\n", $3);
            parse_error = 1;
        }
        free($3);
    }
    ;

expression:
    assignment
    ;

assignment:
    conditional
    | NAME '=' assignment {
        int offset = symbols_parameter_offset($1);
        if (offset != -1)
            codegen_push_parameter_address(offset);
        else {
            offset = symbols_local_offset($1);
            if (offset != -1)
                codegen_push_local_address(offset);
            else {
                report_unknown($1);
                codegen_push_name_address($1);
            }
        }
        free($1);
        codegen_store_indirect();
    }
    | lvalue '=' assignment {
        codegen_store_indirect();
    }
    ;

lvalue:
    '*' unary %prec NAME_EXPR
    | postfix '[' expression ']' %prec NAME_EXPR {
        codegen_index_address();
    }
    ;

conditional:
    bitwise_or
    | bitwise_or '?' {
        codegen_conditional_start();
    } expression ':' {
        codegen_conditional_else();
    } conditional {
        codegen_conditional_end();
    }
    ;

bitwise_or:
    bitwise_xor
    | bitwise_or '|' bitwise_xor { codegen_bitwise_or(); }
    ;

bitwise_xor:
    bitwise_and %prec '^'
    | bitwise_xor '^' bitwise_and { codegen_bitwise_xor(); }
    ;

bitwise_and:
    equality
    | bitwise_and '&' equality { codegen_bitwise_and(); }
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
    | shift LSHIFT additive { codegen_shift_left(); }
    | shift RSHIFT additive { codegen_shift_right(); }
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
    | INC '(' '*' unary ')' {
        codegen_increment(1, 1);
    }
    | DEC '(' '*' unary ')' {
        codegen_increment(1, -1);
    }
    | INC NAME '[' expression ']' {
        int offset = symbols_parameter_offset($2);
        if (offset != -1)
            codegen_push_parameter_address(offset);
        else {
            offset = symbols_local_offset($2);
            if (offset != -1)
                codegen_push_local_address(offset);
            else
                codegen_push_name_address($2);
        }
        free($2);
        codegen_index_address();
        codegen_increment(1, 1);
    }
    | DEC NAME '[' expression ']' {
        int offset = symbols_parameter_offset($2);
        if (offset != -1)
            codegen_push_parameter_address(offset);
        else {
            offset = symbols_local_offset($2);
            if (offset != -1)
                codegen_push_local_address(offset);
            else
                codegen_push_name_address($2);
        }
        free($2);
        codegen_index_address();
        codegen_increment(1, -1);
    }
    | INC NAME {
        int offset = symbols_parameter_offset($2);
        if (offset != -1)
            codegen_push_parameter_address(offset);
        else {
            offset = symbols_local_offset($2);
            if (offset != -1)
                codegen_push_local_address(offset);
            else
                codegen_push_name_address($2);
        }
        free($2);
        codegen_increment(1, 1);
    }
    | DEC NAME {
        int offset = symbols_parameter_offset($2);
        if (offset != -1)
            codegen_push_parameter_address(offset);
        else {
            offset = symbols_local_offset($2);
            if (offset != -1)
                codegen_push_local_address(offset);
            else
                codegen_push_name_address($2);
        }
        free($2);
        codegen_increment(1, -1);
    }
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
            else {
                report_unknown($2);
                codegen_push_name_address($2);
            }
        }
        free($2);
    }
    ;

postfix:
    primary
    | '(' '*' unary ')' INC {
        codegen_increment(0, 1);
    }
    | '(' '*' unary ')' DEC {
        codegen_increment(0, -1);
    }
    | NAME INC {
        int offset = symbols_parameter_offset($1);
        if (offset != -1)
            codegen_push_parameter_address(offset);
        else {
            offset = symbols_local_offset($1);
            if (offset != -1)
                codegen_push_local_address(offset);
            else
                codegen_push_name_address($1);
        }
        free($1);
        codegen_increment(0, 1);
    }
    | NAME DEC {
        int offset = symbols_parameter_offset($1);
        if (offset != -1)
            codegen_push_parameter_address(offset);
        else {
            offset = symbols_local_offset($1);
            if (offset != -1)
                codegen_push_local_address(offset);
            else
                codegen_push_name_address($1);
        }
        free($1);
        codegen_increment(0, -1);
    }
    | postfix '[' expression ']' INC {
        codegen_index_address();
        codegen_increment(0, 1);
    }
    | postfix '[' expression ']' DEC {
        codegen_index_address();
        codegen_increment(0, -1);
    }
    | postfix '[' expression ']' %prec NAME_EXPR {
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
    | CONSTANT {
        codegen_push_immediate($1);
    }
    | STRING {
        codegen_push_string($1);
        free($1);
    }
    | NAME %prec NAME_EXPR {
        int offset = symbols_parameter_offset($1);
        if (offset != -1) {
            codegen_push_parameter(offset);
        } else {
            offset = symbols_local_offset($1);
            if (offset != -1)
                codegen_push_local(offset);
            else {
                report_unknown($1);
                codegen_push_name($1);
            }
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
    return yyparse() == 0 && !parse_error ? 0 : 1;
}