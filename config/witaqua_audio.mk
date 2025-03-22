#
# WitAqua Audio Files
#

ALARM_PATH := vendor/lineage/prebuilt/common/media/audio-witaqua/alarms
NOTIFICATION_PATH := vendor/lineage/prebuilt/common/media/audio-witaqua/notifications
RINGTONE_PATH := vendor/lineage/prebuilt/common/media/audio-witaqua/ringtones

# Alarms
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(ALARM_PATH),$(TARGET_COPY_OUT_PRODUCT)/media/audio/alarms)

# Notifications
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(NOTIFICATION_PATH),$(TARGET_COPY_OUT_PRODUCT)/media/audio/notifications)

# Ringtones
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(RINGTONE_PATH),$(TARGET_COPY_OUT_PRODUCT)/media/audio/ringtones)
