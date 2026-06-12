# WitAqua-ify
PRODUCT_PACKAGES += \
	WitAquaFrameworksResOverlay

# Optional
PRODUCT_PACKAGES += \
    DisableCameraSoundOverlay

# Standard Overlays
PRODUCT_PACKAGE_OVERLAYS += \
	vendor/witaqua/overlay/common

PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += \
	vendor/witaqua/overlay/common
