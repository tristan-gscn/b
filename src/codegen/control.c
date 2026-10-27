#include "codegen.h"
#include <stdio.h>

#define SWITCH_DEPTH 64
#define CONDITIONAL_DEPTH 64

static int switch_depth;
static int switch_skip_labels[SWITCH_DEPTH];
static int current_else_label;
static int current_if_end_label;
static int conditional_else_labels[CONDITIONAL_DEPTH];
static int conditional_end_labels[CONDITIONAL_DEPTH];
static int conditional_depth;

void codegen_switch_start(void)
{
    int depth = switch_depth++;

    printf("    pop eax\n");
    printf("    push esi\n");
    printf("    push edi\n");
    printf("    mov esi, eax\n");
    printf("    xor edi, edi\n");
    if (depth < SWITCH_DEPTH)
        switch_skip_labels[depth] = -1;
}

void codegen_switch_case(int value)
{
    int depth = switch_depth - 1;

    if (depth >= 0 && depth < SWITCH_DEPTH) {
        if (switch_skip_labels[depth] != -1)
            codegen_emit_label(switch_skip_labels[depth]);
        switch_skip_labels[depth] = codegen_new_label();
        printf("    cmp edi, 0\n");
        printf("    jne .L%d_body\n", switch_skip_labels[depth]);
        printf("    cmp esi, %d\n", value);
        printf("    jne .L%d\n", switch_skip_labels[depth]);
        printf("    mov edi, 1\n");
        printf(".L%d_body:\n", switch_skip_labels[depth]);
    }
}

void codegen_switch_default(void)
{
    int depth = switch_depth - 1;

    if (depth >= 0 && depth < SWITCH_DEPTH) {
        if (switch_skip_labels[depth] != -1)
            codegen_emit_label(switch_skip_labels[depth]);
        switch_skip_labels[depth] = codegen_new_label();
        printf("    cmp edi, 0\n");
        printf("    jne .L%d_body\n", switch_skip_labels[depth]);
        printf("    mov edi, 1\n");
        printf(".L%d_body:\n", switch_skip_labels[depth]);
    }
}

void codegen_switch_end(void)
{
    int depth = --switch_depth;

    if (depth >= 0 && depth < SWITCH_DEPTH &&
        switch_skip_labels[depth] != -1)
        codegen_emit_label(switch_skip_labels[depth]);
    printf("    pop edi\n");
    printf("    pop esi\n");
}

void codegen_conditional_start(void)
{
    int depth = conditional_depth++;

    if (depth >= CONDITIONAL_DEPTH)
        return;
    conditional_else_labels[depth] = codegen_new_label();
    conditional_end_labels[depth] = codegen_new_label();
    codegen_jump_zero(conditional_else_labels[depth]);
}

void codegen_conditional_else(void)
{
    int depth = conditional_depth - 1;

    if (depth < 0 || depth >= CONDITIONAL_DEPTH)
        return;
    codegen_jump(conditional_end_labels[depth]);
    codegen_emit_label(conditional_else_labels[depth]);
}

void codegen_conditional_end(void)
{
    int depth = conditional_depth - 1;

    if (depth < 0 || depth >= CONDITIONAL_DEPTH)
        return;
    codegen_emit_label(conditional_end_labels[depth]);
    --conditional_depth;
}

void codegen_if_start(int else_label)
{
    current_else_label = else_label;
    codegen_jump_zero(else_label);
}

void codegen_if_else(void)
{
    current_if_end_label = codegen_new_label();
    codegen_jump(current_if_end_label);
    codegen_emit_label(current_else_label);
}

void codegen_if_no_else(void)
{
    codegen_emit_label(current_else_label);
}

void codegen_if_end(void)
{
    codegen_emit_label(current_if_end_label);
}

void codegen_while_condition(int end_label)
{
    codegen_jump_zero(end_label);
}

void codegen_while_end(int start_label, int end_label)
{
    codegen_jump(start_label);
    codegen_emit_label(end_label);
}
