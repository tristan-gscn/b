%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

int yylval;
%}

%option noyywrap

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

[a-zA-Z][a-zA-Z0-9]* {
    return NAME;
}

[ \t\n\r]+ {
    /* Ignore whitespace */
}
"/*"([^*]|\*+[^*/])*\*+"/" {
    /* Ignore comment */
}

[1-9][0-9]* {
    yylval = atoi(yytext);
    return NUMBER;
}
0[0-9]* {
    yylval = strtol(yytext, NULL, 8);
    return NUMBER;
}
\'([^'\\]|\\.)*\' {
    yylval = yytext[1];
    return CONSTANT;
}
\"([^\"\\]|\\.)*\" {
    yylval = (int)strdup(yytext);
    return STRING;
}

"=="    { return EQ; }
"!="    { return NE; }
"<="    { return LE; }
">="      { return GE; }
"<<"    { return LSHIFT; }
">>"    { return RSHIFT; }
"++"    { return INC; }
"--"    { return DEC; }
[-+*/%<>=&|^!()\[\]{};:,?] {
    return yytext[0];
}

%%

int main(void) {
    yylex();
    return 0;
}