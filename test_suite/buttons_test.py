#!/usr/bin/env python3

import sys
import os
import time
import platform

# Add the seedsigner src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'seedsigner'))

# Monkey patch the Settings class to use our custom settings file
from seedsigner.models.settings import Settings


Settings.SETTINGS_FILENAME = "/seedsigner/settings.json"

from seedsigner.hardware.buttons import HardwareButtons, HardwareButtonsConstants
from seedsigner.models.settings_definition import SettingsConstants

def test_button_initialization():
    """Test that buttons can be initialized"""
    print("Testing button initialization...")
    try:
        buttons = HardwareButtons.get_instance()
        print("✓ Buttons initialized successfully")
        return True
    except Exception as e:
        print(f"✗ Failed to initialize buttons: {e}")
        return False

def test_button_names():
    """Test that all button names are defined"""
    print("\nTesting button names...")
    expected_names = [
        "KEY_UP", "KEY_DOWN", "KEY_LEFT", "KEY_RIGHT", 
        "KEY_PRESS", "KEY1", "KEY2", "KEY3"
    ]
    
    for name in expected_names:
        if hasattr(HardwareButtonsConstants, name):
            print(f"✓ {name} defined")
        else:
            print(f"✗ {name} missing")
            return False
    return True

def test_hardware_config():
    """Test hardware configuration detection"""
    print("\nTesting hardware configuration...")
    try:
        # Check if we can get hardware config
        configs = SettingsConstants.ALL_HARDWARE_PIN_CONFIGS
        print(f"✓ Found {len(configs)} hardware configurations")
        
        # Check Luckfox configs specifically
        fox_configs = [c for c in configs if 'FOX' in c[0]]
        print(f"✓ Found {len(fox_configs)} Luckfox configurations")
        
        return True
    except Exception as e:
        print(f"✗ Hardware config test failed: {e}")
        return False

def test_current_hardware_config():
    """Display the currently configured hardware configuration"""
    print("\n=== Current Hardware Configuration ===")
    try:        
        hardware_config = Settings.get_instance().get_value(SettingsConstants.SETTING__HARDWARE_CONFIG)
        print(f"Current hardware config: {hardware_config}")
        
 
        
        return True
    except Exception as e:
        print(f"✗ Failed to get current hardware config: {e}")
        return False

def test_button_press_simulation():
    """Test button press simulation (without actual hardware)"""
    print("\nTesting button press simulation...")
    try:
        buttons = HardwareButtons.get_instance()
        
        # Test trigger_override
        buttons.trigger_override()
        print("✓ Override trigger works")
        
        # Test update_last_input_time
        buttons.update_last_input_time()
        print("✓ Input time update works")
        
        return True
    except Exception as e:
        print(f"✗ Button simulation failed: {e}")
        return False

def test_each_button():
    """Test each button by asking user to press them one by one"""
    print("\n=== Testing Each Button ===")
    print("Press each button when prompted...")
    
    buttons = HardwareButtons.get_instance()
    button_names = [
        "KEY_UP",
        "KEY_DOWN", 
        "KEY_LEFT",
        "KEY_RIGHT",
        "KEY_PRESS",
        "KEY1",
        "KEY2",
        "KEY3"
    ]
    
    results = {}
    
    for button_const in button_names:
        print(f"\nPress the {button_const} button...")
        print("(Waiting for button press...)")
        
        try:
            # Wait for the specific button
            pressed_button = buttons.wait_for([button_const])
            
            if pressed_button == button_const:
                print(f"✓ {button_const} button works!")
                results[button_const] = True
            else:
                print(f"✗ {button_const} button failed - got {pressed_button}")
                results[button_const] = False
                
        except Exception as e:
            print(f"✗ {button_const} button error: {e}")
            results[button_const] = False
    
    # Summary
    print(f"\n=== Button Test Results ===")
    passed = sum(results.values())
    total = len(results)
    
    for button_const in button_names:
        status = "✓" if results[button_const] else "✗"
        print(f"{status} {button_const}")
    
    print(f"\nPassed: {passed}/{total}")
    return passed == total

def main():
    print("=== Basic Button Test Script ===\n")
    
    tests = [
        test_button_initialization,
        test_button_names,
        test_hardware_config,
        test_current_hardware_config,
        test_button_press_simulation,
        test_each_button
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
