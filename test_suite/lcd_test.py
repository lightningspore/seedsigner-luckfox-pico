#!/usr/bin/env python3

import sys
import os
import time
import platform
from PIL import Image, ImageDraw

# Add the seedsigner src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'seedsigner'))

# Monkey patch the Settings class to use our custom settings file
from seedsigner.models.settings import Settings
Settings.SETTINGS_FILENAME = "/seedsigner/settings.json"

from seedsigner.gui.renderer import Renderer
from seedsigner.models.settings_definition import SettingsConstants

def initialize_renderer():
    """Initialize the renderer once for all tests"""
    try:
        Renderer.configure_instance()
        return Renderer.get_instance()
    except Exception as e:
        print(f"Failed to initialize renderer: {e}")
        return None

def test_lcd_initialization():
    """Test that LCD can be initialized"""
    print("Testing LCD initialization...")
    try:
        renderer = Renderer.get_instance()
        print("✓ LCD initialized successfully")
        return True
    except Exception as e:
        print(f"✗ Failed to initialize LCD: {e}")
        return False

def test_display_settings():
    """Test and display current LCD settings"""
    print("\nTesting display settings...")
    try:
        settings = Settings.get_instance()
        
        # Get display configuration
        display_config = settings.get_value(SettingsConstants.SETTING__DISPLAY_CONFIGURATION, default_if_none=True)
        print(f"✓ Display config: {display_config}")
        
        # Get hardware configuration
        hardware_config = settings.get_value(SettingsConstants.SETTING__HARDWARE_CONFIG)
        print(f"✓ Hardware config: {hardware_config}")
        
        # Get color inversion setting
        color_inverted = settings.get_value(SettingsConstants.SETTING__DISPLAY_COLOR_INVERTED, default_if_none=True)
        print(f"✓ Color inverted: {color_inverted}")
        
        return True
    except Exception as e:
        print(f"✗ Display settings test failed: {e}")
        return False

def test_display_dimensions():
    """Test and display LCD dimensions"""
    print("\nTesting display dimensions...")
    try:
        # Get the already configured renderer instance
        renderer = Renderer.get_instance()
        
        print(f"✓ Canvas width: {renderer.canvas_width}")
        print(f"✓ Canvas height: {renderer.canvas_height}")
        print(f"✓ Display type: {renderer.display_type}")
        
        return True
    except Exception as e:
        print(f"✗ Display dimensions test failed: {e}")
        return False

def create_flag_image(width, height, flag_type):
    """Create a simple flag image using PIL"""
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    if flag_type == "france":
        # French flag: blue, white, red vertical stripes
        third = width // 3
        draw.rectangle([0, 0, third, height], fill=(0, 85, 164))  # Blue
        draw.rectangle([third, 0, 2*third, height], fill=(255, 255, 255))  # White
        draw.rectangle([2*third, 0, width, height], fill=(239, 65, 53))  # Red
        
    elif flag_type == "germany":
        # German flag: black, red, gold horizontal stripes
        third = height // 3
        draw.rectangle([0, 0, width, third], fill=(0, 0, 0))  # Black
        draw.rectangle([0, third, width, 2*third], fill=(221, 0, 0))  # Red
        draw.rectangle([0, 2*third, width, height], fill=(255, 206, 0))  # Gold
        
    elif flag_type == "italy":
        # Italian flag: green, white, red vertical stripes
        third = width // 3
        draw.rectangle([0, 0, third, height], fill=(0, 146, 70))  # Green
        draw.rectangle([third, 0, 2*third, height], fill=(255, 255, 255))  # White
        draw.rectangle([2*third, 0, width, height], fill=(206, 43, 55))  # Red
        
    elif flag_type == "japan":
        # Japanese flag: white background with red circle
        draw.rectangle([0, 0, width, height], fill=(255, 255, 255))  # White background
        circle_radius = min(width, height) // 3
        circle_x = width // 2
        circle_y = height // 2
        draw.ellipse([circle_x - circle_radius, circle_y - circle_radius, 
                     circle_x + circle_radius, circle_y + circle_radius], 
                    fill=(188, 0, 45))  # Red circle
        
    elif flag_type == "usa":
        # Simplified US flag: red and white stripes with blue canton
        stripe_height = height // 13
        for i in range(13):
            y_start = i * stripe_height
            y_end = (i + 1) * stripe_height
            if i % 2 == 0:  # Red stripes
                draw.rectangle([0, y_start, width, y_end], fill=(179, 25, 66))
            else:  # White stripes
                draw.rectangle([0, y_start, width, y_end], fill=(255, 255, 255))
        
        # Blue canton (top left)
        canton_width = width // 2
        canton_height = height // 2
        draw.rectangle([0, 0, canton_width, canton_height], fill=(10, 49, 97))
    
    return img

def test_flag_display():
    """Test displaying different flag images on the LCD"""
    print("\nTesting flag display...")
    try:
        # Get the already configured renderer instance
        renderer = Renderer.get_instance()
        flags = ["france", "germany", "italy", "japan", "usa"]
        
        for i, flag_type in enumerate(flags, 1):
            print(f"Displaying {flag_type} flag ({i}/5)...")
            
            # Create flag image
            flag_img = create_flag_image(renderer.canvas_width, renderer.canvas_height, flag_type)
            
            # Display the flag
            renderer.show_image(flag_img, show_direct=True)
            
            # Wait a bit to see the flag
            time.sleep(2)
        
        print("✓ All flags displayed successfully")
        return True
    except Exception as e:
        print(f"✗ Flag display test failed: {e}")
        return False

def test_color_display():
    """Test displaying different colors on the LCD"""
    print("\nTesting color display...")
    try:
        # Get the already configured renderer instance
        renderer = Renderer.get_instance()
        colors = [
            ("Red", (255, 0, 0)),
            ("Green", (0, 255, 0)),
            ("Blue", (0, 0, 255)),
            ("White", (255, 255, 255)),
            ("Black", (0, 0, 0)),
            ("Yellow", (255, 255, 0)),
            ("Cyan", (0, 255, 255)),
            ("Magenta", (255, 0, 255))
        ]
        
        for color_name, color_rgb in colors:
            print(f"Displaying {color_name}...")
            
            # Create solid color image
            color_img = Image.new('RGB', (renderer.canvas_width, renderer.canvas_height), color_rgb)
            
            # Display the color
            renderer.show_image(color_img, show_direct=True)
            
            # Wait a bit to see the color
            time.sleep(1)
        
        print("✓ All colors displayed successfully")
        return True
    except Exception as e:
        print(f"✗ Color display test failed: {e}")
        return False

def test_pattern_display():
    """Test displaying patterns on the LCD"""
    print("\nTesting pattern display...")
    try:
        # Get the already configured renderer instance
        renderer = Renderer.get_instance()
        
        # Create a checkerboard pattern
        print("Displaying checkerboard pattern...")
        pattern_img = Image.new('RGB', (renderer.canvas_width, renderer.canvas_height))
        draw = ImageDraw.Draw(pattern_img)
        
        square_size = 20
        for x in range(0, renderer.canvas_width, square_size):
            for y in range(0, renderer.canvas_height, square_size):
                if (x // square_size + y // square_size) % 2 == 0:
                    draw.rectangle([x, y, x + square_size, y + square_size], fill=(255, 255, 255))
                else:
                    draw.rectangle([x, y, x + square_size, y + square_size], fill=(0, 0, 0))
        
        renderer.show_image(pattern_img, show_direct=True)
        time.sleep(3)
        
        # Create a gradient pattern
        print("Displaying gradient pattern...")
        gradient_img = Image.new('RGB', (renderer.canvas_width, renderer.canvas_height))
        draw = ImageDraw.Draw(gradient_img)
        
        for x in range(renderer.canvas_width):
            for y in range(renderer.canvas_height):
                r = int((x / renderer.canvas_width) * 255)
                g = int((y / renderer.canvas_height) * 255)
                b = 128
                draw.point((x, y), fill=(r, g, b))
        
        renderer.show_image(gradient_img, show_direct=True)
        time.sleep(3)
        
        print("✓ All patterns displayed successfully")
        return True
    except Exception as e:
        print(f"✗ Pattern display test failed: {e}")
        return False

def test_text_display():
    """Test displaying text on the LCD"""
    print("\nTesting text display...")
    try:
        # Get the already configured renderer instance
        renderer = Renderer.get_instance()
        
        # Create a test image with text
        text_img = Image.new('RGB', (renderer.canvas_width, renderer.canvas_height), (0, 0, 0))
        draw = ImageDraw.Draw(text_img)
        
        # Try to use a basic font, fallback to default if not available
        try:
            from PIL import ImageFont
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
        except:
            font = ImageFont.load_default()
        
        # Draw some test text
        text_lines = [
            "LCD Test",
            f"Size: {renderer.canvas_width}x{renderer.canvas_height}",
            "Display Working!",
            "Flags: France, Germany,",
            "Italy, Japan, USA"
        ]
        
        y_offset = 20
        for line in text_lines:
            draw.text((10, y_offset), line, fill=(255, 255, 255), font=font)
            y_offset += 30
        
        renderer.show_image(text_img, show_direct=True)
        time.sleep(3)
        
        print("✓ Text display test successful")
        return True
    except Exception as e:
        print(f"✗ Text display test failed: {e}")
        return False

def test_blank_screen():
    """Test displaying a blank screen"""
    print("\nTesting blank screen...")
    try:
        # Get the already configured renderer instance
        renderer = Renderer.get_instance()
        renderer.display_blank_screen()
        print("✓ Blank screen displayed successfully")
        return True
    except Exception as e:
        print(f"✗ Blank screen test failed: {e}")
        return False

def main():
    print("=== LCD Display Test Script ===\n")
    
    # Initialize the renderer once at the beginning
    print("Initializing renderer...")
    renderer = initialize_renderer()
    if renderer is None:
        print("✗ Failed to initialize renderer. Exiting.")
        return 1
    
    tests = [
        test_lcd_initialization,
        test_display_settings,
        test_display_dimensions,
        test_color_display,
        test_pattern_display,
        test_flag_display,
        test_text_display,
        test_blank_screen
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()
    
    print(f"=== Test Results ===")
    print(f"Passed: {passed}/{total}")
    
    if passed == total:
        print("✓ All tests passed!")
        return 0
    else:
        print("✗ Some tests failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main())
