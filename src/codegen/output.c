#include "codegen.h"
#include <stdio.h>

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
    extern int codegen_current_function_id;

    printf(".L%d_%s:\n", codegen_current_function_id, name);
}

void codegen_goto_named(const char *name)
{
    extern int codegen_current_function_id;

    printf("    jmp .L%d_%s\n", codegen_current_function_id, name);
}
