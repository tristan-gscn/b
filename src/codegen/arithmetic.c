#include "codegen.h"
#include <stdio.h>

static void codegen_binary(const char *instruction)
{
    printf("    pop ebx\n");
    printf("    pop eax\n");
    printf("    %s eax, ebx\n", instruction);
    printf("    push eax\n");
}

void codegen_add(void) { codegen_binary("add"); }
void codegen_subtract(void) { codegen_binary("sub"); }
void codegen_multiply(void) { codegen_binary("imul"); }
void codegen_bitwise_or(void) { codegen_binary("or"); }
void codegen_bitwise_xor(void) { codegen_binary("xor"); }
void codegen_bitwise_and(void) { codegen_binary("and"); }

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
