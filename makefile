CC     = gcc
CFLAGS = -fPIC -fprofile-arcs -ftest-coverage
RM     = rm -rf

.PHONY: help build coverage lcov-report gcovr-report deps clean lint

help: ## Makefile help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

main.o: main.c
	$(CC) $(CFLAGS) -c -Wall -Werror main.c

foo.o: foo.c
	$(CC) $(CFLAGS) -c -Wall -Werror foo.c

test.o: test.c
	$(CC) $(CFLAGS) -c -Wall -Werror test.c

build: main.o foo.o test.o ## Make build
	$(CC) $(CFLAGS) -o main main.o foo.o test.o

coverage: ## Run code coverage
	gcov main.c foo.c test.c

lcov-report: coverage ## Generate lcov report
	mkdir -p lcov-report
	lcov --capture --directory . --output-file lcov-report/coverage.info
	genhtml lcov-report/coverage.info --output-directory lcov-report

gcovr-report: coverage ## Generate gcovr report
	mkdir -p gcovr-report
	gcovr --root . --html --html-details --output gcovr-report/coverage.html

deps: ## Install dependencies (requires Debian/Ubuntu for apt-get)
	sudo apt-get install lcov clang-format
	pip install gcovr

clean: ## Clean all generate files
	$(RM) main *.out *.o *.so *.gcno *.gcda *.gcov lcov-report gcovr-report

lint: ## Lint code with clang-format
	clang-format -i --style=LLVM *.c *.h
