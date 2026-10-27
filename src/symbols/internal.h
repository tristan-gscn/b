#ifndef SYMBOLS_INTERNAL_H
#define SYMBOLS_INTERNAL_H

#define MAX_SYMBOLS 64

struct global_symbol {
    char *name;
    int defined;
};

extern const char *symbols_parameters[MAX_SYMBOLS];
extern const char *symbols_locals[MAX_SYMBOLS];
extern struct global_symbol symbols_globals[MAX_SYMBOLS];
extern int symbols_parameter_count;
extern int symbols_local_count;
extern int symbols_global_count;

#endif
