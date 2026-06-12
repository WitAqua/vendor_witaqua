PRODUCT_BRAND ?= WitAqua

# Audio
include vendor/witaqua/config/audio.mk

# RRO Overlays
include vendor/witaqua/config/rro_overlays.mk

# Version
include vendor/witaqua/config/version.mk

# Keys
-include vendor/witaqua-priv/keys/keys.mk
