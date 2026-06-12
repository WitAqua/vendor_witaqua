PRODUCT_VERSION_MAJOR := 3
PRODUCT_VERSION_MINOR := 2

WITAQUA_BUILD_TYPE ?= UNOFFICIAL
WITAQUA_MAINTAINER ?= Unknown

# Versioning System
WITAQUA_BUILD_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)

# Internal version
LINEAGE_VERSION := WitAqua-v$(WITAQUA_BUILD_VERSION)-$(shell date -u +%Y%m%d)-$(LINEAGE_BUILD)-$(WITAQUA_BUILD_TYPE)

# Display version
LINEAGE_DISPLAY_VERSION := $(LINEAGE_VERSION)

# WitAqua version properties
PRODUCT_PRODUCT_PROPERTIES += \
    ro.witaqua.build.version=$(WITAQUA_BUILD_VERSION) \
    ro.witaqua.build.status=$(WITAQUA_BUILD_TYPE) \
    ro.witaqua.maintainer=$(WITAQUA_MAINTAINER)

# Device info
WITAQUA_PROCESSOR_INFO ?= Unknown

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.witaqua_processor_info=$(subst $() ,_,$(WITAQUA_PROCESSOR_INFO)) \
    persist.sys.device_camera_info_rear=$(CUSTOM_CAMERA_REAR_INFO) \
    persist.sys.device_camera_info_front=$(CUSTOM_CAMERA_FRONT_INFO)
