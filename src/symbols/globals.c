#include "symbols.h"
#include "internal.h"
#include <stdlib.h>
#include <string.h>

int symbols_add_global(const char *name)
{
    int i;

    for (i = 0; i < symbols_global_count; ++i) {
        if (strcmp(symbols_globals[i].name, name) == 0) {
            if (!symbols_globals[i].defined) {
                symbols_globals[i].defined = 1;
                return 1;
            }
            return 0;
        }
    }
    if (symbols_global_count >= MAX_SYMBOLS)
        return 0;
    symbols_globals[symbols_global_count++] =
        (struct global_symbol){ strdup(name), 1 };
    return 1;
}

int symbols_add_external(const char *name)
{
    int i;

    for (i = 0; i < symbols_global_count; ++i)
        if (strcmp(symbols_globals[i].name, name) == 0)
            return symbols_globals[i].defined ? -1 : 0;
    if (symbols_global_count >= MAX_SYMBOLS)
        return 0;
    symbols_globals[symbols_global_count++] =
        (struct global_symbol){ strdup(name), 0 };
    return 1;
}

int symbols_is_global(const char *name)
{
    int i;

    for (i = 0; i < symbols_global_count; ++i)
        if (strcmp(symbols_globals[i].name, name) == 0)
            return 1;
    return 0;
}
