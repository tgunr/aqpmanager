#!/bin/sh

# release.sh
#
# Created by Dave Carlton on 10/11/10.
# Copyright 2010 PolyMicro Systems. All rights reserved.

set -o errexit
if [[ "$CONFIGURATION" == 'Release' ]]; then
#set -x

exit 0
# Variables

# Get the build number from the development.xcconfig and set the release.xccofig file
# This way, we stay at a constant build number until we go back to debugging
BUILD_NUMBER=`head -n 1 "$SRCROOT/Misc/development.xcconfig" | sed -e 's/BUILD_NUMBER = //'`
sed -e "s/BUILD_NUMBER = .*/BUILD_NUMBER = $BUILD_NUMBER/" -i ""  "$SRCROOT/Misc/release.xcconfig"

# Have to update the application Info.plist so it knows we are on this build
PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
#PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
#PlistBuddy -c "Set :SUFeedURL $SU_SITE/$SU_FEED_URL" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

# Read back values to make sure they were set
RELEASE_BUILD=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleVersion)
RELEASE_VERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Info" CFBundleShortVersionString)

# Naming conventions
#NAME		= trailing file name
#DIR		= leading path components to a folder, no trailing slash
#PATH		= partial path component to construct URL or PATHNAME, no leading /
#URL		= $SITE/$DIR/$NAME
#PATHNAME	= full path to a file $DIR/$PATH/$FILE

# Directories
SITE_BASE=${SU_SITE}/${SU_PATH}
UPDATES_BASE="$SRCROOT"/updates

#Paths
RELEASE_NOTES_PATH="support/releasenotes"

#Directories
RELEASE_NOTES_DIR="$UPDATES_BASE"/"$RELEASE_NOTES_PATH"
KEYCHAIN_DIR="$SRCROOT/Misc"

# construct file names
ARCHIVE_FILE=`echo "${PRODUCT_NAME}_${VERSION_NUMBER}_${RELEASE_BUILD}" | tr "-" "_"`
RELEASE_NOTES="$ARCHIVE_FILE".html

#Files
KEYCHAIN_PRIVKEY_NAME="dsa_priv.pem"
XML_UPDATE_FILE="$UPDATES_BASE"/updates.xml
XML_CONFIG_FILE="$UPDATES_BASE"/supportConfig.php

# URL's
DOWNLOAD_BASE_URL="http://${SITE_BASE}/archives"
RELEASENOTES_URL="http://${SITE_BASE}/$RELEASE_NOTES_PATH/$RELEASE_NOTES"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILE"

WD=$PWD
pushd "$BUILT_PRODUCTS_DIR"
rm -fr ${PROGRAM_FILE}_*.*
cp -R "${PRODUCT_NAME}".app "$ARCHIVE_FILE".app
ditto -ck --keepParent "$PRODUCT_NAME".app "$ARCHIVE_FILE".zip
mv "$ARCHIVE_FILE".zip "$UPDATES_BASE"/archives/
popd


# see if release notes file for this release already exists, may be 2nd or more build so only do it once
RELEASE_NOTES_PATHNAME="$RELEASE_NOTES_DIR/$RELEASE_NOTES"

cat <<EOF
tell application "Feeder"
	activate
    set theFeed to folder item "${PRODUCT_NAME}" of root folder
    set feedVersion to "${VERSION_NUMBER}"
    set feedShortVersion to "${BUILD_NUMBER}"
    set feedTitle to "${PRODUCT_NAME}_${VERSION_NUMBER}_${BUILD_NUMBER}"
    set feedFile to POSIX file "${UPDATES_BASE}/archives/${ARCHIVE_FILE}.zip"
	set feedLink to POSIX file "${RELEASE_NOTES_PATHNAME}"
    make new feed item at theFeed with properties {feed:theFeed, sparkle short version:feedVersion, sparkle version:feedShortVersion, item link:feedLink, enclosure upload file:feedFile, item title:feedTitle} 
	set latest to number of feed items of theFeed
end tell
EOF

cat | osascript <<EOF
tell application "Feeder"
	activate
    set theFeed to folder item "${PRODUCT_NAME}" of root folder
    set feedVersion to "${VERSION_NUMBER}"
    set feedShortVersion to "${BUILD_NUMBER}"
    set feedTitle to "${PRODUCT_NAME}_${VERSION_NUMBER}_${BUILD_NUMBER}"
    set feedFile to POSIX file "${UPDATES_BASE}/archives/${ARCHIVE_FILE}.zip"
	set feedLink to POSIX file "${RELEASE_NOTES_PATHNAME}"
    make new feed item at theFeed with properties {feed:theFeed, sparkle short version:feedVersion, sparkle version:feedShortVersion, item link:feedLink, enclosure upload file:feedFile, item title:feedTitle} 
	set latest to number of feed items of theFeed
end tell
EOF

#echo rsync -auv "$UPDATES_DIR"/ polymicrosystems.com:sites/pdfgarden.com/updates/

echo "release.sh finished"

fi