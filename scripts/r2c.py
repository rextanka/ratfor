import sys
import re
import traceback

# --- CONFIGURATION ---
PRIMITIVES = {
    "getc", "putc", "open", "close", "create", "delete", 
    "error", "usage", "seek", "mark", "ungetc", "putdec", 
    "putstr", "length", "mod", "printf", "fprintf", "exit"
}

# --- HELPERS ---

def split_comment(line):
    """Splits line into (code, comment). Handles '#' comments."""
    if '#' in line:
        parts = line.split('#', 1)
        return parts[0].rstrip(), "//" + parts[1].rstrip()
    return line.rstrip(), ""

def clean_line_for_parsing(line):
    """Applies global fixes like typo correction."""
    return line.replace("integed ", "integer ")

# --- PASS 0: PROTOTYPE SCANNER ---

def scan_prototypes(lines):
    """
    Scans the file to generate CORRECT C prototypes (e.g., 'int foo(int a[]);').
    It looks inside function bodies to see if arguments are declared as arrays.
    """
    prototypes = []
    
    current_func_name = None
    current_ret_type = None
    current_args = []     # list of arg names ["col", "tabs"]
    current_arg_is_array = {} # "tabs" -> True
    
    for line in lines:
        code, _ = split_comment(line)
        code = clean_line_for_parsing(code)
        
        # 1. Detect Header
        # Regex matches: "integer function name(args)" or "subroutine name(args)"
        m = re.match(r'^\s*(?:(integer|character)\s+)?(function|subroutine)\s+(\w+)(?:\((.*)\))?', code, re.IGNORECASE)
        if m:
            is_sub = (m.group(2).lower() == 'subroutine')
            current_ret_type = "void" if is_sub else "int"
            current_func_name = m.group(3)
            
            raw_args = m.group(4)
            if raw_args:
                current_args = [x.strip() for x in raw_args.split(',') if x.strip()]
            else:
                current_args = []
            
            current_arg_is_array = {arg: False for arg in current_args}
            continue

        # 2. Detect Declarations (to refine arg types)
        if current_func_name:
            if re.match(r'^\s*(integer|character)', code, re.IGNORECASE):
                content = re.sub(r'^\s*(integer|character)\s*', '', code, flags=re.IGNORECASE)
                # Find vars "x" or "x(100)"
                defs = re.finditer(r'(\w+)(?:\(([^)]+)\))?', content)
                for d in defs:
                    name = d.group(1)
                    size = d.group(2)
                    # If this declared var is an argument, and has a size, it's an array arg
                    if name in current_arg_is_array and size is not None:
                        current_arg_is_array[name] = True
        
        # 3. Detect End (Flush prototype)
        if re.match(r'^\s*end\s*$', code, re.IGNORECASE):
            if current_func_name:
                # Build C-style arg list: "int col, int tabs[]"
                c_args = []
                for arg in current_args:
                    if current_arg_is_array.get(arg):
                        c_args.append(f"int {arg}[]")
                    else:
                        c_args.append(f"int {arg}")
                
                arg_str = ", ".join(c_args)
                prototypes.append(f"{current_ret_type} {current_func_name}({arg_str});")
                
                current_func_name = None
                
    return prototypes

# --- PASS 1: BLOCK PARSER ---

def parse_ratfor_block(lines, global_funcs):
    # 1. SCANNING PHASE: Identify variables & Header
    vars_info = {} 
    args_list = []
    header_line = ""
    is_main = False
    
   # Find Header
    for line in lines:
        code, _ = split_comment(line)
        code = clean_line_for_parsing(code)
        # Add 'driver' to the regex for headers
        if re.match(r'^\s*(subroutine|function|integer\s+function|character\s+function|driver)', code, re.IGNORECASE):
            header_line = code
            # If it's the driver, treat it as main
            if "driver" in code.lower():
                is_main = True
                header_line = "int main(int argc, char *argv[])"
                break
            m = re.search(r'\((.*)\)', code)
            if m:
                args_list = [x.strip() for x in m.group(1).split(',') if x.strip()]
            break

    # If no header found, this is Main
    if not header_line:
        is_main = True
        header_line = "int main(int argc, char *argv[])"

    # Scan for declarations in this block
    for line in lines:
        code, _ = split_comment(line)
        code = clean_line_for_parsing(code)
        
        if re.match(r'^\s*(integer|character)', code, re.IGNORECASE):
            content = re.sub(r'^\s*(integer|character)\s*', '', code, flags=re.IGNORECASE)
            defs = re.finditer(r'(\w+)(?:\(([^)]+)\))?', content)
            for d in defs:
                name = d.group(1)
                size = d.group(2)
                vars_info[name] = {"is_array": (size is not None), "size": size}

    # 2. GENERATION PHASE
    output = []
    
    func_name = ""
    ret_type = "void" # Default
    
    if is_main:
        output.append("int main(int argc, char *argv[]) {")
        func_name = "main"
        ret_type = "int"
    else:
        if "function" in header_line.lower(): ret_type = "int"
        
        m = re.search(r'(?:function|subroutine)\s+(\w+)', header_line, re.IGNORECASE)
        if m: func_name = m.group(1)

        # Build Arguments
        typed_args = []
        for arg in args_list:
            info = vars_info.get(arg, {"is_array": False})
            if info["is_array"]:
                typed_args.append(f"int {arg}[]")
            else:
                typed_args.append(f"int {arg}")
        
        output.append(f"{ret_type} {func_name}({', '.join(typed_args)}) {{")

