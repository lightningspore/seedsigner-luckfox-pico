from pyzbar.pyzbar import decode

from PIL import Image

decode(Image.open('/test_suite/test-qrcode.png'))