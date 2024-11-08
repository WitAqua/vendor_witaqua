PRODUCT_VERSION_MAJOR = 15
PRODUCT_VERSION_MINOR = 1

# Increase WitAqua Version with each major release.
WITAQUA_VERSION := 2.1
WITAQUA_BUILD_TYPE ?= UNOFFICIAL

# Internal version
LINEAGE_VERSION := WitAqua-$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(shell date +%Y%m%d)-$(LINEAGE_BUILD)-v$(WITAQUA_VERSION)-$(WITAQUA_BUILD_TYPE)

# Display version
LINEAGE_DISPLAY_VERSION := v$(WITAQUA_VERSION)-$(shell date +%Y%m%d)

# WitAqua version properties
PRODUCT_SYSTEM_PROPERTIES += \
    ro.witaqua.build.version=$(WITAQUA_VERSION) \
    ro.witaqua.display.version=$(LINEAGE_DISPLAY_VERSION) \
    ro.witaqua.version=$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR) \
    ro.modversion=$(WITAQUA_VERSION)
