#ifndef SYMBOLS_H
#define SYMBOLS_H

void symbols_begin_function(void);
int symbols_add_global(const char *name);
int symbols_add_external(const char *name);
int symbols_add_parameter(const char *name);
int symbols_add_local(const char *name);
int symbols_parameter_offset(const char *name);
int symbols_local_offset(const char *name);
int symbols_is_global(const char *name);

#endif
