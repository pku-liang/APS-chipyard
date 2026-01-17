import sys
import argparse
import re

def get_signal_id(line):
    """
    Extracts the VCD signal identifier from a value change line.
    """
    line = line.strip()
    if not line:
        return None
        
    if line.startswith('b') or line.startswith('r'):
        return line.split()[-1]
    else:
        return line[1:]

def extract_vcd_module(input_vcd_path, output_vcd_path, target_module, include_submodules=False):
    """
    Parses a VCD file and extracts all signals and their values
    for a specific module, optionally including its submodules.

    Args:
        input_vcd_path (str): Path to the large input VCD file.
        output_vcd_path (str): Path to write the new, smaller VCD file.
        target_module (str): The full hierarchical name of the module to extract.
        include_submodules (bool): If True, also extracts all submodules within the target.
    """
    print(f"[*] Starting VCD extraction...")
    print(f"    Input file:  {input_vcd_path}")
    print(f"    Output file: {output_vcd_path}")
    print(f"    Target module: {target_module}")
    print(f"    Include submodules: {include_submodules}")

    signals_to_keep = set()
    
    # State tracking
    in_desired_scope = False
    in_header = True
    scope_stack = []

    try:
        with open(input_vcd_path, 'r', errors='ignore') as f_in, open(output_vcd_path, 'w') as f_out:
            for i, line in enumerate(f_in):
                stripped_line = line.strip()

                if in_header:
                    # --- HEADER PARSING PHASE ---
                    # Always copy basic metadata
                    if stripped_line.startswith(('$date', '$version', '$timescale', '$comment')):
                        f_out.write(line)
                        continue

                    if stripped_line.startswith('$scope'):
                        parts = stripped_line.split()
                        scope_stack.append(parts[2])
                        current_scope_str = ".".join(scope_stack)
                        
                        if include_submodules:
                            # Check if the current scope is the target or a child of it
                            if current_scope_str.startswith(target_module):
                                in_desired_scope = True
                        else:
                            # Original behavior: check for exact match
                            if current_scope_str == target_module:
                                in_desired_scope = True
                        
                        # If we are in a scope we care about, write its definition
                        if in_desired_scope:
                            f_out.write(line)

                    elif stripped_line.startswith('$var'):
                        # If we are inside a desired scope, keep this signal
                        if in_desired_scope:
                            parts = stripped_line.split()
                            signal_id = parts[3]
                            signals_to_keep.add(signal_id)
                            f_out.write(line)

                    elif stripped_line.startswith('$upscope'):
                        # Write the $upscope if we were in a scope we cared about
                        if in_desired_scope:
                            f_out.write(line)
                        
                        if scope_stack:
                            scope_stack.pop()
                        
                        # After popping, re-evaluate if we are still in a desired scope
                        current_scope_str = ".".join(scope_stack)
                        if include_submodules:
                            if not current_scope_str.startswith(target_module):
                                in_desired_scope = False
                        else:
                            if current_scope_str != target_module:
                                in_desired_scope = False
                        # Special case for exiting the target module itself
                        if not scope_stack and in_desired_scope:
                            in_desired_scope = False


                    elif stripped_line.startswith('$enddefinitions'):
                        in_header = False
                        print(f"[*] Header parsed. Found {len(signals_to_keep)} signals in '{target_module}' and its submodules.")
                        if not signals_to_keep:
                            print(f"[!] Warning: No signals were found for module '{target_module}'.")
                            print(f"    Check if the module name is correct and has the right hierarchy.")
                            print(f"    Aborting to avoid creating an empty file.")
                            return False

                        print(f"[*] Now parsing value changes, this may take a long time...")
                        f_out.write(line)
                    
                    elif in_desired_scope:
                        # Write any other commands inside our desired scope
                        f_out.write(line)

                else:
                    # --- VALUE PARSING PHASE ---
                    if not stripped_line:
                        continue

                    if stripped_line.startswith('#'):
                        # Timestamp, always keep.
                        f_out.write(line)
                    elif stripped_line.startswith('$'):
                        # Simulation command (e.g., $dumpvars), copy it.
                        f_out.write(line)
                    else:
                        # Value change line.
                        signal_id = get_signal_id(stripped_line)
                        if signal_id in signals_to_keep:
                            f_out.write(line)

        print(f"[*] Extraction complete. Filtered VCD written to '{output_vcd_path}'.")
        return True

    except FileNotFoundError:
        print(f"[!] Error: Input file not found at '{input_vcd_path}'")
        return False
    except Exception as e:
        print(f"[!] An unexpected error occurred: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description="A Python script to extract signals from a specific module in a large VCD file.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('input_vcd', help="Path to the input VCD file.")
    parser.add_argument('output_vcd', help="Path for the filtered output VCD file.")
    parser.add_argument('module_name', help="Full hierarchical name of the module to extract (e.g., 'TOP.tb_top.dut').")
    parser.add_argument(
        '--submodules', 
        action='store_true', 
        help="If set, include all signals from submodules within the target module."
    )

    args = parser.parse_args()
    
    extract_vcd_module(args.input_vcd, args.output_vcd, args.module_name, args.submodules)

if __name__ == '__main__':
    main()