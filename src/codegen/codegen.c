#include "codegen.h"
#include <stdio.h>

static int next_label;
static int current_else_label;
static int current_if_end_label;

void codegen_function_start(const char *name)
{
    printf(".intel_syntax noprefix\n");
    printf(".text\n");
    printf(".globl %s\n", name);
    printf("%s:\n", name);
    printf("    .long %s + 4\n", name);
    printf("    enter 0, 0\n");
}

void codegen_function_end(void)
{
    printf("    leave\n");
    printf("    ret\n");
}

void codegen_push_immediate(int value)
{
    printf("    push %d\n", value);
}

void codegen_push_parameter(int offset)
{
    printf("    push DWORD PTR [ebp + %d]\n", offset);
}

void codegen_push_local(int offset)
{
    printf("    push DWORD PTR [ebp - %d]\n", -offset);
}

void codegen_store_local(int offset)
{
    printf("    pop eax\n");
    printf("    mov DWORD PTR [ebp - %d], eax\n", -offset);
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

void codegen_return(void)
{
    printf("    pop eax\n");
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