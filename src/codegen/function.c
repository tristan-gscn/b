#include "codegen.h"
#include "internal.h"
#include <stdio.h>

void codegen_function_start(const char *name)
{
    ++codegen_current_function_id;
    printf(".intel_syntax noprefix\n");
    printf(".text\n");
    printf(".globl %s\n", name);
    printf("%s:\n", name);
    printf("    .long %s + 4\n", name);
    printf("    enter 0, 0\n");
    codegen_current_default_return_label = codegen_new_label();
    codegen_current_return_label = codegen_new_label();
}

void codegen_function_end(void)
{
    codegen_emit_label(codegen_current_default_return_label);
    printf("    mov eax, 0\n");
    codegen_jump(codegen_current_return_label);
    codegen_emit_label(codegen_current_return_label);
    printf("    leave\n");
    printf("    ret\n");
}

void codegen_return(void)
{
    printf("    pop eax\n");
    codegen_jump(codegen_current_return_label);
}

void codegen_return_zero(void)
{
    printf("    mov eax, 0\n");
    codegen_jump(codegen_current_return_label);
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