# Generate Body
    for line in lines:
        code, comment = split_comment(line)
        if not code:
            if comment: output.append(comment)
            continue

        # Skip the 'driver' line so it doesn't end up as "driver;" in C
        if "driver" in code.lower() and "(" not in code:
            continue

        # Skip the header line in output
        if code.strip() == header_line.strip(): continue
        if func_name and func_name in code and "(" in code and ("function" in code or "subroutine" in code): continue

        # --- DECLARATIONS ---
        code = clean_line_for_parsing(code)
        if re.match(r'^\s*(integer|character)', code, re.IGNORECASE):
            out_decl = []
            content = re.sub(r'^\s*(integer|character)\s*', '', code, flags=re.IGNORECASE)
            defs = re.finditer(r'(\w+)(?:\(([^)]+)\))?', content)
            
            for d in defs:
                name = d.group(1)
                size = d.group(2)
                
                # Filtering Rules
                if name in args_list: continue # Already in args
                if name in PRIMITIVES: continue # Built-in
                if name == func_name: continue # Return variable
                # Skip global functions to avoid shadowing, BUT only if they aren't arrays
                # (Ratfor sometimes uses array name same as function? Unlikely. Safety check:)
                if name in global_funcs and name != func_name and not size: continue

                if size:
                    out_decl.append(f"*{name}" if size == "*" else f"{name}[{size} + 1]")
                else:
                    out_decl.append(name)
            
            if out_decl:
                output.append(f"int {', '.join(out_decl)}; {comment}")
            elif comment:
                output.append(comment)
            continue

        if re.match(r'^\s*end\s*$', code, re.IGNORECASE):
            output.append("}")
            continue

        # --- LOGIC TRANSLATION ---

        # Macros
        if code.startswith("define"):
            m = re.search(r'define\s*\(([^,]+),([^\)]+)\)', code, re.IGNORECASE)
            if m: output.append(f"#define {m.group(1).strip()} {m.group(2).strip()}")
            continue

        # Standard replacements
        code = code.replace("call ", "")
        code = re.sub(r'\bstop\b', 'exit(0)', code)

        # Return Values (Assignment to function name -> return)
        if not is_main and func_name:
            if re.match(rf'^\s*{func_name}\s*=', code):
                 code = re.sub(rf'\b{func_name}\s*=', 'return ', code)
        
        # Bare 'return' in int function -> 'return 0;'
        if re.match(r'^\s*return\s*;?$', code):
            if ret_type == "int":
                code = "return 0" 

        # Loops
        if "repeat {" in code or code.strip() == "repeat":
            code = code.replace("repeat", "do")
        
        m_until = re.search(r'until\s*\((.*)\)', code)
        if m_until:
            cond = m_until.group(1)
            code = f"}} while(!({cond}));" 

        # Operators
        code = code.replace(".gt.", " > ").replace(".lt.", " < ")
        code = code.replace(".ge.", " >= ").replace(".le.", " <= ")
        code = code.replace(".eq.", " == ").replace(".ne.", " != ")
        code = code.replace(".not.", " ! ").replace(".and.", " && ").replace(".or.", " || ")
        code = code.replace("~=", " != ").replace("^=", " != ").replace("~", " ! ")
        code = code.replace("|", " || ").replace("&", " && ")

        # Smart Access (Array vs Function)
        def repl_access(m):
            name = m.group(1)
            arg = m.group(2)
            # If it's a known LOCAL array, use brackets
            if vars_info.get(name, {}).get("is_array"):
                return f"{name}[{arg}]"
            return f"{name}({arg})"

        code = re.sub(r'\b([a-zA-Z_]\w*)\(([^)]+)\)', repl_access, code)

        # Semicolons
        stripped = code.strip()
        skip_semi = False
        if not stripped: skip_semi = True
        if stripped.endswith((';', '{', '}')): skip_semi = True
        if stripped.startswith(('#', 'include', 'define', '//')): skip_semi = True
        keywords = ["if", "for", "while", "else", "do ", "case", "default"]
        if any(stripped.startswith(k) for k in keywords): skip_semi = True
            
        if not skip_semi:
            code += ";"

        output.append(f"{code} {comment}")

    return "\n".join(output)

def parse_ratfor(lines):
    output = []
    
    # Pass 0: Generate Correct Prototypes
    prototypes = scan_prototypes(lines)
    for p in prototypes:
        output.append(p)
    
    output.append("") 

    # Pass 1: Chunk blocks
    current_block = []
    
    # Extract function names for filtering
    func_names = set()
    for p in prototypes:
        # Extract name from prototype string e.g., "int tabpos(..."
        m = re.match(r'\w+\s+(\w+)\(', p)
        if m: func_names.add(m.group(1))

    for line in lines:
        if line.strip().startswith("include"):
            output.append(f"// {line.strip()}") 
            continue
            
        current_block.append(line)
        
        # Check for END using clean code
        code, _ = split_comment(line)
        if re.match(r'^\s*end\s*$', code, re.IGNORECASE):
            output.append(parse_ratfor_block(current_block, func_names))
            output.append("")
            current_block = []
            
    # Handle implicit main if leftovers exist (and have code)
    if current_block:
         has_code = any(l.strip() and not l.strip().startswith('#') for l in current_block)
         if has_code:
            output.append(parse_ratfor_block(current_block, func_names))
         
    return "\n".join(output)

if __name__ == "__main__":
    try:
        if len(sys.argv) < 2:
            print("Usage: python r2c.py input.r")
        else:
            with open(sys.argv[1], 'r') as f:
                print("#include \"tools.h\"\n")
                print(parse_ratfor(f.readlines()))
    except Exception as e:
        # Print error to stderr so it shows up even if stdout is redirected
        sys.stderr.write(f"\nCRITICAL ERROR in r2c.py:\n{traceback.format_exc()}\n")
        sys.exit(1)