#ifndef LABELS_H
#define LABELS_H

void labels_begin_function(void);
int labels_define(const char *name);
void labels_record_goto(const char *name);
int labels_validate_gotos(void);

#endif
