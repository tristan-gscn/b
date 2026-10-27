#include "labels.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LABELS 64

static char *labels[MAX_LABELS];
static char *gotos[MAX_LABELS];
static int label_count;
static int goto_count;

void labels_begin_function(void)
{
    label_count = 0;
    goto_count = 0;
}

static int find_label(const char *name)
{
    int i;

    for (i = 0; i < label_count; ++i)
        if (strcmp(labels[i], name) == 0)
            return 1;
    return 0;
}

int labels_define(const char *name)
{
    if (find_label(name)) {
        fprintf(stderr, "duplicate label: %s\n", name);
        return 0;
    }
    if (label_count >= MAX_LABELS)
        return 0;
    labels[label_count++] = strdup(name);
    return 1;
}

void labels_record_goto(const char *name)
{
    if (goto_count < MAX_LABELS)
        gotos[goto_count++] = strdup(name);
}

int labels_validate_gotos(void)
{
    int i;
    int valid = 1;

    for (i = 0; i < goto_count; ++i) {
        if (!find_label(gotos[i])) {
            fprintf(stderr, "unknown label: %s\n", gotos[i]);
            valid = 0;
        }
        free(gotos[i]);
    }
    for (i = 0; i < label_count; ++i)
        free(labels[i]);
    label_count = 0;
    goto_count = 0;
    return valid;
}
