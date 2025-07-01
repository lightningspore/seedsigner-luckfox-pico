import sys
import os
import time
import platform

# Add the seedsigner src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'seedsigner'))

# Monkey patch the Settings class to use our custom settings file
from seedsigner.models.settings import Settings
Settings.SETTINGS_FILENAME = "/seedsigner/settings.json"

from seedsigner.gui.renderer import Renderer
from seedsigner.models.settings_definition import SettingsConstants
from seedsigner.hardware.camera import Camera

def initialize_renderer():
    """Initialize the renderer once for all tests"""
    try:
        Renderer.configure_instance()
        return Renderer.get_instance()
    except Exception as e:
        print(f"Failed to initialize renderer: {e}")
        return None

def test_camera_initialization():
    """Test that camera can be initialized"""
    print("Testing camera initialization...")
    try:
        camera = Camera.get_instance()
        print("✓ Camera initialized successfully")
        return True
    except Exception as e:
        print(f"✗ Failed to initialize camera: {e}")
        return False

def test_camera_settings():
    """Test and display current camera settings"""
    print("\nTesting camera settings...")
    try:
        settings = Settings.get_instance()
        
        # Get hardware configuration
        hardware_config = settings.get_value(SettingsConstants.SETTING__HARDWARE_CONFIG)
        print(f"✓ Hardware config: {hardware_config}")
        
        # Get camera rotation setting
        camera_rotation = settings.get_value(SettingsConstants.SETTING__CAMERA_ROTATION, default_if_none=True)
        print(f"✓ Camera rotation: {camera_rotation}°")
        
        return True
    except Exception as e:
        print(f"✗ Camera settings test failed: {e}")
        return False

def test_camera_hardware_config():
    """Test hardware configuration detection"""
    print("\nTesting camera hardware configuration...")
    try:
        # Check if we can get hardware config
        configs = SettingsConstants.ALL_HARDWARE_PIN_CONFIGS
        print(f"✓ Found {len(configs)} hardware configurations")
        
        # Check Luckfox configs specifically
        fox_configs = [c for c in configs if 'FOX' in c[0]]
        print(f"✓ Found {len(fox_configs)} Luckfox configurations")
        
        return True
    except Exception as e:
        print(f"✗ Camera hardware config test failed: {e}")
        return False

def test_current_camera_config():
    """Display the currently configured camera configuration"""
    print("\n=== Current Camera Configuration ===")
    try:        
        hardware_config = Settings.get_instance().get_value(SettingsConstants.SETTING__HARDWARE_CONFIG)
        print(f"Current hardware config: {hardware_config}")
        
        # Get camera pin mapping
        pin_mapping = SettingsConstants.ALL_HARDWARE_PIN_CONFIGS__PIN_DEFINITIONS[hardware_config]["camera"]
        print(f"Camera device: {pin_mapping['device']}")
        print(f"Camera resolution: {pin_mapping['resolution']}")
        print(f"Camera pixel format: {pin_mapping['pixelformat']}")
        print(f"Camera framerate: {pin_mapping['framerate']}")
        
        return True
    except Exception as e:
        print(f"✗ Failed to get current camera config: {e}")
        return False

def test_camera_capture_and_display():
    """Test taking photos and displaying them on the LCD"""
    print("\n=== Testing Camera Capture and Display ===")
    print("Taking 10 photos and displaying them on screen...")
    
    try:
        camera = Camera.get_instance()
        renderer = Renderer.get_instance()
        
        # Start video stream mode
        camera.start_video_stream_mode()
        print("✓ Video stream started")
        
        for i in range(1, 11):
            print(f"\nTaking photo {i}/10...")
            
            try:
                # Capture image from camera using read_video_stream
                image = camera.read_video_stream(as_image=True)
                
                if image is not None:
                    print(f"✓ Photo {i} captured successfully")
                    
                    # Resize image to fit the LCD screen
                    resized_image = image.resize((renderer.canvas_width, renderer.canvas_height))
                    
                    # Display the image on the LCD
                    renderer.show_image(resized_image, show_direct=True)
                    
                    print(f"✓ Photo {i} displayed on screen")
                else:
                    print(f"✗ Failed to capture photo {i}")
                
                # Wait between captures
                if i < 10:  # Don't wait after the last photo
                    print("Waiting 3 seconds before next capture...")
                    time.sleep(3)
                    
            except Exception as e:
                print(f"✗ Error capturing/displaying photo {i}: {e}")
                continue
        
        # Stop video stream mode
        camera.stop_video_stream_mode()
        print("✓ Video stream stopped")
        
        print("\n✓ Camera capture and display test completed")
        return True
        
    except Exception as e:
        print(f"✗ Camera capture and display test failed: {e}")
        # Make sure to stop video stream even if there's an error
        try:
            camera.stop_video_stream_mode()
        except:
            pass
        return False

def test_camera_resolution():
    """Test different camera resolutions"""
    print("\nTesting camera resolutions...")
    try:
        camera = Camera.get_instance()
        renderer = Renderer.get_instance()
        
        # Start video stream mode
        camera.start_video_stream_mode()
        
        # Get current resolution from settings
        settings = Settings.get_instance()
        hardware_config = settings.get_value(SettingsConstants.SETTING__HARDWARE_CONFIG)
        pin_mapping = SettingsConstants.ALL_HARDWARE_PIN_CONFIGS__PIN_DEFINITIONS[hardware_config]["camera"]
        current_resolution = pin_mapping["resolution"]
        print(f"✓ Current resolution: {current_resolution}")
        
        # Test capturing at current resolution
        image = camera.read_video_stream(as_image=True)
        if image is not None:
            print(f"✓ Captured image size: {image.size}")
            
            # Display the image
            resized_image = image.resize((renderer.canvas_width, renderer.canvas_height))
            renderer.show_image(resized_image, show_direct=True)
            time.sleep(2)
        
        # Stop video stream mode
        camera.stop_video_stream_mode()
        
        return True
    except Exception as e:
        print(f"✗ Camera resolution test failed: {e}")
        # Make sure to stop video stream even if there's an error
        try:
            camera.stop_video_stream_mode()
        except:
            pass
        return False

def main():
    print("=== Camera Test Script ===\n")
    
    # Initialize the renderer once at the beginning
    print("Initializing renderer...")
    renderer = initialize_renderer()
    if renderer is None:
        print("✗ Failed to initialize renderer. Exiting.")
        return 1
    
    tests = [
        test_camera_initialization,
        test_camera_settings,
        test_camera_hardware_config,
        test_current_camera_config,
        test_camera_resolution,
        test_camera_capture_and_display
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
