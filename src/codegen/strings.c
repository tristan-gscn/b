#include "codegen.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_STRINGS 64

static int next_string;
static char *strings[MAX_STRINGS];
static int string_count;

void codegen_push_string(const char *value)
{
    int label = next_string++;

    printf("    lea eax, [.LC%d]\n", label);
    printf("    push eax\n");
    if (string_count < MAX_STRINGS)
        strings[string_count++] = strdup(value);
}

void codegen_finish_program(void)
{
    int i;

    if (string_count == 0)
        return;
    printf(".section .rodata\n");
    for (i = 0; i < string_count; ++i) {
        const unsigned char *p = (const unsigned char *)strings[i];
        int j;

        printf(".LC%d:\n    .byte ", i);
        for (j = 0; ; ++j) {
            if (j != 0)
                printf(", ");
            printf("%u", (unsigned int)p[j]);
            if (p[j] == '\0')
                break;
        }
        printf("\n");
        free(strings[i]);
    }
    string_count = 0;
}
