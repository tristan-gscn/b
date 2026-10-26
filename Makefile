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

$(TARGET): $(PARSER) $(SCANNER) src/codegen/codegen.o
	$(CC) $(CFLAGS) -o $@ $(PARSER) $(SCANNER) src/codegen/codegen.o

src/codegen/codegen.o: src/codegen/codegen.c src/codegen/codegen.h
	$(CC) $(CFLAGS) -Isrc/codegen -c $< -o $@

$(PARSER) $(PARSER_HEADER): parser.y
	$(YACC) -d parser.y

$(SCANNER): lexer.l $(PARSER_HEADER)
	$(LEX) -o $@ lexer.l

test: $(TARGET)
	printf 'main() { return 42; }' | ./$(TARGET)
	printf 'main() { return 7; }' | ./$(TARGET)
	printf 'main() { return 7+4*8; }' | ./$(TARGET)

clean:
	rm -f $(TARGET) $(PARSER) $(PARSER_HEADER) $(SCANNER) src/codegen/codegen.o
