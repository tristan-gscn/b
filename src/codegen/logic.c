#include "codegen.h"
#include <stdio.h>

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
