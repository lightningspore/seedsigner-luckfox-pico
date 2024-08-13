from typing import List
# import RPi.GPIO as GPIO
from periphery import GPIO
import time

from seedsigner.models.singleton import Singleton

class HardwareButtons(Singleton):
    # if GPIO.RPI_INFO['P1_REVISION'] == 3: #This indicates that we have revision 3 GPIO
    #     print("Detected 40pin GPIO (Rasbperry Pi 2 and above)")
    #     KEY_UP_PIN = 31
    #     KEY_DOWN_PIN = 35
    #     KEY_LEFT_PIN = 29
    #     KEY_RIGHT_PIN = 37
    #     KEY_PRESS_PIN = 33

    #     KEY1_PIN = 40
    #     KEY2_PIN = 38
    #     KEY3_PIN = 36

    # else:
    #     print("Assuming 26 Pin GPIO (Raspberry P1 1)")
    #     KEY_UP_PIN = 5
    #     KEY_DOWN_PIN = 11
    #     KEY_LEFT_PIN = 3
    #     KEY_RIGHT_PIN = 15
    #     KEY_PRESS_PIN = 7

    #     KEY1_PIN = 16
    #     KEY2_PIN = 12
    #     KEY3_PIN = 8

    KEY_UP_PIN = 5
    KEY_DOWN_PIN = 11
    KEY_LEFT_PIN = 3
    KEY_RIGHT_PIN = 15
    KEY_PRESS_PIN = 7

    KEY1_PIN = 16
    KEY2_PIN = 12
    KEY3_PIN = 8

    @classmethod
    def get_instance(cls):
        # This is the only way to access the one and only instance
        if cls._instance is None:
            cls._instance = cls.__new__(cls)

            #init GPIO
            # GPIO.setmode(GPIO.BOARD)
            # GPIO.setup(HardwareButtons.KEY_UP_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)    # Input with pull-up
            # GPIO.setup(HardwareButtons.KEY_DOWN_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)  # Input with pull-up
            # GPIO.setup(HardwareButtons.KEY_LEFT_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)  # Input with pull-up
            # GPIO.setup(HardwareButtons.KEY_RIGHT_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
            # GPIO.setup(HardwareButtons.KEY_PRESS_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
            # GPIO.setup(HardwareButtons.KEY1_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)      # Input with pull-up
            # GPIO.setup(HardwareButtons.KEY2_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)      # Input with pull-up
            # GPIO.setup(HardwareButtons.KEY3_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)      # Input with pull-up

            pin1 = GPIO(42, "in") # LEFT  # yes-pullup
            pin2 = GPIO(43, "in") # RIGHT # yes-pullup
            pin4 = GPIO(55, "in") # UP    # no-pullup
            pin5 = GPIO(54, "in") # DOWN  # no-pullup

            pin6 = GPIO(53, "in") # PRESS # no-pullup

            pin7 = GPIO(52, "in") # KEY1  # no-pullup
            pin9 = GPIO(58, "in") # KEY2  # no-pullup
            pin10 = GPIO(59, "in")# KEY3  # no-pullup

            mapping = {
                42: pin1,
                43: pin2,
                55: pin4,
                54: pin5,
                53: pin6,
                52: pin7,
                58: pin9,
                59: pin10
            }


            cls._instance.GPIO = mapping
            cls._instance.override_ind = False

            cls._instance.add_events([HardwareButtonsConstants.KEY_UP, HardwareButtonsConstants.KEY_DOWN, HardwareButtonsConstants.KEY_PRESS, HardwareButtonsConstants.KEY_LEFT, HardwareButtonsConstants.KEY_RIGHT, HardwareButtonsConstants.KEY1, HardwareButtonsConstants.KEY2, HardwareButtonsConstants.KEY3])

            # Track state over time so we can apply input delays/ignores as needed
            cls._instance.cur_input = None           # Track which direction or button was last pressed
            cls._instance.cur_input_started = None   # Track when that input began
            cls._instance.last_input_time = int(time.time() * 1000)  # How long has it been since the last input?
            cls._instance.first_repeat_threshold = 225  # Long-press time required before returning continuous input
            cls._instance.next_repeat_threshold = 250  # Amount of time where we no longer consider input a continuous hold

        return cls._instance


    def wait_for(self, keys=[], check_release=True, release_keys=[]) -> int:
        print(f"wait for --- {keys}")
        import random
        # TODO: Refactor to keep control in the Controller and not here
        from seedsigner.controller import Controller
        controller = Controller.get_instance()

        if not release_keys:
            release_keys = keys
        self.override_ind = False

        while True:
            # print("wait_for loop")
            cur_time = int(time.time() * 1000)
            if cur_time - self.last_input_time > controller.screensaver_activation_ms and not controller.is_screensaver_running:
                # Start the screensaver. Will block execution until input detected.
                controller.start_screensaver()

                # We're back. Update last_input_time to now.
                self.update_last_input_time()

                # Freeze any further processing for a moment to avoid having the wakeup
                #   input register in the resumed UI.
                time.sleep(self.next_repeat_threshold / 1000.0)

                # Resume from a fresh loop
                continue

            # time.sleep(1)

            # print(f"available keys: {keys}")
            # # random_key = random.choice(keys)
            # random_key = int(input("what to do?"))    
            # self.update_last_input_time()
            # return random_key

            for key in keys:
                if not check_release or ((check_release and key in release_keys and HardwareButtonsConstants.release_lock) or check_release and key not in release_keys):
                    # when check release is False or the release lock is released (True)
                    # if self.GPIO.input(key) == GPIO.LOW or self.override_ind:
                    if self.GPIO[key].read() == False or self.override_ind:
                        print(f"{key} is pressed! what now?")
                        # HardwareButtonsConstants.release_lock = False
                        HardwareButtonsConstants.release_lock = True
                        if self.override_ind:
                            self.override_ind = False
                            return HardwareButtonsConstants.OVERRIDE

                        if self.cur_input != key:
                            self.cur_input = key
                            self.cur_input_started = int(time.time() * 1000)  # in milliseconds
                            self.last_input_time = self.cur_input_started
                            return key

                        else:
                            # Still pressing the same input
                            if cur_time - self.last_input_time > self.next_repeat_threshold:
                                # Too much time has elapsed to consider this the same
                                #   continuous input. Treat as a new separate press.
                                self.cur_input_started = cur_time
                                self.last_input_time = cur_time
                                return key

                            elif cur_time - self.cur_input_started > self.first_repeat_threshold:
                                # We're good to relay this immediately as continuous
                                #   input.
                                self.last_input_time = cur_time
                                return key

                            else:
                                # We're not yet at the first repeat threshold; triggering
                                #   a key now would be too soon and yields a bad user
                                #   experience when only a single click was intended but
                                #   a second input is processed because of race condition
                                #   against human response time to release the button.
                                # So there has to be a delay before we allow the first
                                #   continuous repeat to register. So we'll ignore this
                                #   round's input and **won't update any of our
                                #   timekeeping vars**. But once we cross the threshold,
                                #   we let the repeats fly.
                                pass

            time.sleep(0.01) # wait 10 ms to give CPU chance to do other things


    def update_last_input_time(self):
        print("update_last_input_time")
        self.last_input_time = int(time.time() * 1000)


    def add_events(self, keys=[]):
        pass
        # for key in keys:
        #     GPIO.add_event_detect(key, self.GPIO.RISING, callback=HardwareButtons.rising_callback)


    def rising_callback(channel):
        HardwareButtonsConstants.release_lock = True


    def trigger_override(self, force_release = False) -> bool:
        if force_release:
            HardwareButtonsConstants.release_lock = True

        if not self.override_ind:
            self.override_ind = True
            return True
        return False

    def force_release(self) -> bool:
        HardwareButtonsConstants.release_lock = True
        return True

    def check_for_low(self, key: int = None, keys: List[int] = None) -> bool:
        print("check_for_low")
        if key:
            keys = [key]
        for key in keys:
            # if self.GPIO.input(key) == self.GPIO.LOW:
            if self.GPIO[key].read() == False:
                self.update_last_input_time()
                return True
        else:
            return False

    def has_any_input(self) -> bool:
        for key in HardwareButtonsConstants.ALL_KEYS:
            # if self.GPIO.input(key) == GPIO.LOW:
            try:
                if self.GPIO[key].read() == False:
                    return True
            except IndexError as e:
                print(e)
                print(f"issue with key: {key}")
        return False

