#
# Copyright (C) 2020-2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Add su only userdebug and eng builds
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
  PRODUCT_PACKAGES += su
  PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += system/xbin/su
endif
