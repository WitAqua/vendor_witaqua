# WitAqua-ify
PRODUCT_PACKAGES += \
	WitAquaFrameworksResOverlay

# Standard Overlays
PRODUCT_PACKAGE_OVERLAYS += \
    vendor/witaqua/overlay/common

PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += \
    vendor/witaqua/overlay/common