LOCAL_PATH := vendor/witaqua/audio

# Alarms
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/alarms,$(TARGET_COPY_OUT_PRODUCT)/media/audio/alarms)

# Ringtones
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/ringtones,$(TARGET_COPY_OUT_PRODUCT)/media/audio/ringtones)

# 2019 Material product sounds (CC-BY 4.0)
# Source: https://material.io/design/sound/sound-resources.html
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/material/,$(TARGET_COPY_OUT_PRODUCT)/media/audio)

# Default Sounds
PRODUCT_PRODUCT_PROPERTIES += \
    ro.config.ringtone=Frail_Naysayer.ogg \
    ro.config.alarm_alert=Birdland.m4a \
    ro.config.notification_sound=material_simple-celebration_1.ogg
