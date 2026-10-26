%{
#include "y.tab.h"
#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

static int decode_escape(const char **input)
{
    const char *p = *input;
    int value;

    if (*p != '\\') {
        value = (unsigned char)*p++;
        *input = p;
        return value;
    }
    ++p;
    switch (*p) {
    case 'a': value = '\a'; ++p; break;
    case 'b': value = '\b'; ++p; break;
    case 'f': value = '\f'; ++p; break;
    case 'n': value = '\n'; ++p; break;
    case 'r': value = '\r'; ++p; break;
    case 't': value = '\t'; ++p; break;
    case 'v': value = '\v'; ++p; break;
    case '0': value = '\0'; ++p; break;
    case '\\': case '\'': case '"': value = (unsigned char)*p++; break;
    default: value = (unsigned char)*p++; break;
    }
    *input = p;
    return value;
}

static int character_value(const char *text)
{
    const char *p = text + 1;
    unsigned long value = 0;
    int count = 0;

    while (*p && *p != '\'' && count < 2) {
        value = (value << 8) | (unsigned char)decode_escape(&p);
        ++count;
    }
    return (int)value;
}

static char *string_value(const char *text)
{
    size_t length = strlen(text);
    char *result = malloc(length);
    const char *p = text + 1;
    char *out = result;

    if (!result)
        return NULL;
    while (*p && *p != '"')
        *out++ = (char)decode_escape(&p);
    *out = '\0';
    return result;
}
%}

%option noyywrap noinput nounput

%%
"auto"      { return AUTO; }
"extrn"     { return EXTRN; }
"case"      { return CASE; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"switch"    { return SWITCH; }
"goto"      { return GOTO; }
"return"    { return RETURN; }

[A-Za-z_][A-Za-z0-9_]* {
    yylval.sval = strdup(yytext);
    return NAME;
}

[ \t\n\r]+                    { }
"/*"([^*]|\*+[^*/])*\*+"/"  { }

[0-9]+ {
    errno = 0;
    yylval.ival = (int)strtol(yytext, NULL, 10);
    if (errno == ERANGE || yylval.ival < 0)
        yylval.ival = INT_MAX;
    return NUMBER;
}

\'([^\\'\n]|\\.)+\' {
    yylval.ival = character_value(yytext);
    return CONSTANT;
}
\"([^\\\"\n]|\\.)*\" {
    yylval.sval = string_value(yytext);
    return STRING;
}

"=="    { return EQ; }
"!="    { return NE; }
"<="    { return LE; }
">="    { return GE; }
"<<"    { return LSHIFT; }
">>"    { return RSHIFT; }
"++"    { return INC; }
"--"    { return DEC; }
[-+*/%<>=&|^!()[\]{};:,?] { return yytext[0]; }
.                            { return yytext[0]; }
%%
