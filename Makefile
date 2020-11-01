TARGET := iphone:clang::13.3
THEOS_DEVICE_IP = 192.168.1.211
ARCHS = arm64 arm64e
DEBUG=0

PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NineMusic

NineMusic_FILES = NineMusic.xm support/MarqueeLabel.m
NineMusic_CFLAGS = -fobjc-arc
NineMusic_FRAMEWORKS = UIKit
NineMusic_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += ninemusicpref
include $(THEOS_MAKE_PATH)/aggregate.mk
