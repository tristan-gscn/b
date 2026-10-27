#include "codegen.h"
#include <stdio.h>

int codegen_current_function_id;
int codegen_current_return_label;
int codegen_current_default_return_label;

static int next_label;

int codegen_new_label(void)
{
    return next_label++;
}

void codegen_emit_label(int label)
{
    printf(".L%d:\n", label);
}
