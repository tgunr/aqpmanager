#!/bin/sh

# asrelease.sh
#
# Created by Dave Carlton on 10/11/10.
# Copyright 2010 PolyMicro Systems. All rights reserved.

# Naming conventions
#NAME		= trailing file name
#DIR		= leading path components to a folder, no trailing slash
#PATH		= partial path component to construct URL or PATHNAME, no leading /
#URL		= $SITE/$DIR/$NAME
#PATHNAME	= full path to a file $DIR/$PATH/$FILE

set -o errexit
#set -x

if [[ "$CONFIGURATION" == 'ASRelease' ]]; then
echo "asrelease.sh started"

#Directories
RELEASE_NOTES_DIR="$UPDATES_BASE"/"$RELEASE_NOTES_PATH"
KEYCHAIN_DIR="$SRCROOT/Misc"
SITE_BASE=${SU_SITE}/${SU_PATH}
UPDATES_BASE="$SRCROOT"/updates

#Paths
RELEASE_NOTES_PATH="support/releasenotes"

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
PRODUCT_PLIST_NAME=`echo ${PRODUCT_NAME:identifier}|tr " " "_"`

set +o errexit
PlistBuddy -c "Print :CFBundleIdentifier" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH" &> /dev/null
if [[ $? == 0 ]] ; then 
    PlistBuddy -c "Set :CFBundleIdentifier com.polymicrosystems.mas.$PRODUCT_PLIST_NAME" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
fi

PlistBuddy -c "Print :SUCheckAtStartup" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH" &> /dev/null
if [[ $? == 0 ]] ; then 
	PlistBuddy -c "Delete :SUCheckAtStartup bool YES" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
	PlistBuddy -c "Delete :SUEnableSystemProfiling bool YES" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
	PlistBuddy -c "Delete :SUFeedURL string http:\/\/$SU_SITE/$SU_PATH/$SU_FEED" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
fi
set -o errexit

pushd "$BUILT_PRODUCTS_DIR"

pushd "$FRAMEWORKS_FOLDER_PATH"
if [[ -d "Sparkle.framework" ]] ; then
	rm -fr  "Sparkle.framework"
fi
popd

if [[ -e "$ARCHIVE_FILE".app ]] ; then
	rm -fr "$ARCHIVE_FILE".app
fi

cp -R "${PRODUCT_NAME}".app "$ARCHIVE_FILE".app
popd

#open "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

echo "asrelease.sh finished"
fi

