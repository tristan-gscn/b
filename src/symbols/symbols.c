#include "symbols.h"
#include <stdlib.h>
#include <string.h>

#define MAX_SYMBOLS 64

static const char *parameters[MAX_SYMBOLS];
static const char *locals[MAX_SYMBOLS];
struct global_symbol {
    char *name;
    int defined;
};
static struct global_symbol globals[MAX_SYMBOLS];
static int parameter_count;
static int local_count;
static int global_count;

static int add_global(const char *name)
{
    int i;

    for (i = 0; i < global_count; ++i)
        if (strcmp(globals[i].name, name) == 0) {
            if (!globals[i].defined) {
                globals[i].defined = 1;
                return 1;
            }
            return 0;
        }
    if (global_count < MAX_SYMBOLS)
        globals[global_count++] = (struct global_symbol){ strdup(name), 1 };
    return 1;
}

int symbols_add_global(const char *name)
{
    return add_global(name);
}

int symbols_add_external(const char *name)
{
    int i;

    for (i = 0; i < global_count; ++i)
        if (strcmp(globals[i].name, name) == 0)
            return globals[i].defined ? -1 : 0;
    if (global_count < MAX_SYMBOLS)
        globals[global_count++] = (struct global_symbol){ strdup(name), 0 };
    return 1;
}

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

int symbols_add_parameter(const char *name)
{
    int i;

    for (i = 0; i < parameter_count; ++i)
        if (strcmp(parameters[i], name) == 0)
            return 0;
    if (parameter_count < MAX_SYMBOLS)
        parameters[parameter_count++] = strdup(name);
    return 1;
}

int symbols_add_local(const char *name)
{
    int i;

    for (i = 0; i < local_count; ++i)
        if (strcmp(locals[i], name) == 0)
            return -1;
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

int symbols_is_global(const char *name)
{
    int i;

    for (i = 0; i < global_count; ++i)
        if (strcmp(globals[i].name, name) == 0)
            return 1;
    return 0;
}
