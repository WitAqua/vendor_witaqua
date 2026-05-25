PRODUCT_BRAND ?= WitAqua

# RRO Overlays
include vendor/witaqua/config/rro_overlays.mk

# Version
include vendor/witaqua/config/version.mk

# Keys
-include vendor/witaqua-priv/keys/keys.mk