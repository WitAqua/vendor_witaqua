# Boot sounds
TARGET_BOOTANIMATION_SOUND_SUPPORTED ?= true

ifeq ($(TARGET_BOOTANIMATION_SOUND_SUPPORTED),true)
PRODUCT_PACKAGES += \
    WitAquaBootSoundOverlay
else
PRODUCT_PRODUCT_PROPERTIES += \
    persist.sys.bootanim.play_sound=0
endif
