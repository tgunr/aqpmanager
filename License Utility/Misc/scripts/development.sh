#!/bin/sh

# development.sh
#
# Created by Dave Carlton on 10/11/10.
# Copyright 2010 PolyMicro Systems. All rights reserved.

### If not releasing increment build number
if [[ "$CONFIGURATION" == 'Development' ]]; then

echo "BUILD_NUMBER: $BUILD_NUMBER"
echo "VERSION_NUMBER: $VERSION_NUMBER"
echo "SU_FEED: $SU_SITE/$SU_PATH/$SU_FEED" | sed -e 's?//?/?'
OLD_BUILD_NUMBER=$BUILD_NUMBER
/usr/bin/perl -pe 's/(BUILD_NUMBER = )(\d+)/$1.($2+1)/eg' -i "$SRCROOT/Misc/debug.xcconfig"
BUILD_NUMBER=`head -n 1 "$SRCROOT/Misc/debug.xcconfig" | sed -e 's/BUILD_NUMBER = //'`
PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
PlistBuddy -c "Set :SUFeedURL http:\/\/$SU_SITE/$SU_PATH/$SU_FEED" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

# Naming conventions
#NAME		= trailing file name
#DIR		= leading path components to a folder, no trailing slash
#PATH		= partial path component to construct URL or PATHNAME, no leading /
#URL		= $SITE/$DIR/$NAME
#PATHNAME	= full path to a file $DIR/$PATH/$FILE

# Read back values to make sure they were set
RELEASE_BUILD=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleVersion)
RELEASE_VERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleShortVersionString)

echo "RELEASE_BUILD: $RELEASE_BUILD"
echo "RELEASE_VERSION: $RELEASE_VERSION"

echo "development.sh finished"
fi

#set -x
#	if [ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist" ]; then
#		if [ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1" ]; then
#		    echo "Removing prefs"
#		    /bin/rm "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist"
#		else
#		    echo "Moving prefs aside"
#		    /bin/mv "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist" "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1"
#		fi
#	fi
#elif [[ -e "$HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1" ]]; then
#		echo "Old prefs still exists at $HOME/Library/Preferences/com.polymicrosystems.pdfgarden.plist.1"
