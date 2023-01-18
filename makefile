CC	= gcc
CFLAG = -fPIC -fprofile-arcs -ftest-coverage
RM	= rm -rf

help: ## Makefile help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

main.o: main.c
	$(CC) $(CFLAG) -c -Wall -Werror main.c

foo.o: foo.c
	$(CC) $(CFLAG) -c -Wall -Werror foo.c

test.o: test.c
	$(CC) $(CFLAG) -c -Wall -Werror test.c

build: main.o foo.o test.o ## Make build
	$(CC) $(CFLAG) -c -Wall -Werror main.c
	$(CC) $(CFLAG) -o main main.o foo.o test.o

coverage: ## Run code coverage
	gcov main.c foo.c test.c

lcov-report: coverage ## Generate lcov report
	mkdir lcov-report
	lcov --capture --directory . --output-file lcov-report/coverage.info
	genhtml lcov-report/coverage.info --output-directory lcov-report

gcovr-report: coverage ## Generate gcovr report
	mkdir gcovr-report
	gcovr --root . --html --html-details --output gcovr-report/coverage.html

deps: ## Install dependencies
	sudo apt-get install lcov clang-format
	pip install gcovr

clean: ## Clean all generate files
	$(RM) main *.out *.o *.so *.gcno *.gcda *.gcov lcov-report gcovr-report

lint: ## Lint code with clang-format
	clang-format -i --style=LLVM *.c *.h
