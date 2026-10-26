#include "symbols.h"
#include <stdlib.h>
#include <string.h>

#define MAX_PARAMETERS 64

static const char *parameters[MAX_PARAMETERS];
static int parameter_count;

void symbols_begin_function(void)
{
    int i;

    for (i = 0; i < parameter_count; ++i)
        free((char *)parameters[i]);
    parameter_count = 0;
}

void symbols_add_parameter(const char *name)
{
    if (parameter_count < MAX_PARAMETERS)
        parameters[parameter_count++] = strdup(name);
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
