# Top-Level Makefile to build all chapters

# 1. Export the absolute path to this directory as TOP
export TOP := $(shell pwd)

# 2. Find all directories inside src/
SUBDIRS := $(wildcard src/*)

.PHONY: all clean list test

all:
	@echo ">>> Building all chapters..."
	@for dir in $(SUBDIRS); do \
		if [ -f $$dir/Makefile ]; then \
			echo "--- Entering $$dir ---"; \
			$(MAKE) -C $$dir || exit 1; \
		else \
			echo "--- Skipping $$dir (No Makefile found) ---"; \
		fi \
	done
	@echo ">>> Build complete."

# New target to run the centralized test suite
test: all
	@chmod +x $(TOP)/scripts/run_all_tests.sh
	@$(TOP)/scripts/run_all_tests.sh

list:
	@echo "Detected Chapter Directories:"
	@for dir in $(SUBDIRS); do \
		echo "  $$dir"; \
	done

clean:
	@echo ">>> Cleaning all chapters..."
	@for dir in $(SUBDIRS); do \
		if [ -f $$dir/Makefile ]; then \
			echo "--- Cleaning $$dir ---"; \
			$(MAKE) -C $$dir clean; \
		fi \
	done
	# Also remove the centralized bin and build directories
	rm -rf $(TOP)/bin $(TOP)/build
	@echo ">>> Clean complete."