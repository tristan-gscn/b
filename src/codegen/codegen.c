#include "codegen.h"
#include <stdio.h>

void codegen_function_start(const char *name)
{
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