import time

from periphery import GPIO


pin_LEFT = GPIO(42, "in")  # LEFT  # yes-pullup
pin_RIGHT = GPIO(43, "in") # RIGHT # yes-pullup
pin_UP = GPIO(55, "in")    # UP    # no-pullup
pin_DOWN = GPIO(54, "in")  # DOWN  # no-pullup

pin_ENTER = GPIO(53, "in") # PRESS # no-pullup

pin_KEY1 = GPIO(52, "in")  # KEY1  # no-pullup
pin_KEY2 = GPIO(58, "in")  # KEY2  # no-pullup
pin_KEY3 = GPIO(59, "in")  # KEY3  # no-pullup

val = pin_KEY3.read()


pins = [
    ("LEFT", pin_LEFT),
    ("RIGHT", pin_RIGHT),
    ("UP", pin_UP),
    ("DOWN", pin_DOWN),
    ("ENTER", pin_ENTER),
    ("KEY1", pin_KEY1),
    ("KEY2", pin_KEY2),
    ("KEY3", pin_KEY3)
]

for name, pin in pins:
    print(f"Press the {name} button and then press Enter")
    while pin.read():
        pass
    input("Button pressed, press Enter to continue...")
    print(f"{name} button confirmed working")
    time.sleep(0.5)

print("All buttons confirmed working")
