#include "codegen.h"
#include <stdio.h>

static int next_label;
static int next_string;
static int current_return_label;
static int current_default_return_label;
static int current_function_id;
static int switch_active;
static int switch_skip_label;
static int current_else_label;
static int current_if_end_label;
#define CONDITIONAL_DEPTH 64
static int conditional_else_labels[CONDITIONAL_DEPTH];
static int conditional_end_labels[CONDITIONAL_DEPTH];
static int conditional_depth;

void codegen_function_start(const char *name)
{
    ++current_function_id;
    printf(".intel_syntax noprefix\n");
    printf(".text\n");
    printf(".globl %s\n", name);
    printf("%s:\n", name);
    printf("    .long %s + 4\n", name);
    printf("    enter 0, 0\n");
    current_default_return_label = codegen_new_label();
    current_return_label = codegen_new_label();
}

void codegen_function_end(void)
{
    codegen_emit_label(current_default_return_label);
    printf("    mov eax, 0\n");
    codegen_jump(current_return_label);
    codegen_emit_label(current_return_label);
    printf("    leave\n");
    printf("    ret\n");
}

void codegen_push_immediate(int value)
{
    printf("    push %d\n", value);
}

void codegen_push_string(const char *value)
{
    const unsigned char *p = (const unsigned char *)value;
    int label = next_string++;

    printf(".section .rodata\n");
    printf(".LC%d:\n", label);
    printf("    .byte ");
    do {
        printf("%s%u", p == (const unsigned char *)value ? "" : ", ",
            (unsigned int)*p);
    } while (*p++ != '\0');
    printf("\n.text\n");
    printf("    lea eax, [.LC%d]\n", label);
    printf("    push eax\n");
}

void codegen_push_parameter(int offset)
{
    printf("    push DWORD PTR [ebp + %d]\n", offset);
}

void codegen_push_local(int offset)
{
    printf("    push DWORD PTR [ebp - %d]\n", -offset);
}

void codegen_push_parameter_address(int offset)
{
    printf("    lea eax, [ebp + %d]\n", offset);
    printf("    push eax\n");
}

void codegen_push_local_address(int offset)
{
    printf("    lea eax, [ebp - %d]\n", -offset);
    printf("    push eax\n");
}

void codegen_push_name(const char *name)
{
    printf("    push DWORD PTR [%s]\n", name);
}

void codegen_push_name_address(const char *name)
{
    printf("    lea eax, [%s]\n", name);
    printf("    push eax\n");
}

void codegen_store_local(int offset)
{
    printf("    pop eax\n");
    printf("    mov DWORD PTR [ebp - %d], eax\n", -offset);
}

void codegen_load_indirect(void)
{
    printf("    pop eax\n");
    printf("    mov eax, DWORD PTR [eax]\n");
    printf("    push eax\n");
}

void codegen_store_indirect(void)
{
    printf("    pop eax\n");
    printf("    pop ebx\n");
    printf("    mov DWORD PTR [ebx], eax\n");
}

void codegen_index(void)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    lea eax, [eax + ebx * 4]\n");
    printf("    mov eax, DWORD PTR [eax]\n");
    printf("    push eax\n");
}

void codegen_index_address(void)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    lea eax, [eax + ebx * 4]\n");
    printf("    push eax\n");
}

void codegen_increment(int prefix, int delta)
{
    printf("    pop eax\n");
    printf("    mov ebx, DWORD PTR [eax]\n");
    printf("    mov ecx, ebx\n");
    if (delta > 0)
        printf("    add ebx, 1\n");
    else
        printf("    sub ebx, 1\n");
    printf("    mov DWORD PTR [eax], ebx\n");
    printf("    push %s\n", prefix ? "ebx" : "ecx");
}

void codegen_allocate_local(void)
{
    printf("    sub esp, 4\n");
}

void codegen_add(void)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    add eax, ebx\n");
    printf("    push eax\n");
}

void codegen_subtract(void)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    sub eax, ebx\n");
    printf("    push eax\n");
}

void codegen_multiply(void)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    imul eax, ebx\n");
    printf("    push eax\n");
}

void codegen_divide(void)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    cdq\n");
    printf("    idiv ebx\n");
    printf("    push eax\n");
}

void codegen_modulo(void)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    cdq\n");
    printf("    idiv ebx\n");
    printf("    push edx\n");
}

static void codegen_bitwise(const char *instruction)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    %s eax, ebx\n", instruction);
    printf("    push eax\n");
}

void codegen_bitwise_or(void) { codegen_bitwise("or"); }
void codegen_bitwise_xor(void) { codegen_bitwise("xor"); }
void codegen_bitwise_and(void) { codegen_bitwise("and"); }

