#!/usr/bin/env python3
"""
Flash Image Creator

This script creates a complete disk image by combining individual partition images
into a single .img file using dd commands. It replicates the functionality of the
original U-Boot flashing script.
"""

import os
import subprocess
import argparse
from pathlib import Path

# Define partition information
# Format: (image_name, start_block, num_blocks, fill_size)
PARTITIONS = [
    ("env.img", 0x0, 0x40, 0x8000),
    ("idblock.img", 0x40, 0x170, 0x2E000),
    ("uboot.img", 0x440, 0x200, 0x40000),
    ("boot.img", 0x640, 0x180D, 0x301A00),
    ("oem.img", 0x10640, 0x12028, 0x2405000),
    ("userdata.img", 0x110640, 0x4C4A, 0x989400),
    ("rootfs.img", 0x190640, 0x49018, 0x9203000)
]

def create_disk_image(source_dir, output_img, block_size=512):
    """
    Create a complete disk image from individual partition images.
    
    Args:
        source_dir (str): Directory containing partition image files
        output_img (str): Path to the output disk image file
        block_size (int): Size of each block in bytes (default: 512)
    """
    source_dir = Path(source_dir)
    total_size = 0
    
    # Calculate total size needed for the image
    for _, start_block, num_blocks, _ in PARTITIONS:
        end_pos = (start_block + num_blocks) * block_size
        if end_pos > total_size:
            total_size = end_pos
    
    print(f"Creating disk image of size {total_size} bytes ({total_size/1024/1024:.2f} MB)")

    # Create an empty image file filled with zeros
    # More efficient way to create a sparse file of the correct size
    with open(output_img, 'wb') as f:
        f.seek(total_size - 1)
        f.write(b'\0')
    
    # Write each partition to the image
    for img_name, start_block, num_blocks, fill_size in PARTITIONS:
        img_path = source_dir / img_name
        offset = start_block * block_size
        
        if not img_path.exists():
            print(f"Warning: {img_name} not found, skipping this partition")
            continue
        
        print(f"Writing {img_name} to position {offset} ({start_block} blocks)")
        
        # Write the image file to the correct position in the output image
        # Using a larger block size for better performance
        subprocess.run([
            "dd", 
            f"if={img_path}",
            f"of={output_img}",
            f"bs={block_size}",
            f"seek={start_block}",
            "conv=notrunc",
            "status=progress"
        ], check=True)
    
    print(f"Disk image created successfully: {output_img}")

def main():
    parser = argparse.ArgumentParser(description="Create a disk image from individual partition images")
    parser.add_argument("source_dir", help="Directory containing the partition image files")
    parser.add_argument("output_img", help="Path for the output disk image file")
    parser.add_argument("--block-size", type=int, default=512, help="Block size in bytes (default: 512)")
    
    args = parser.parse_args()
    
    create_disk_image(args.source_dir, args.output_img, args.block_size)

if __name__ == "__main__":
    main()