#!/bin/bash

if [ "$#" -lt 5 ]; then
    echo "Usage: $0 <STOCK_DEVICE> <TARGET_DEVICE> <TARGET_DEVICE_CSC> <TARGET_DEVICE_IMEI> <OUTPUT_FILESYSTEM>"
    exit 1
fi

# Device info
export STOCK_DEVICE="$1"
export TARGET_DEVICE="$2"
export TARGET_DEVICE_CSC="$3"
export TARGET_DEVICE_IMEI="$4"
export OUTPUT_FILESYSTEM="$5"

# Directories
export OUT_DIR="$(pwd)/OUT"
export WORK_DIR="$(pwd)/WORK"
export FIRM_DIR="$(pwd)/FIRMWARE"
export DEVICES_DIR="$(pwd)/OceanTools/Devices"
export APKTOOL="$(pwd)/bin/apktool/apktool.jar"
export VNDKS_COLLECTION="$(pwd)/OceanTools/vndks"
export SMART_MANAGER_CN="$(pwd)/OceanTools/Mods/SMART_MANAGER_CN"

export BUILD_PARTITIONS="product,system_ext,system"

# Source
source "$(pwd)/scripts/OceanScript.sh"

EXTRACT_FIRMWARE "$FIRM_DIR/$TARGET_DEVICE"
EXTRACT_FIRMWARE_IMG "$FIRM_DIR/$TARGET_DEVICE"

APPLY_STOCK_CONFIG "$FIRM_DIR/$TARGET_DEVICE"
DEBLOAT "$FIRM_DIR/$TARGET_DEVICE"
APPLY_CUSTOM_FEATURES "$FIRM_DIR/$TARGET_DEVICE"

INSTALL_FRAMEWORK "$FIRM_DIR/$TARGET_DEVICE/system/system/framework/framework-res.apk"
DECOMPILE "$APKTOOL" "$FIRM_DIR/$TARGET_DEVICE/system/system/framework/ssrm.jar" "$WORK_DIR"
DECOMPILE "$APKTOOL" "$FIRM_DIR/$TARGET_DEVICE/system/system/framework/services.jar" "$WORK_DIR"

PATCH_SSRM "$WORK_DIR/ssrm"
PATCH_FLAG_SECURE "$WORK_DIR/services"
PATCH_SECURE_FOLDER "$WORK_DIR/services"

RECOMPILE "$APKTOOL" "$WORK_DIR/ssrm" "$FIRM_DIR/$TARGET_DEVICE/system/system/framework" "$WORK_DIR"
RECOMPILE "$APKTOOL" "$WORK_DIR/services" "$FIRM_DIR/$TARGET_DEVICE/system/system/framework" "$WORK_DIR"
mv -f "$WORK_DIR"/*.jar "$FIRM_DIR/$TARGET_DEVICE/system/system/framework/"

PATCH_BT_LIB "$FIRM_DIR/$TARGET_DEVICE" "$WORK_DIR"

D_ID="$(grep -m1 '^ro.build.display.id=' "$FIRM_DIR/$TARGET_DEVICE/system/system/build.prop" | cut -d= -f2 | tr -d '\r')"
BUILD_PROP "$FIRM_DIR/$TARGET_DEVICE" "system" "ro.build.display.id" "Built by OceanTools+                           ${D_ID}  "
BUILD_PROP "$FIRM_DIR/$TARGET_DEVICE" "product" "ro.build.display.id" "Built by OceanTools+                            ${D_ID} "

BUILD_IMG "$FIRM_DIR/$TARGET_DEVICE" "$OUTPUT_FILESYSTEM" "$OUT_DIR"
