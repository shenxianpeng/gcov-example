CC     = gcc
CFLAGS = -fPIC -fprofile-arcs -ftest-coverage
RM     = rm -rf

SRCS = main.c foo.c test.c trigger.c
OBJS = $(SRCS:.c=.o)

# Multi-configuration demo: every configuration is built into its own
# directory so that each .gcno/.gcda pair stays together. GCC stamps every
# .gcno with the compile time, so a .gcda written by a binary that was linked
# against an older .o does not match a freshly rebuilt .gcno in the same
# directory ("stamp mismatch with notes file").
BUILD_DIR   = build
CONFIG1_DIR = $(BUILD_DIR)/config1
CONFIG2_DIR = $(BUILD_DIR)/config2

.PHONY: help build coverage lcov-report gcovr-report deps clean lint \
        build-config1 build-config2 coverage-merged coverage-filter

help: ## Makefile help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

%.o: %.c
	$(CC) $(CFLAGS) -c -Wall -Werror $< -o $@

build: $(OBJS) ## Make build
	$(CC) $(CFLAGS) -o main $(OBJS)

coverage: ## Run code coverage
	gcov $(SRCS)

# --no-recursion / --exclude-directories keep the per-configuration data
# under build/ out of the single-configuration reports.
lcov-report: coverage ## Generate lcov report
	mkdir -p lcov-report
	lcov --capture --directory . --no-recursion --output-file lcov-report/coverage.info
	genhtml lcov-report/coverage.info --output-directory lcov-report

gcovr-report: coverage ## Generate gcovr report
	mkdir -p gcovr-report
	gcovr --root . --exclude-directories '$(BUILD_DIR)' --html --html-details --output gcovr-report/coverage.html

deps: ## Install dependencies (requires Debian/Ubuntu for apt-get)
	sudo apt-get install -y lcov clang-format pipx
	pipx install gcovr
	@echo "If 'gcovr' is not found, run 'pipx ensurepath' and open a new shell."

$(CONFIG1_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -DTRIGGER_ON -c -Wall -Werror $< -o $@

$(CONFIG2_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -Wall -Werror $< -o $@

build-config1: $(addprefix $(CONFIG1_DIR)/,$(OBJS)) ## Build with -DTRIGGER_ON into build/config1 (multi-config demo)
	$(CC) $(CFLAGS) -o $(CONFIG1_DIR)/main $^

build-config2: $(addprefix $(CONFIG2_DIR)/,$(OBJS)) ## Build without TRIGGER_ON into build/config2 (multi-config demo)
	$(CC) $(CFLAGS) -o $(CONFIG2_DIR)/main $^

coverage-merged: build-config1 build-config2 ## Merge coverage of both configurations into one report
	./$(CONFIG1_DIR)/main
	./$(CONFIG2_DIR)/main
	lcov --capture --directory $(CONFIG1_DIR) --output-file $(BUILD_DIR)/config1.info
	lcov --capture --directory $(CONFIG2_DIR) --output-file $(BUILD_DIR)/config2.info
	lcov --add-tracefile $(BUILD_DIR)/config1.info --add-tracefile $(BUILD_DIR)/config2.info --output-file $(BUILD_DIR)/merged.info
	mkdir -p merged-report
	genhtml $(BUILD_DIR)/merged.info --output-directory merged-report
	@echo "Merged coverage report: merged-report/index.html"

coverage-filter: lcov-report ## Show coverage for trigger.c only (file-specific filtering)
	mkdir -p trigger-report
	lcov --extract lcov-report/coverage.info "$(CURDIR)/trigger.c" --output-file trigger-report/trigger_only.info
	genhtml trigger-report/trigger_only.info --output-directory trigger-report
	@echo "Filtered coverage report: trigger-report/index.html"

clean: ## Clean all generate files
	$(RM) main *.out *.o *.so *.gcno *.gcda *.gcov $(BUILD_DIR) \
	      lcov-report gcovr-report merged-report trigger-report

lint: ## Lint code with clang-format
	clang-format -i --style=LLVM *.c *.h
