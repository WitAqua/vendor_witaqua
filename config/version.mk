PRODUCT_VERSION_MAJOR := 4
PRODUCT_VERSION_MINOR := 0

WITAQUA_BUILD_TYPE ?= UNOFFICIAL
WITAQUA_MAINTAINER ?= Unknown

# Versioning System
WITAQUA_BUILD_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)

# Internal version
LINEAGE_VERSION := WitAqua-$(PLATFORM_VERSION).$(PRODUCT_VERSION_MINOR)-$(shell date -u +%Y%m%d)-$(LINEAGE_BUILD)-v$(WITAQUA_BUILD_VERSION)-$(WITAQUA_BUILD_TYPE)

# Display version
LINEAGE_DISPLAY_VERSION := $(LINEAGE_VERSION)

# WitAqua version properties
PRODUCT_PRODUCT_PROPERTIES += \
    ro.witaqua.build.version=$(WITAQUA_BUILD_VERSION) \
    ro.witaqua.build.status=$(WITAQUA_BUILD_TYPE) \
    ro.witaqua.maintainer=$(WITAQUA_MAINTAINER)

# Device info
PROCESSOR_INFO ?= Unknown

PRODUCT_PRODUCT_PROPERTIES += \
    persist.sys.processor_info=$(subst $() ,_,$(PROCESSOR_INFO)) \
    persist.sys.device_camera_info_rear=$(CAMERA_REAR_INFO) \
    persist.sys.device_camera_info_front=$(CAMERA_FRONT_INFO)
