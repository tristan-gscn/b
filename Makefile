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

CODEGEN_OBJECTS = src/codegen/codegen.o src/codegen/output.o \
	src/codegen/function.o src/codegen/memory.o \
	src/codegen/arithmetic.o src/codegen/logic.o \
	src/codegen/control.o src/codegen/strings.o

$(TARGET): $(PARSER) $(SCANNER) $(CODEGEN_OBJECTS) \
	src/symbols/symbols.o src/symbols/globals.o \
	src/symbols/scope.o src/semantic/labels.o
	$(CC) $(CFLAGS) -o $@ $(PARSER) $(SCANNER) \
		$(CODEGEN_OBJECTS) \
		src/symbols/symbols.o src/symbols/globals.o \
		src/symbols/scope.o src/semantic/labels.o

src/codegen/codegen.o: src/codegen/codegen.c src/codegen/codegen.h
	$(CC) $(CFLAGS) -Isrc/codegen -c $< -o $@

src/codegen/%.o: src/codegen/%.c src/codegen/codegen.h src/codegen/internal.h
	$(CC) $(CFLAGS) -Isrc/codegen -c $< -o $@

src/codegen/strings.o: src/codegen/strings.c src/codegen/codegen.h
	$(CC) $(CFLAGS) -Isrc/codegen -c $< -o $@

src/symbols/symbols.o: src/symbols/symbols.c src/symbols/symbols.h
	$(CC) $(CFLAGS) -Isrc/symbols -c $< -o $@

src/symbols/%.o: src/symbols/%.c src/symbols/symbols.h \
	src/symbols/internal.h
	$(CC) $(CFLAGS) -Isrc/symbols -c $< -o $@

src/semantic/labels.o: src/semantic/labels.c src/semantic/labels.h
	$(CC) $(CFLAGS) -Isrc/semantic -c $< -o $@

$(PARSER) $(PARSER_HEADER): parser.y
	$(YACC) -d parser.y

$(SCANNER): lexer.l $(PARSER_HEADER)
	$(LEX) -o $@ lexer.l

test: $(TARGET)
	@tests/run-tests.sh
	@$(MAKE) --no-print-directory assembly-test
	@$(MAKE) --no-print-directory runtime-test

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
		$(CODEGEN_OBJECTS) \
		src/symbols/symbols.o src/symbols/globals.o \
		src/symbols/scope.o src/semantic/labels.o
