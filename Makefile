TARGET = iphone:11.2:11.0
ARCHS = arm64
THEOS_DEVICE_IP = 0
THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeirdFlexButOK
WeirdFlexButOK_FILES = Extensions/NSString+Random.m Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk


