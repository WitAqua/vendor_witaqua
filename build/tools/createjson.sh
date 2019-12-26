#!/bin/bash
#
# Copyright (C) 2019-2023 crDroid Android Project
#			(C) 2025 WitAqua
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
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

#$1=TARGET_DEVICE, $2=PRODUCT_OUT, $3=FILE_NAME
existingOTAjson=./WitAquaOTA/data/$1.json
output=$2/$1.json

#cleanup old file
if [ -f $output ]; then
	rm $output
fi

echo "Generating JSON file data for OTA support..."

if [ -f $existingOTAjson ]; then
	#get data from already existing device json
	#there might be a better way to parse json yet here we try without adding more dependencies like jq
	maintainer=`grep -n "\"maintainer\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	oem=`grep -n "\"oem\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	device=`grep -n "\"device\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	filename=$3
	version=`echo "$3" | cut -d'-' -f5`
	v_max=`echo "$version" | cut -d'.' -f1 | cut -d'v' -f2`
	v_min=`echo "$version" | cut -d'.' -f2`
	version=`echo $v_max.$v_min`
	buildprop=$2/system/build.prop
	linenr=`grep -n "ro.system.build.date.utc" $buildprop | cut -d':' -f1`
	timestamp=`sed -n $linenr'p' < $buildprop | cut -d'=' -f2`
	md5=`md5sum "$2/$3" | cut -d' ' -f1`
	sha256=`sha256sum "$2/$3" | cut -d' ' -f1`
	size=`stat -c "%s" "$2/$3"`
	echo '{
	"response": [
		{
			"maintainer": "'$maintainer'",
			"oem": "'$oem'",
			"device": "'$device'",
			"filename": "'$filename'",
			"download": "https://sourceforge.net/projects/witaqua/files/'$version'/'$1'/'$3'/download",
			"timestamp": '$timestamp',
			"md5": "'$md5'",
			"sha256": "'$sha256'",
			"size": '$size',
			"version": "'$version'"
		}
	]
}' >> $output
else
	filename=$3
	version=`echo "$3" | cut -d'-' -f5`
	v_max=`echo "$version" | cut -d'.' -f1 | cut -d'v' -f2`
	v_min=`echo "$version" | cut -d'.' -f2`
	version=`echo $v_max.$v_min`
	buildprop=$2/system/build.prop
	linenr=`grep -n "ro.system.build.date.utc" $buildprop | cut -d':' -f1`
	timestamp=`sed -n $linenr'p' < $buildprop | cut -d'=' -f2`
	md5=`md5sum "$2/$3" | cut -d' ' -f1`
	sha256=`sha256sum "$2/$3" | cut -d' ' -f1`
	size=`stat -c "%s" "$2/$3"`

	echo '{
	"response": [
		{
			"maintainer": "''",
			"oem": "''",
			"device": "''",
			"filename": "'$filename'",
			"download": "https://sourceforge.net/projects/crdroid/files/'$1'/'$v_max'.x/'$3'/download",
			"timestamp": '$timestamp',
			"md5": "'$md5'",
			"sha256": "'$sha256'",
			"size": '$size',
			"version": "'$version'"
		}
	]
}' >> $output

	echo 'There is no official support for this device yet'
	echo 'Consider adding official support by reading the documentation at https://wiki.witaqua.org/developers/maintainership/requirements.html'
fi

echo ""
