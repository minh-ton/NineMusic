TARGET := iphone:clang::13.3

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = NineMusicPref

NineMusicPref_FILES = NineMusicRootListController.m NineMusicRootHeaderView.mm
NineMusicPref_FRAMEWORKS = UIKit
NineMusicPref_PRIVATE_FRAMEWORKS = Preferences
NineMusicPref_INSTALL_PATH = /Library/PreferenceBundles
NineMusicPref_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
