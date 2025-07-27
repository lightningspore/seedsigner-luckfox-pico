#!/usr/bin/env python3
"""
U-Boot Script Parser

This script parses a U-Boot flashing script and extracts the partition information,
outputting it in a format suitable for the Flash Image Creator script.
"""

import re
import sys
import json
from pathlib import Path

def parse_uboot_script(file_path):
    """
    Parse a U-Boot script and extract partition information.
    
    Args:
        file_path (str): Path to the U-Boot script file
        
    Returns:
        list: List of partition entries (name, start_block, num_blocks, fill_size)
    """
    partitions = []
    
    # Read the script file
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Process lines in pairs (comment line + command line)
    i = 0
    while i < len(lines) - 1:
        comment_line = lines[i].strip()
        command_line = lines[i+1].strip()
        
        # Skip if not a proper partition entry
        if not comment_line.startswith('#') or 'mw.b' not in command_line:
            i += 1
            continue
        
        # Extract image name from comment line
        image_match = re.match(r'#(\S+)\s', comment_line)
        if not image_match:
            i += 2
            continue
        
        image_name = image_match.group(1)
        
        # Extract address information from comment line
        # Format: #image.img start:size start:size blocks:bytes
        address_info = re.findall(r'0x[0-9a-fA-F]+:0x[0-9a-fA-F]+', comment_line)
        
        # Extract fill size from command line
        fill_match = re.search(r'mw\.b\s+\$\{ramdisk_addr_r\}\s+0xff\s+(0x[0-9a-fA-F]+)', command_line)
        
        # Extract block count from command line
        block_match = re.search(r'mmc\s+write\s+\$\{ramdisk_addr_r\}\s+(0x[0-9a-fA-F]+)\s+(0x[0-9a-fA-F]+)', command_line)
        
        if fill_match and block_match and len(address_info) >= 1:
            start_block = int(block_match.group(1), 16)
            num_blocks = int(block_match.group(2), 16)
            fill_size = int(fill_match.group(1), 16)
            
            partitions.append((image_name, start_block, num_blocks, fill_size))
        
        i += 2  # Move to the next pair of lines
    
    return partitions

def format_for_python(partitions):
    """
    Format the partitions list as Python code for the Flash Image Creator script.
    
    Args:
        partitions (list): List of partition entries
        
    Returns:
        str: Formatted Python code
    """
    result = "PARTITIONS = [\n"
    for name, start, blocks, size in partitions:
        result += f"    (\"{name}\", 0x{start:X}, 0x{blocks:X}, 0x{size:X}),\n"
    result += "]\n"
    return result

def format_as_json(partitions):
    """
    Format the partitions list as JSON.
    
    Args:
        partitions (list): List of partition entries
        
    Returns:
        str: JSON representation
    """
    json_data = []
    for name, start, blocks, size in partitions:
        json_data.append({
            "name": name,
            "start_block": f"0x{start:X}",
            "num_blocks": f"0x{blocks:X}",
            "fill_size": f"0x{size:X}"
        })
    return json.dumps(json_data, indent=4)

def main():
    if len(sys.argv) < 2:
        print("Usage: python uboot_parser.py <uboot_script_file> [--json]")
        return
    
    script_path = sys.argv[1]
    output_format = "python"
    
    if len(sys.argv) > 2 and sys.argv[2] == "--json":
        output_format = "json"
    
    partitions = parse_uboot_script(script_path)
    
    if output_format == "json":
        print(format_as_json(partitions))
    else:
        print(format_for_python(partitions))

if __name__ == "__main__":
    main()