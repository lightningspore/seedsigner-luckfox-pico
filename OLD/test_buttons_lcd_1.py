import time
from periphery import GPIO
from hardware.ST7789 import ST7789
from PIL import Image, ImageDraw, ImageFont

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
width, height = 240, 240

# Helper function to display text on the LCD
def display_text(text):
    # Create a blank image with RGB mode
    img = Image.new('RGB', (width, height), (0, 0, 0))  # Black background
    draw = ImageDraw.Draw(img)
    # Load a default font
    font = ImageFont.load_default()
    # Center the text
    text_width, text_height = draw.textsize(text, font=font)
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    # Draw the text
    draw.text((x, y), text, font=font, fill=(255, 255, 255))  # White text
    disp.ShowImage(img, 0, 0)

# Main loop to detect button presses
def main():
    try:
        while True:
            for name, pin in pins:
                if not pin.read():  # Button is pressed
                    display_text(f"{name} Pressed")
                    time.sleep(0.5)  # Debounce delay
                    # Wait for the button to be released
                    while not pin.read():
                        pass
    except KeyboardInterrupt:
        print("Exiting...")
    finally:
        # Clean up GPIO pins
        for _, pin in pins:
            pin.close()

# Run the script
if __name__ == "__main__":
    main()
