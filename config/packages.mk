#
# Copyright (C) 2020-2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Mind The Gapps
WITH_GMS ?= false
ifeq ($(WITH_GMS),true)
  # We don't want to include gapps in official builds
  ifeq ($(WITAQUA_BUILD_TYPE),OFFICIAL)
    $(error Include gapps in official builds are not allowed.)
  endif
  PRODUCT_PACKAGES += GoogleConfigOverlay
  TARGET_GAPPS_ARCH ?= arm64
  $(call inherit-product, vendor/gapps/$(TARGET_GAPPS_ARCH)/$(TARGET_GAPPS_ARCH)-vendor.mk)
endif

# Add su only userdebug and eng builds
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
  PRODUCT_PACKAGES += su
  PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += system/xbin/su
endif

# Face Unlock
ifeq ($(TARGET_SUPPORTS_64_BIT_APPS),true)
PRODUCT_PACKAGES += \
    FaceUnlock

PRODUCT_SYSTEM_EXT_PROPERTIES += \
    ro.face.sense_service=true

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.biometrics.face.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.biometrics.face.xml
endif
