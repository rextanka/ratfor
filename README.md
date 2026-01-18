# Ratfor Software Tools Framework

![K&P Software Tools CI](https://github.com/rextanka/ratfor/actions/workflows/main.yml/badge.svg)

This repository contains a modern implementation of the tools from Kernighan & Plauger's *Software Tools* (1976). Since the original code is in Ratfor (Rational Fortran), this project uses a custom Python transpiler to target modern C.

## Project Structure
- `src/`: Source code (`.r` files) organized by chapter.
- `scripts/`: Centralized logic for transpilation (`r2c.py`) and testing (`test_utils.sh`).
- `include/`: Shared C headers (`tools.h`) providing book-specific primitives.
- `bin/`: (Generated) Destination for all compiled executables (Git ignored).
- `build/`: (Generated) Staging area for intermediate `.c` files (Git ignored).

## Workflow
- **Build Everything**: Run `make` from the root.
- **Run Tests**: Run `make test` to build all tools and execute the full test suite.
- **Clean**: Run `make clean` to remove all generated binaries and intermediate files.

## Implementation Notes (The "Hacks")
The goal is a "90% automated" solution. To keep the translation simple, we employ specific strategies inherited from the original Fortran logic:

### The Array Hack
Ratfor/Fortran uses 1-based indexing, while C uses 0-based.
- **Strategy**: We do **not** shift indices (e.g., `i-1`). This causes bugs in complex logic.
- **Implementation**: We allocate C arrays with `size + 1`. If the book asks for `integer list(100)`, we allocate `int list[101]` in C and ignore index `0`.

### The Type Hack
K&P often store `EOF` (-1) in `character` variables. In C, a standard `char` may be unsigned, which causes infinite loops when comparing against `-1`.
- **Fix**: We typedef `character` to `int` in `tools.h` to ensure EOF is handled correctly.

### Adding New Exercises
1. Create a directory in `src/` (e.g., `src/ch2_filters`).
2. Add a `Makefile` that defines your `TOOLS` and includes `common.mk`:
   ```makefile
   TOP ?= $(shell cd ../.. && pwd)
   TOOLS = tool1 tool2
   include $(TOP)/common.mk
3. Add your .r files and a tests.sh script using the shared test_utils.sh.

### Development Workflow & Git Cheatsheet
To maintain a stable environment, follow this sequence when making changes or adding new tools.

1. Prepare Main Ensure your local main branch is clean and synchronized with the remote repository.

   ``` bash
   git checkout -- . (Discard experimental changes to tracked files)
   git clean -fd (Remove untracked files/directories)
   git pull origin main (Update to latest) 
   ``` 

2. Create a Feature Branch Use the format YYYYMMDD-HHMM for branch names.
Command: git checkout -b $(date +%Y%m%d-%H%M)
Example: 

    ``` bash
    git checkout -b 20260118-1301
    ``` 

3. Implement and Verify
Modify the Ratfor source (.r), the translator (r2c.py), or the header (tools.h). Before committing, verify the entire suite passes.
    ``` bash
   make clean
   make all
   make test
   ``` 
4. Push and Merge
Once tests are green, push to GitHub and use the web interface for the final merge.
   ``` bash
   git add .
   git commit -m "Your descriptive message"
   git push -u origin <branch-name>
   ``` 

Merge Strategy: Use Squash and Merge on GitHub to keep the main history clean.
## Resources
* [The Markdown Guide](https://www.markdownguide.org/)