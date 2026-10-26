#ifndef CODEGEN_H
#define CODEGEN_H

void codegen_function_start(const char *name);
void codegen_function_end(void);
void codegen_push_immediate(int value);
void codegen_push_parameter(int offset);
void codegen_add(void);
void codegen_subtract(void);
void codegen_multiply(void);
void codegen_divide(void);
void codegen_modulo(void);
void codegen_return(void);

#endif