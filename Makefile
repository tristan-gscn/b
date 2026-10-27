CC = cc
CFLAGS = -Wall -Wextra
YACC = yacc
LEX = lex

TARGET = B
PARSER = y.tab.c
PARSER_HEADER = y.tab.h
SCANNER = lex.yy.c

.PHONY: all clean test assembly-test runtime-test

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
	run_error_test() { \
		printf '\n[%s]\n%s\n' "$$1" "$$2"; \
		if printf '%s\n' "$$2" | ./$(TARGET) >/dev/null 2>&1; then \
			printf 'FAIL\n' >&2; \
			return 1; \
		else \
			printf 'PASS\n'; \
		fi; \
	}; \
	run_test 'constant return' \
		'main() { return 42; }'; \
	run_test 'implicit return value' \
		'main() { auto x; x = 1; }'; \
	run_test 'auto initializers' \
		'main() { auto x 42, y '\''A'\'', message "ok"; return x + y; }'; \
	run_test 'auto name initializer' \
		'main() { auto x 42, y x; return y; }'; \
	run_test 'partial explicit return' \
		'main(x) { if (x) return 1; }'; \
	run_test 'goto and label' \
		'main() { goto done; return 0; done: return 1; }'; \
	run_test 'forward label validation' \
		'main() { goto later; later: return 1; }'; \
	run_test 'switch and case' \
		'main(x) { switch x { case 1: return 7; case 2: return 8; } }'; \
	run_test 'switch default' \
		'main(x) { switch x { case 1: return 7; default: return 9; } }'; \
	run_test 'character and string literals' \
		'main() { auto message; message = "ok"; return '\''A'\''; }'; \
	run_test 'arithmetic expressions' \
		'main() { return 7 + 4 * 8; }'; \
	run_test 'bitwise and shift expressions' \
		'main() { return (1 | 2) ^ (8 >> 1) & (1 << 2); }'; \
	run_test 'conditional expression' \
		'main(x) { return x ? 7 : 9; }'; \
	run_test 'parameters and local variables' \
		'f(x) { auto y; y = x + 1; return y; }'; \
	run_test 'if and while' \
		'main() { auto x; while (x) { x = x - 1; } if (x == 0) return 1; else return 0; }'; \
	run_test 'indirect function call' \
		'f(x) { return x; } main() { return f(7); }'; \
	run_test 'external function declaration' \
		'extrn f; main() { return f(7); }'; \
	run_test 'vector indexing' \
		'main(p) { return p[2]; }'; \
	run_test 'vector assignment' \
		'main(p) { p[2] = 7; return p[2]; }'; \
	run_test 'prefix and postfix increments' \
		'main() { auto x; x = 1; return x++ + ++x; }'; \
	run_test 'vector postfix increment' \
		'main(p) { p[2]++; return p[2]; }'; \
	run_test 'indirect postfix increment' \
		'main(p) { (*p)++; return *p; }'; \
	run_test 'vector prefix increment' \
		'main(p) { ++p[2]; return p[2]; }'; \
	run_test 'nested switch' \
		'main(x) { switch x { case 1: switch x { case 1: return 7; } default: return 8; } }'; \
	run_test 'indirect prefix increment' \
		'main(p) { ++(*p); return *p; }'; \
	run_error_test 'duplicate parameters' \
		'main(x, x) { return x; }'; \
	run_error_test 'duplicate locals' \
		'main() { auto x, x; return x; }'; \
	run_error_test 'unknown label' \
		'main() { goto missing; }'; \
	$(MAKE) --no-print-directory assembly-test; \
	$(MAKE) --no-print-directory runtime-test

assembly-test: $(TARGET)
	@set -e; \
	compiler=$${B_ASM_CC:-clang}; \
	if ! command -v "$$compiler" >/dev/null 2>&1 || \
		! "$$compiler" -target i386-unknown-linux-gnu -x c -E - </dev/null \
			>/dev/null 2>&1; then \
		printf '\n[assembly tests]\nSKIP (clang i386 cross-target unavailable)\n'; \
		exit 0; \
	fi; \
	run_assembly_test() { \
		source=$$(mktemp /tmp/b-asm-source.XXXXXX); \
		object=$$(mktemp /tmp/b-asm-object.XXXXXX); \
		printf '\n[%s]\n%s\n' "$$1" "$$2"; \
		if ! printf '%s\n' "$$2" | ./$(TARGET) > "$$source" || \
			! "$$compiler" -target i386-unknown-linux-gnu -x assembler -c "$$source" \
				-o "$$object"; then \
			printf 'FAIL\n' >&2; \
			rm -f "$$source" "$$object"; \
			return 1; \
		fi; \
		rm -f "$$source" "$$object"; \
		printf 'PASS\n'; \
	}; \
	run_assembly_test 'assembly arithmetic' \
		'main() { return 7 + 4 * 8; }'; \
	run_assembly_test 'assembly control flow' \
		'main(x) { switch x { case 1: return 7; default: return 9; } }'; \
	run_assembly_test 'assembly strings' \
		'main() { return "ok"; }'

runtime-test: $(TARGET) brt0.o
	@set -e; \
	if [ "$$(uname -s)" != Linux ] || ! file brt0.o | grep -q 'ELF 32-bit.*Intel 80386'; then \
		printf '\n[runtime tests]\nSKIP (requires Linux i386 tools for brt0.o)\n'; \
		exit 0; \
	fi; \
	assembler=$${B_AS:-as}; linker=$${B_LD:-ld}; \
	if ! command -v "$$assembler" >/dev/null 2>&1 || \
		! command -v "$$linker" >/dev/null 2>&1; then \
		printf '\n[runtime tests]\nSKIP (as/ld not found)\n'; \
		exit 0; \
	fi; \
	run_runtime_test() { \
		source=$$(mktemp /tmp/b-runtime-source.XXXXXX); \
		object=$$(mktemp /tmp/b-runtime-object.XXXXXX); \
		binary=$$(mktemp); \
		printf '\n[%s]\n%s\n' "$$1" "$$2"; \
		if ! printf '%s\n' "$$2" | ./$(TARGET) > "$$source" || \
			! "$$assembler" --32 -o "$$object" "$$source" || \
			! "$$linker" -m elf_i386 -o "$$binary" "$$object" brt0.o; then \
			printf 'FAIL\n' >&2; \
			rm -f "$$source" "$$object" "$$binary"; \
			return 1; \
		fi; \
		set +e; "$$binary"; actual=$$?; set -e; \
		rm -f "$$source" "$$object" "$$binary"; \
		if [ "$$actual" -ne "$$3" ]; then \
			printf 'FAIL (expected %s, got %s)\n' "$$3" "$$actual" >&2; \
			return 1; \
		fi; \
		printf 'PASS\n'; \
	}; \
	run_runtime_test 'runtime constant' \
		'main() { return 42; }' 42; \
	run_runtime_test 'runtime locals and arithmetic' \
		'main() { auto x 6; x = x * 7; return x; }' 42; \
	run_runtime_test 'runtime conditional return' \
		'main() { auto x 1; if (x) return 7; return 0; }' 7; \
	run_runtime_test 'runtime function call' \
		'f(x) { return x + 1; } main() { return f(41); }' 42; \
	run_runtime_test 'runtime switch' \
		'main() { auto x 2; switch x { case 1: return 7; case 2: return 42; default: return 9; } }' 42

clean:
	rm -f $(TARGET) $(PARSER) $(PARSER_HEADER) $(SCANNER) \
		src/codegen/codegen.o src/symbols/symbols.o
