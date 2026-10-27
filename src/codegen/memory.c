#include "codegen.h"
#include <stdio.h>

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
    printf("    pop ebx\n");
    printf("    pop eax\n");
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
    printf("    %s ebx, 1\n", delta > 0 ? "add" : "sub");
    printf("    mov DWORD PTR [eax], ebx\n");
    printf("    push %s\n", prefix ? "ebx" : "ecx");
}

void codegen_allocate_local(void)
{
    printf("    sub esp, 4\n");
}
