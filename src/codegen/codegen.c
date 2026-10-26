#include "codegen.h"
#include <stdio.h>

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