# class used as short hand for static button/channel lookup values
# TODO: Implement `release_lock` functionality as a global somewhere. Mixes up design
#   patterns to have a static constants class plus a settable global value.
class HardwareButtonsConstants:
    # if True:
    # if GPIO.RPI_INFO['P1_REVISION'] == 3: #This indicates that we have revision 3 GPIO
    KEY_UP = 43
    KEY_DOWN = 54
    KEY_LEFT = 42
    KEY_RIGHT = 53
    KEY_PRESS = 55

    KEY1 = 58
    KEY2 = 52
    KEY3 = 59

    # if True:
    # # if GPIO.RPI_INFO['P1_REVISION'] == 3: #This indicates that we have revision 3 GPIO
    #     KEY_UP = 31
    #     KEY_DOWN = 35
    #     KEY_LEFT = 29
    #     KEY_RIGHT = 37
    #     KEY_PRESS = 33

    #     KEY1 = 40
    #     KEY2 = 38
        # KEY3 = 36
    # else:
    #     KEY_UP = 5
    #     KEY_DOWN = 11
    #     KEY_LEFT = 3
    #     KEY_RIGHT = 15
    #     KEY_PRESS = 7

    #     KEY1 = 16
    #     KEY2 = 12
    #     KEY3 = 8

    OVERRIDE = 1000

    ALL_KEYS = [
        KEY_UP,
        KEY_DOWN,
        KEY_LEFT,
        KEY_RIGHT,
        KEY_PRESS,
        KEY1,
        KEY2,
        KEY3,
    ]

    KEYS__LEFT_RIGHT_UP_DOWN = [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
    KEYS__ANYCLICK = [KEY_PRESS, KEY1, KEY2, KEY3]

    release_lock = True # released when True, locked when False
