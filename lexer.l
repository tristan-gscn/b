%{
#include "y.tab.h"
#include <stdlib.h>
#include <string.h>
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

[1-9][0-9]* {
    yylval.ival = atoi(yytext);
    return NUMBER;
}
0[0-9]* {
    yylval.ival = strtol(yytext, NULL, 8);
    return NUMBER;
}

\'([^'\\]|\\.)*\' {
    yylval.ival = yytext[1];
    return CONSTANT;
}
\"([^\"\\]|\\.)*\" {
    yylval.sval = strdup(yytext);
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