void codegen_shift_left(void)
{
    printf("    pop ecx\n");
    printf("    pop eax\n");
    printf("    shl eax, cl\n");
    printf("    push eax\n");
}

void codegen_shift_right(void)
{
    printf("    pop ecx\n");
    printf("    pop eax\n");
    printf("    sar eax, cl\n");
    printf("    push eax\n");
}

void codegen_return(void)
{
    printf("    pop eax\n");
    codegen_jump(current_return_label);
}

void codegen_return_zero(void)
{
    printf("    mov eax, 0\n");
    codegen_jump(current_return_label);
}

void codegen_call(int argument_count)
{
    int i;

    for (i = 0; i < argument_count / 2; ++i) {
        int right = (argument_count - 1 - i) * 4;

        printf("    mov eax, DWORD PTR [esp + %d]\n", i * 4);
        printf("    mov ebx, DWORD PTR [esp + %d]\n", right);
        printf("    mov DWORD PTR [esp + %d], ebx\n", i * 4);
        printf("    mov DWORD PTR [esp + %d], eax\n", right);
    }
    printf("    call DWORD PTR [esp + %d]\n", argument_count * 4);
    printf("    add esp, %d\n", (argument_count + 1) * 4);
    printf("    push eax\n");
}

static void codegen_compare(const char *condition)
{
    int true_label = codegen_new_label();
    int end_label = codegen_new_label();

    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    cmp eax, ebx\n");
    printf("    %s .L%d\n", condition, true_label);
    printf("    push 0\n");
    printf("    jmp .L%d\n", end_label);
    printf(".L%d:\n", true_label);
    printf("    push 1\n");
    printf(".L%d:\n", end_label);
}

void codegen_compare_equal(void) { codegen_compare("je"); }
void codegen_compare_not_equal(void) { codegen_compare("jne"); }
void codegen_compare_less(void) { codegen_compare("jl"); }
void codegen_compare_less_equal(void) { codegen_compare("jle"); }
void codegen_compare_greater(void) { codegen_compare("jg"); }
void codegen_compare_greater_equal(void) { codegen_compare("jge"); }

void codegen_logical_not(void)
{
    int true_label = codegen_new_label();
    int end_label = codegen_new_label();

    printf("    pop eax\n");
    printf("    cmp eax, 0\n");
    printf("    je .L%d\n", true_label);
    printf("    push 0\n");
    printf("    jmp .L%d\n", end_label);
    printf(".L%d:\n", true_label);
    printf("    push 1\n");
    printf(".L%d:\n", end_label);
}

void codegen_negate(void)
{
    printf("    pop eax\n");
    printf("    neg eax\n");
    printf("    push eax\n");
}

int codegen_new_label(void)
{
    return next_label++;
}

void codegen_emit_label(int label)
{
    printf(".L%d:\n", label);
}

void codegen_jump(int label)
{
    printf("    jmp .L%d\n", label);
}

void codegen_jump_zero(int label)
{
    printf("    pop eax\n");
    printf("    cmp eax, 0\n");
    printf("    je .L%d\n", label);
}

void codegen_emit_named_label(const char *name)
{
    printf(".L%d_%s:\n", current_function_id, name);
}

void codegen_goto_named(const char *name)
{
    printf("    jmp .L%d_%s\n", current_function_id, name);
}

void codegen_switch_start(void)
{
    printf("    pop esi\n");
    printf("    xor edi, edi\n");
    switch_active = 1;
    switch_skip_label = -1;
}

void codegen_switch_case(int value)
{
    if (switch_active) {
        if (switch_skip_label != -1)
            codegen_emit_label(switch_skip_label);
        switch_skip_label = codegen_new_label();
        printf("    cmp edi, 0\n");
        printf("    jne .L%d_body\n", switch_skip_label);
        printf("    cmp esi, %d\n", value);
        printf("    jne .L%d\n", switch_skip_label);
        printf("    mov edi, 1\n");
        printf(".L%d_body:\n", switch_skip_label);
    }
}

void codegen_switch_default(void)
{
    if (switch_active) {
        if (switch_skip_label != -1)
            codegen_emit_label(switch_skip_label);
        switch_skip_label = codegen_new_label();
        printf("    cmp edi, 0\n");
        printf("    jne .L%d_body\n", switch_skip_label);
        printf("    mov edi, 1\n");
        printf(".L%d_body:\n", switch_skip_label);
    }
}

void codegen_switch_end(void)
{
    if (switch_active && switch_skip_label != -1)
        codegen_emit_label(switch_skip_label);
    switch_active = 0;
    switch_skip_label = -1;
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