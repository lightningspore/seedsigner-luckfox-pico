import os
import struct
import time
from periphery import GPIO
from hardware.ST7789 import ST7789
from PIL import Image

# Set up the V4L2 device and capture configuration
CAMERA_DEVICE = '/dev/video15'
WIDTH = 240
HEIGHT = 135
PIXEL_FORMAT = 'NV12'  # Y/CbCr 4:2:0 format
FRAME_SIZE = 48480  # This is the size of one frame in bytes

# Define button pins
pins = [
    ("KEY3", GPIO(42, "in")),  # KEY 3 Back Button (Always pressed?)
    ("KEY2", GPIO(43, "in")),  # KEY 2
    ("KEY1", GPIO(55, "in")),  # KEY 1 
    ("RIGHT", GPIO(54, "in")),  # RIGHT
    ("DOWN", GPIO(53, "in")),  # DOWN
    ("IN", GPIO(52, "in")),  # IN (Push directional button in)
    ("UP", GPIO(58, "in")),  # UP
    ("LEFT", GPIO(59, "in")),  # LEFT
]

# Initialize the LCD display
disp = ST7789()
width, height = 240, 240  # LCD resolution


def capture_frame():
    """
    Captures one frame from the camera using v4l2-ctl.
    """
    # Ensure the output file doesn't already exist
    if os.path.exists('frame.yuv'):
        os.remove('frame.yuv')
    
    cmd = f'v4l2-ctl --device={CAMERA_DEVICE} --set-fmt-video=width={WIDTH},height={HEIGHT},pixelformat={PIXEL_FORMAT} --stream-mmap --stream-to=frame.yuv --stream-count=1'
    print(f"Executing command: {cmd}")
    
    # Use os.system to run the command and capture potential errors
    result = os.system(cmd)
    print(f"v4l2-ctl command exit status: {result}")
    
    # Check if file was created
    if not os.path.exists('frame.yuv'):
        raise ValueError("Failed to capture frame. No output file created.")
    
    with open('frame.yuv', 'rb') as file:
        frame_data = file.read()
    
    print(f"Captured frame size: {len(frame_data)} bytes")
    
    # Some additional sanity checks
    if len(frame_data) == 0:
        raise ValueError("Captured frame is empty!")
    
    return frame_data

def convert_nv12_to_rgb(frame_data):
    """
    Converts NV12 frame data to an RGB image with improved error handling.
    """
    WIDTH = 240
    HEIGHT = 135
    
    # Precise frame size calculations
    y_size = WIDTH * HEIGHT  # Luma (Y) plane size
    uv_width = (WIDTH + 1) // 2  # Chroma plane width
    uv_height = (HEIGHT + 1) // 2  # Chroma plane height
    uv_size = uv_width * uv_height * 2  # UV plane size (interleaved U and V)
    
    # Slice the planes, being careful about exact sizes
    y_plane = frame_data[:y_size]
    uv_plane = frame_data[y_size:y_size + uv_size]
    
    # Ensure we use the minimum of the actual data and expected sizes
    effective_y_size = min(len(y_plane), y_size)
    effective_uv_size = min(len(uv_plane), uv_size)
    
    rgb_data = bytearray()
    
    for i in range(HEIGHT):
        for j in range(WIDTH):
            y_index = i * WIDTH + j
            uv_index = (i // 2) * uv_width + (j // 2)
            
            # Robust bounds checking
            if y_index >= effective_y_size:
                # If Y index is out of bounds, use black
                r, g, b = 0, 0, 0
            else:
                # Get Y value
                y = y_plane[y_index]
                
                # Carefully handle UV indices
                if uv_index * 2 + 1 >= effective_uv_size:
                    # If UV index is out of bounds, use neutral gray for chroma
                    u, v = 0, 0
                else:
                    u = uv_plane[2 * uv_index] - 128
                    v = uv_plane[2 * uv_index + 1] - 128
                
                # YUV to RGB conversion with clamping
                r = max(0, min(255, int(y + 1.402 * v)))
                g = max(0, min(255, int(y - 0.344136 * u - 0.714136 * v)))
                b = max(0, min(255, int(y + 1.772 * u)))
            
            rgb_data.extend([r, g, b])
    
    return rgb_data

def display_on_lcd(rgb_data):
    """
    Display the frame on the LCD screen using PIL Image.
    """
    try:
        # Create a PIL Image from the raw RGB data
        img = Image.frombytes('RGB', (WIDTH, HEIGHT), bytes(rgb_data))
        
        # If the display resolution is different, resize to fit
        img = img.resize((width, height))
        
        # Display the image on the LCD
        disp.ShowImage(img, 0, 0)
    except Exception as e:
        print(f"Failed to display image: {e}")


def main():
    """
    Main loop that waits for KEY1 button press, captures a frame, and displays it on the LCD.
    """
    print("Waiting for KEY1 button press to capture image...")

    try:
        while True:
            # Find the KEY1 pin
            key1_pin = next((pin for name, pin in pins if name == "KEY1"), None)
            
            if key1_pin is None:
                print("ERROR: KEY1 pin not found!")
                break
            
            if not key1_pin.read():  # KEY1 button is pressed (active low)
                print("KEY1 button pressed! Capturing frame...")
                frame_data = capture_frame()
                print("Frame captured successfully.")
                
                print("Converting NV12 to RGB...")
                rgb_data = convert_nv12_to_rgb(frame_data)
                
                print("Displaying frame on the LCD screen...")
                display_on_lcd(rgb_data)
                
                # Debounce the button
                time.sleep(0.5)
                
                # Wait for the button to be released
                while not key1_pin.read():
                    pass
            
            # Small delay to prevent tight looping
            time.sleep(0.1)
    
    except KeyboardInterrupt:
        print("Exiting...")
    finally:
        # Clean up GPIO pins
        for _, pin in pins:
            pin.close()


if __name__ == "__main__":
    main()
