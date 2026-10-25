%{
#include "parser.tab.h"
#include <stdlib.h>

int yylval;
%}

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

"/*"([^*]|\*+[^*/])*\*+"/" {
    /* Ignore the comment */
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

%%