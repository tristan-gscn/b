CC = cc
CFLAGS = -Wall -Wextra
YACC = yacc
LEX = lex

TARGET = B
PARSER = y.tab.c
PARSER_HEADER = y.tab.h
SCANNER = lex.yy.c

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(PARSER) $(SCANNER)
	$(CC) $(CFLAGS) -o $@ $(PARSER) $(SCANNER)

$(PARSER) $(PARSER_HEADER): parser.y
	$(YACC) -d parser.y

$(SCANNER): lexer.l $(PARSER_HEADER)
	$(LEX) -o $@ lexer.l

clean:
	rm -f $(TARGET) $(PARSER) $(PARSER_HEADER) $(SCANNER)
