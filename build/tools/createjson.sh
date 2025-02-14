#!/bin/bash
#
# Copyright (C) 2025 WitAqua
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Usage: ./createjson.sh TARGET_DEVICE PRODUCT_OUT FILE_NAME

INPUT_FILE=./WitAquaOTA/data/devices.json

BUILDPROP="$2/system/build.prop"
NEW_BUILD_DATE=$(grep "ro.system.build.date.utc" "$BUILDPROP" | cut -d'=' -f2)
MD5=$(md5sum "$2/$3" | cut -d' ' -f1)
SIZE=$(stat -c "%s" "$2/$3")
VERSION=$(grep "ro.witaqua.build.version" "$BUILDPROP"  | cut -d'=' -f2)
TMP_FILE=$(mktemp)

jq --arg codename "$1" --argjson newDate "$NEW_BUILD_DATE" --arg filename "$3" --arg md5 "$MD5" --arg version "$VERSION" --argjson size "$SIZE" \
    '(.devices[] | select(.codename == $codename) | .downloadUrl) = "https://sourceforge.net/projects/witaqua/files/15.1/"+$codename+"/"+$filename+"/download" |
     (.devices[] | select(.codename == $codename) | .datetime) = $newDate |
     (.devices[] | select(.codename == $codename) | .filename) = $filename |
     (.devices[] | select(.codename == $codename) | .md5) = $md5 |
     (.devices[] | select(.codename == $codename) | .size) = $size |
     (.devices[] | select(.codename == $codename) | .version) = $version' \
    "$INPUT_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$INPUT_FILE"

echo "Updated $INPUT_FILE successfully."
