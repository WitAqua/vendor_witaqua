# Inherit mobile full common Lineage stuff
$(call inherit-product, vendor/witaqua/config/common_mobile_full.mk)

# Inherit tablet common Lineage stuff
$(call inherit-product, vendor/witaqua/config/tablet.mk)

$(call inherit-product, vendor/witaqua/config/wifionly.mk)
