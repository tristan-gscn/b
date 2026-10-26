#ifndef CODEGEN_H
#define CODEGEN_H

void codegen_function_start(const char *name);
void codegen_function_end(void);
void codegen_push_immediate(int value);
void codegen_push_parameter(int offset);
void codegen_push_local(int offset);
void codegen_push_parameter_address(int offset);
void codegen_push_local_address(int offset);
void codegen_push_name(const char *name);
void codegen_push_name_address(const char *name);
void codegen_store_local(int offset);
void codegen_load_indirect(void);
void codegen_store_indirect(void);
void codegen_index(void);
void codegen_index_address(void);
void codegen_increment(int prefix, int delta);
void codegen_allocate_local(void);
void codegen_add(void);
void codegen_subtract(void);
void codegen_multiply(void);
void codegen_divide(void);
void codegen_modulo(void);
void codegen_return(void);
void codegen_call(int argument_count);
void codegen_compare_equal(void);
void codegen_compare_not_equal(void);
void codegen_compare_less(void);
void codegen_compare_less_equal(void);
void codegen_compare_greater(void);
void codegen_compare_greater_equal(void);
void codegen_logical_not(void);
void codegen_negate(void);
int codegen_new_label(void);
void codegen_emit_label(int label);
void codegen_jump(int label);
void codegen_jump_zero(int label);
void codegen_if_start(int else_label);
void codegen_if_else(void);
void codegen_if_no_else(void);
void codegen_if_end(void);
void codegen_while_condition(int end_label);
void codegen_while_end(int start_label, int end_label);

#endif