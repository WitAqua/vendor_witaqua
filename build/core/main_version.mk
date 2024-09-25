# Build fingerprint
ifneq ($(BUILD_FINGERPRINT),)
ADDITIONAL_SYSTEM_PROPERTIES += \
    ro.build.fingerprint=$(BUILD_FINGERPRINT)
endif

# WitAqua System Version
ADDITIONAL_SYSTEM_PROPERTIES += \
    ro.witaqua.build.version=$(WITAQUA_VERSION) \
    ro.witaqua.display.version=$(WITAQUA_DISPLAY_VERSION) \
    ro.witaqua.version=$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR) \
    ro.modversion=$(WITAQUA_VERSION) \
    ro.witaqualegal.url=https://witaqua.tokyo/legal.html
    
