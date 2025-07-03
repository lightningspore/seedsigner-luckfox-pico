import sys
import os
import time
import argparse
from datetime import datetime

# Add the seedsigner src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'seedsigner'))

# Monkey patch the Settings class to use our custom settings file
from seedsigner.models.settings import Settings
Settings.SETTINGS_FILENAME = "/seedsigner/settings.json"

from seedsigner.models.settings_definition import SettingsConstants
from seedsigner.hardware.camera import Camera

def initialize_camera():
    """Initialize the camera"""
    try:
        camera = Camera.get_instance()
        print("✓ Camera initialized successfully")
        return camera
    except Exception as e:
        print(f"✗ Failed to initialize camera: {e}")
        return None

def get_camera_settings():
    """Get and display current camera settings"""
    try:
        settings = Settings.get_instance()
        
        # Get hardware configuration
        hardware_config = settings.get_value(SettingsConstants.SETTING__HARDWARE_CONFIG)
        print(f"✓ Hardware config: {hardware_config}")
        
        # Get camera rotation setting
        camera_rotation = settings.get_value(SettingsConstants.SETTING__CAMERA_ROTATION, default_if_none=True)
        print(f"✓ Camera rotation: {camera_rotation}°")
        
        # Get camera pin mapping
        pin_mapping = SettingsConstants.ALL_HARDWARE_PIN_CONFIGS__PIN_DEFINITIONS[hardware_config]["camera"]
        print(f"✓ Camera device: {pin_mapping['device']}")
        print(f"✓ Camera resolution: {pin_mapping['resolution']}")
        print(f"✓ Camera pixel format: {pin_mapping['pixelformat']}")
        print(f"✓ Camera framerate: {pin_mapping['framerate']}")
        
        return True
    except Exception as e:
        print(f"✗ Camera settings failed: {e}")
        return False

def capture_photos(camera, interval_seconds, output_dir, max_photos=None, format='jpg'):
    """Capture photos at specified intervals and save them"""
    print(f"\n=== Starting Photo Capture ===")
    print(f"Interval: {interval_seconds} seconds")
    print(f"Output directory: {output_dir}")
    print(f"Format: {format}")
    if max_photos:
        print(f"Max photos: {max_photos}")
    else:
        print("Max photos: Unlimited")
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Start video stream mode
    camera.start_video_stream_mode()
    print("✓ Video stream started")
    
    # Give the camera time to initialize and warm up
    print("Waiting for camera to initialize...")
    time.sleep(3)
    
    photo_count = 0
    start_time = time.time()
    
    # Map user format to PIL format string
    format_map = {"jpg": "JPEG", "jpeg": "JPEG", "png": "PNG"}
    save_format = format_map.get(format.lower(), "PNG")
    
    try:
        while True:
            if max_photos and photo_count >= max_photos:
                print(f"\n✓ Reached maximum number of photos ({max_photos})")
                break
            
            photo_count += 1
            current_time = datetime.now()
            timestamp = current_time.strftime("%Y%m%d_%H%M%S")
            filename = f"photo_{timestamp}_{photo_count:04d}.{format.lower()}"
            filepath = os.path.join(output_dir, filename)
            
            print(f"\nTaking photo {photo_count}...")
            
            try:
                # Capture image from camera
                image = camera.read_video_stream(as_image=True)
                
                if image is not None:
                    # Save the image
                    image.save(filepath, format=save_format)
                    print(f"✓ Photo {photo_count} saved: {filename}")
                    print(f"  Size: {image.size}")
                    print(f"  File: {filepath}")
                else:
                    print(f"✗ Failed to capture photo {photo_count}")
                    continue
                
            except Exception as e:
                print(f"✗ Error capturing photo {photo_count}: {e}")
                continue
            
            # Wait for next capture (except after the last photo)
            if max_photos and photo_count >= max_photos:
                break
            
            print(f"Waiting {interval_seconds} seconds before next capture...")
            time.sleep(interval_seconds)
    
    except KeyboardInterrupt:
        print(f"\n\n=== Capture Interrupted by User ===")
        print(f"Total photos captured: {photo_count}")
        elapsed_time = time.time() - start_time
        print(f"Total time: {elapsed_time:.1f} seconds")
    
    finally:
        # Stop video stream mode
        camera.stop_video_stream_mode()
        print("✓ Video stream stopped")
    
    return photo_count

def main():
    parser = argparse.ArgumentParser(description='Capture photos from camera at configurable intervals')
    parser.add_argument('--interval', '-i', type=int, default=5, 
                       help='Interval between photos in seconds (default: 5)')
    parser.add_argument('--output', '-o', type=str, default='./captured_photos',
                       help='Output directory for photos (default: ./captured_photos)')
    parser.add_argument('--max', '-m', type=int, default=None,
                       help='Maximum number of photos to capture (default: unlimited)')
    parser.add_argument('--format', '-f', type=str, choices=['jpg', 'png'], default='jpg',
                       help='Image format (default: jpg)')
    parser.add_argument('--settings', '-s', action='store_true',
                       help='Show camera settings and exit')
    
    args = parser.parse_args()
    
    print("=== Camera Capture Script ===\n")
    
    # Initialize camera
    camera = initialize_camera()
    if camera is None:
        print("✗ Failed to initialize camera. Exiting.")
        return 1
    
    # Show camera settings if requested
    if args.settings:
        print("\n=== Camera Settings ===")
        get_camera_settings()
        return 0
    
    # Show current settings
    print("=== Current Camera Settings ===")
    get_camera_settings()
    
    # Start capture
    photo_count = capture_photos(
        camera=camera,
        interval_seconds=args.interval,
        output_dir=args.output,
        max_photos=args.max,
        format=args.format
    )
    
    print(f"\n=== Capture Complete ===")
    print(f"Total photos captured: {photo_count}")
    print(f"Photos saved to: {args.output}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 