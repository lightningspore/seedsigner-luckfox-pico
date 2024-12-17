import os
import struct
import time
from periphery import GPIO
from hardware.ST7789 import ST7789
from PIL import Image, ImageDraw, ImageFont


# Set up the V4L2 device and capture configuration
CAMERA_DEVICE = '/dev/video15'
WIDTH = 240
HEIGHT = 135
PIXEL_FORMAT = 'NV12'  # Y/CbCr 4:2:0 format
FRAME_SIZE = 48480  # This is the size of one frame in bytes

# Define button pins
pins = [
    ("KEY2", GPIO(43, "in")),  # KEY 2
    ("KEY1", GPIO(55, "in")),  # KEY 1 
    ("RIGHT", GPIO(54, "in")),  # RIGHT
    ("DOWN", GPIO(53, "in")),  # DOWN
    ("IN", GPIO(52, "in")),  # IN (Push directional button in)
    ("UP", GPIO(58, "in")),  # UP
    ("LEFT", GPIO(59, "in")),  # LEFT
    ("KEY3", GPIO(42, "in")),  # KEY 3 Back Button (Always pressed?)
]
#    

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


def display_message(text, display_time = 2):
    """
    Display a message on the image display with Unicode and encoding safeguards.
    
    Args:
    text (str): The message to display
    """
    # Create a blank image with RGB mode
    img = Image.new('RGB', (width, height), (0, 0, 0))  # Black background
    draw = ImageDraw.Draw(img)
    
    # Load a Font
    font = ImageFont.load_default()
    # font = ImageFont.truetype("/Poppins-Regular.otf", 24)
    
    # Sanitize text: replace or remove problematic Unicode characters
    # This ensures we only use ASCII or easily encodable characters
    safe_text = ''.join(char if ord(char) < 128 else ' ' for char in text)
    
    # Use textbbox to get text dimensions
    text_bbox = draw.textbbox((0, 0), safe_text, font=font)
    
    # Calculate text width and height from bounding box
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    
    # Center the text
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    # Draw the text
    draw.text((x, y), safe_text, font=font, fill=(255, 255, 255))  # White text
    disp.ShowImage(img, 0, 0)

    # Wait for specified display time
    time.sleep(display_time)




def button_test():
    """Test each button on the device."""
    results = {}
    for name, pin in pins:
        display_message(f"Press {name} button", 0.5)
        start_time = time.time()
        while True:
            if not pin.read():  # Button is pressed (active low)
                results[name] = True
                display_message(f"{name} Button OK ✓", 1.5)
                time.sleep(0.5)  # Debounce
                while not pin.read():
                    pass  # Wait until released
                break
            elif time.time() - start_time > 10:  # 10-second timeout
                display_message(f"{name} Button NOT pressed (timeout)")
                results[name] = False
                break
            time.sleep(0.1)
    return results



def camera_test():
    """Test the camera by capturing a frame and displaying it."""
    try:
        display_message("Testing Camera...")
        frame_data = capture_frame()
        display_message("Converting to RGB...")
        rgb_data = convert_nv12_to_rgb(frame_data)
        display_on_lcd(rgb_data)
        time.sleep(2)
        return True
    except Exception as e:
        display_message(f"Camera Error: {str(e)}")
        return False


def main():
    """Main hardware test loop with interactive menu."""
    while True:
        # Main menu display with updated button instructions
        display_message("Welcome to Hardware Test.\n\nPress KEY1 for Button Test\nPress KEY2 for Camera Test\nPress IN to exit.")
        
        # Get pin references
        key1_pin = next((pin for name, pin in pins if name == "KEY1"), None)
        key2_pin = next((pin for name, pin in pins if name == "KEY2"), None)
        in_pin = next((pin for name, pin in pins if name == "IN"), None)
        
        # Wait and check which key is pressed
        start_time = time.time()
        selected_test = None
        
        while True:
            # Check for IN button to exit
            if not in_pin.read():
                display_message("Exiting Test Suite...")
                time.sleep(1)
                return
            
            # Check for KEY1 (Button Test)
            if not key1_pin.read():
                selected_test = "button"
                break
            
            # Check for KEY2 (Camera Test)
            if not key2_pin.read():
                selected_test = "camera"
                break
            
            time.sleep(0.1)
        
        # Run selected test
        if selected_test == "button":
            display_message("Starting Button Test...")
            button_results = button_test()
            
            # Display button test results
            results_message = "Button Test Results:\n"
            for button, result in button_results.items():
                results_message += f"{button}: {'[OK]' if result else '[FAIL]'}\n"
            
            display_message(results_message, 5)
        
        elif selected_test == "camera":
            display_message("Starting Camera Test...")
            camera_result = camera_test()
            
            # Display camera test result
            results_message = f"Camera Test Result:\n{'[OK]' if camera_result else '[FAIL]'}"
            display_message(results_message, 5)
        
        # Optional: Add a brief pause to prevent accidental re-selection
        time.sleep(0.5)

if __name__ == "__main__":
    main()