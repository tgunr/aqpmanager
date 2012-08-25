#!/bin/sh

# set_plist.sh
#
# Created by Dave Carlton on 12/27/10.
# Copyright 2010 PolyMicro Systems. All rights reserved.

set -o errexit
set -x

echo "Starting set_plist.sh"

### If not releasing, increment build number
if [[ "$CONFIGURATION" == "Development" ]]; then

	echo "BUILD_NUMBER: $BUILD_NUMBER"
	echo "VERSION_NUMBER: $VERSION_NUMBER"
	echo "SU_FEED: $SU_SITE/$SU_PATH/$SU_FEED" | sed -e 's?//?/?'
	OLD_BUILD_NUMBER=$BUILD_NUMBER
	/usr/bin/perl -pe 's/(BUILD_NUMBER = )(\d+)/$1.($2+1)/eg' -i "$SRCROOT/Misc/development.xcconfig"
	BUILD_NUMBER=`head -n 1 "$SRCROOT/Misc/development.xcconfig" | sed -e 's/BUILD_NUMBER = //'`

fi

#open "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

#PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONFIGURATION_BUILD_DIR/$INFOPLIST_PATH"
#PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$CONFIGURATION_BUILD_DIR/$INFOPLIST_PATH"

# Read back values to make sure they were set
#RELEASE_BUILD=$(defaults read "$CONFIGURATION_BUILD_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleVersion)
#RELEASE_VERSION=$(defaults read "$CONFIGURATION_BUILD_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleShortVersionString)

echo "RELEASE_BUILD: $RELEASE_BUILD"
echo "RELEASE_VERSION: $RELEASE_VERSION"

echo "Finished set_plist.sh"