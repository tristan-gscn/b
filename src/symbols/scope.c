#include "symbols.h"
#include "internal.h"
#include <stdlib.h>
#include <string.h>

void symbols_begin_function(void)
{
    int i;

    for (i = 0; i < symbols_parameter_count; ++i)
        free((char *)symbols_parameters[i]);
    for (i = 0; i < symbols_local_count; ++i)
        free((char *)symbols_locals[i]);
    symbols_parameter_count = 0;
    symbols_local_count = 0;
}

int symbols_add_parameter(const char *name)
{
    int i;

    for (i = 0; i < symbols_parameter_count; ++i)
        if (strcmp(symbols_parameters[i], name) == 0)
            return 0;
    if (symbols_parameter_count >= MAX_SYMBOLS)
        return 0;
    symbols_parameters[symbols_parameter_count++] = strdup(name);
    return 1;
}

int symbols_add_local(const char *name)
{
    int i;

    for (i = 0; i < symbols_local_count; ++i)
        if (strcmp(symbols_locals[i], name) == 0)
            return -1;
    if (symbols_local_count >= MAX_SYMBOLS)
        return -1;
    symbols_locals[symbols_local_count] = strdup(name);
    return -4 * (++symbols_local_count);
}

int symbols_parameter_offset(const char *name)
{
    int i;

    for (i = 0; i < symbols_parameter_count; ++i)
        if (strcmp(symbols_parameters[i], name) == 0)
            return 8 + i * 4;
    return -1;
}

int symbols_local_offset(const char *name)
{
    int i;

    for (i = 0; i < symbols_local_count; ++i)
        if (strcmp(symbols_locals[i], name) == 0)
            return -4 * (i + 1);
    return -1;
}
