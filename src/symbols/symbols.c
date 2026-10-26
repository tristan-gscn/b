#include "symbols.h"
#include <stdlib.h>
#include <string.h>

#define MAX_SYMBOLS 64

static const char *parameters[MAX_SYMBOLS];
static const char *locals[MAX_SYMBOLS];
static int parameter_count;
static int local_count;

void symbols_begin_function(void)
{
    int i;

    for (i = 0; i < parameter_count; ++i)
        free((char *)parameters[i]);
    for (i = 0; i < local_count; ++i)
        free((char *)locals[i]);
    parameter_count = 0;
    local_count = 0;
}

void symbols_add_parameter(const char *name)
{
    if (parameter_count < MAX_SYMBOLS)
        parameters[parameter_count++] = strdup(name);
}

int symbols_add_local(const char *name)
{
    if (local_count >= MAX_SYMBOLS)
        return -1;
    locals[local_count] = strdup(name);
    return -4 * (++local_count);
}

int symbols_parameter_offset(const char *name)
{
    int i;

    for (i = 0; i < parameter_count; ++i) {
        if (strcmp(parameters[i], name) == 0)
            return 8 + i * 4;
    }
    return -1;
}

int symbols_local_offset(const char *name)
{
    int i;

    for (i = 0; i < local_count; ++i) {
        if (strcmp(locals[i], name) == 0)
            return -4 * (i + 1);
    }
    return -1;
}
