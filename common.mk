# common.mk -- Shared build logic

.SUFFIXES:
.SUFFIXES: .r .c .o

CC = gcc
CFLAGS = -Wall -Wno-implicit-function-declaration -g -I$(TOP)/include
R2C = python3 $(TOP)/scripts/r2c.py

# Define staging areas
# notdir $(CURDIR) gets the name of the current chapter folder (e.g., ch1_getting_started)
BUILD_DIR = $(TOP)/build/$(notdir $(CURDIR))
BIN_DIR = $(TOP)/bin

# This tells Make that the translated C files are not just "temporary" and should be 
# kept for inspection or debugging.
.PRECIOUS: $(BUILD_DIR)/%.c

# Map tool names to the centralized bin directory
TARGETS = $(addprefix $(BIN_DIR)/, $(TOOLS))

all: $(TARGETS)

# --- RULE 1: TRANSPILE (.r -> build/*.c) ---
$(BUILD_DIR)/%.c: %.r $(TOP)/scripts/r2c.py
	@mkdir -p $(BUILD_DIR)
	@echo "--- Transpiling $< to $@ ---"
	$(R2C) $< > $@

# --- RULE 2: COMPILE (build/*.c -> bin/*) ---
$(BIN_DIR)/%: $(BUILD_DIR)/%.c
	@mkdir -p $(BIN_DIR)
	@echo "--- Compiling $< to $@ ---"
	$(CC) $(CFLAGS) -o $@ $<

clean:
	@echo "--- Cleaning $(notdir $(CURDIR)) artifacts ---"
	rm -rf $(BUILD_DIR)
	@for t in $(TOOLS); do rm -f $(BIN_DIR)/$$t; done