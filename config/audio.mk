LOCAL_PATH := vendor/witaqua/audio

# Alarms
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/alarms,$(TARGET_COPY_OUT_PRODUCT)/media/audio/alarms)

# Ringtones
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/ringtones,$(TARGET_COPY_OUT_PRODUCT)/media/audio/ringtones)

# Default Sounds
PRODUCT_PRODUCT_PROPERTIES += \
    ro.config.ringtone=Frail_Naysayer.ogg \
    ro.config.alarm_alert=Birdland.m4a
