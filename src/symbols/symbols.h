#ifndef SYMBOLS_H
#define SYMBOLS_H

void symbols_begin_function(void);
void symbols_add_parameter(const char *name);
int symbols_parameter_offset(const char *name);

#endif
