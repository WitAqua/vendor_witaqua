# Inherit common Lineage stuff
$(call inherit-product, vendor/witaqua/config/common.mk)

# Inherit Lineage car device tree
$(call inherit-product, device/witaqua/car/witaqua_car.mk)
