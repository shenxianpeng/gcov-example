CC     = gcc
CFLAGS = -fPIC -fprofile-arcs -ftest-coverage
RM     = rm -rf

.PHONY: help build coverage lcov-report gcovr-report deps clean lint \
        build-config1 build-config2 coverage-merged coverage-filter

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

build-config1: ## Build with TRIGGER_ON macro (for multi-config coverage demo)
	$(CC) $(CFLAGS) -DTRIGGER_ON -c -Wall -Werror trigger.c -o trigger_on.o
	$(CC) $(CFLAGS) -c -Wall -Werror main.c foo.c test.c
	$(CC) $(CFLAGS) -o main_config1 main.o foo.o test.o trigger_on.o

build-config2: ## Build with TRIGGER_OFF macro (for multi-config coverage demo)
	$(CC) $(CFLAGS) -c -Wall -Werror trigger.c -o trigger_off.o
	$(CC) $(CFLAGS) -c -Wall -Werror main.c foo.c test.c
	$(CC) $(CFLAGS) -o main_config2 main.o foo.o test.o trigger_off.o

coverage-merged: build-config1 build-config2 ## Merge coverage from TRIGGER_ON and TRIGGER_OFF configurations
	./main_config1
	lcov --capture --directory . --output-file config1.info
	$(RM) *.gcda
	./main_config2
	lcov --capture --directory . --output-file config2.info
	lcov -a config1.info -a config2.info -o merged.info
	mkdir -p merged-report
	genhtml merged.info --output-directory merged-report
	@echo "Merged coverage report: merged-report/index.html"

coverage-filter: lcov-report ## Show coverage for trigger.c only (file-specific filtering)
	lcov --extract lcov-report/coverage.info "$(CURDIR)/trigger.c" -o trigger_only.info
	mkdir -p trigger-report
	genhtml trigger_only.info --output-directory trigger-report
	@echo "Filtered coverage report: trigger-report/index.html"

clean: ## Clean all generate files
	$(RM) main main_config1 main_config2 *.out *.o *.so *.gcno *.gcda *.gcov \
	      lcov-report gcovr-report merged-report trigger-report \
	      config1.info config2.info merged.info trigger_only.info

lint: ## Lint code with clang-format
	clang-format -i --style=LLVM *.c *.h
