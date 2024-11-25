from ST7789 import ST7789

from PIL import Image
import random

# Define the dimensions
width, height = 240, 240


def random_image():
    # Create a new image with RGB mode
    img = Image.new('RGB', (width, height))
    # Generate random colors for each pixel
    pixels = []
    for y in range(height):
        for x in range(width):
            pixels.append((random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)))
    # Update the image with the generated colors
    img.putdata(pixels)
    return img


def solid_color_image(r,g,b):
    # Create a new image with RGB mode
    img = Image.new('RGB', (width, height))
    # Generate random colors for each pixel
    pixels = []
    for y in range(height):
        for x in range(width):
            pixels.append((r, g, b))
    # Update the image with the generated colors
    img.putdata(pixels)
    return img 

# Intialize display library
disp = ST7789()

rimg = random_image()
disp.ShowImage(rimg, 0, 0)

yellow_img = solid_color_image(255,238,109)
disp.ShowImage(yellow_img, 0, 0)


orange_img = solid_color_image(255,100,0)
disp.ShowImage(orange_img, 0, 0)