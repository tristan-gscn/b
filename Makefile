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

$(TARGET): $(PARSER) $(SCANNER) src/codegen/codegen.o src/symbols/symbols.o
	$(CC) $(CFLAGS) -o $@ $(PARSER) $(SCANNER) src/codegen/codegen.o src/symbols/symbols.o

src/codegen/codegen.o: src/codegen/codegen.c src/codegen/codegen.h
	$(CC) $(CFLAGS) -Isrc/codegen -c $< -o $@

src/symbols/symbols.o: src/symbols/symbols.c src/symbols/symbols.h
	$(CC) $(CFLAGS) -Isrc/symbols -c $< -o $@

$(PARSER) $(PARSER_HEADER): parser.y
	$(YACC) -d parser.y

$(SCANNER): lexer.l $(PARSER_HEADER)
	$(LEX) -o $@ lexer.l

test: $(TARGET)
	@run_test() { \
		if [ -t 1 ]; then \
			escape=$$(printf '\033'); \
			blue="$${escape}[1;34m"; yellow="$${escape}[33m"; \
			green="$${escape}[32m"; red="$${escape}[31m"; reset="$${escape}[0m"; \
		else \
			blue=''; yellow=''; green=''; red=''; reset=''; \
		fi; \
		output=$$(mktemp); \
		printf '\n%s[%s]%s\n%s%s%s\n' "$$blue" "$$1" "$$reset" \
			"$$yellow" "$$2" "$$reset"; \
		if printf '%s\n' "$$2" | ./$(TARGET) > "$$output"; then \
			cat "$$output"; \
			printf '%sPASS%s\n' "$$green" "$$reset"; \
		else \
			cat "$$output"; \
			printf '%sFAIL%s\n' "$$red" "$$reset" >&2; \
			rm -f "$$output"; \
			return 1; \
		fi; \
		rm -f "$$output"; \
	}; \
	run_test 'constant return' \
		'main() { return 42; }'; \
	run_test 'arithmetic expressions' \
		'main() { return 7 + 4 * 8; }'; \
	run_test 'parameters and local variables' \
		'f(x) { auto y; y = x + 1; return y; }'; \
	run_test 'if and while' \
		'main() { auto x; while (x) { x = x - 1; } if (x == 0) return 1; else return 0; }'; \
	run_test 'indirect function call' \
		'f(x) { return x; } main() { return f(7); }'; \
	run_test 'vector indexing' \
		'main(p) { return p[2]; }'; \
	run_test 'vector assignment' \
		'main(p) { p[2] = 7; return p[2]; }'; \
	run_test 'prefix and postfix increments' \
		'main() { auto x; x = 1; return x++ + ++x; }'

clean:
	rm -f $(TARGET) $(PARSER) $(PARSER_HEADER) $(SCANNER) \
		src/codegen/codegen.o src/symbols/symbols.o
