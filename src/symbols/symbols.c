#include "internal.h"

const char *symbols_parameters[MAX_SYMBOLS];
const char *symbols_locals[MAX_SYMBOLS];
struct global_symbol symbols_globals[MAX_SYMBOLS];
int symbols_parameter_count;
int symbols_local_count;
int symbols_global_count;
