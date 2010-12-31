#!/bin/bash

# deployment.sh
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

if [[ "$CONFIGURATION" == 'Deployment' ]]; then
	echo "deployment.sh started"

	# Bases
	if [[ "" = "$SU_PATH" ]] ; then
		SITE_BASE="http://${SU_SITE}"
	else
		SITE_BASE="http://${SU_SITE}/${SU_PATH}"
	fi

	UPDATES_BASE="$SRCROOT"/updates

	# Variables

	#Paths
	RELEASE_NOTES_PATH="support/releasenotes"

	#Directories
	RELEASE_NOTES_DIR="$UPDATES_BASE"/"$RELEASE_NOTES_PATH"
	KEYCHAIN_DIR="$SRCROOT/Misc"

	# construct file names
	PRODUCT_NAME_OS=`echo "$PRODUCT_NAME" | tr " -" "_"`
	ARCHIVE_FILE=`echo "${PRODUCT_NAME}_${VERSION_NUMBER}_${BUILD_NUMBER}" | tr "-" "_"`
	RELEASE_NOTES="$ARCHIVE_FILE".html

	#Files
	KEYCHAIN_PRIVKEY_NAME="dsa_priv.pem"
	XML_UPDATE_FILE="$UPDATES_BASE"/updates.xml
	XML_CONFIG_FILE="$UPDATES_BASE"/supportConfig.php

	# URL's
	DOWNLOAD_BASE_URL="${SITE_BASE}/archives"
	RELEASENOTES_URL="${SITE_BASE}/$RELEASE_NOTES_PATH/$RELEASE_NOTES"
	DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILE"


	cat <<-EOF
		Prelease checklist
		- Update updates.xml with new version, paste in from clip board
		- Update release notes
		- Update known issues
		- Update URL for new version, copy next line
		- Turn on local hosts for product.com
		- Publish site
		- Verify site
		- Change build to release
		- Verify not using local hosts
		rsync -auv $UPDATES_BASE/ polymicrosystems.com:sites/staging/pdfgarden.com/updates/

	EOF

	PlistBuddy -c "Set :SUFeedURL http:\/\/$SU_SITE/$SU_PATH/$SU_FEED" "$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"
	
	pushd "$BUILT_PRODUCTS_DIR"
	ditto -ck --keepParent "$PRODUCT_NAME".app "$ARCHIVE_FILE".zip

	#cp "$PRODUCT_NAME".zip "$ARCHIVE_FILE"
	mv "$ARCHIVE_FILE".zip "$UPDATES_BASE"/archives/

	# see if release notes file for this release already exists, may be 2nd or more build so only do it once
#	RELEASE_NOTES_PATHNAME="$RELEASE_NOTES_DIR/$RELEASE_NOTES"
#	if [[ ! -e "$RELEASE_NOTES_PATHNAME" ]] ; then
#		echo "Creating $RELEASE_NOTES_PATHNAME"

		#cat >"$RELEASE_NOTES_PATHNAME" <<EOF
		#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 TRANSITIONAL//EN">
		#<html>
		#
		#    <head>
		#        <title>Version $VERSION_NUMBER Build $BUILD_NUMBER</title>
		#        <link href="../css/simplelist.css" type="text/css" rel="stylesheet" media="all">
		#    </head>
		#    <body>
		#        <p class="p1" align="center">$PRODUCT_NAME Version $VERSION_NUMBER Build $BUILD_NUMBER </p>
		#        <ul class="ul1">
		#            <li class="li1">Item1</li>
		#        </ul>
		#    </body>
		#</html>
		#EOF
		#fi
		#
	if [[ "$CONFIGURATION" != 'Development' ]] ; then
		FEEDER="$PRODUCT_NAME"
	else
		FEEDER="${PRODUCT_NAME}Local"
	fi

	TEMPFILE=`mktemp -t "$PRODUCT_NAME_OS"`

	cat > $TEMPFILE <<-EOF
		tell application "Feeder"
			set theFeedItemName to "$PRODUCT_NAME"
			set theFeed to folder item "$FEEDER" of root folder
			set feedVersion to "${VERSION_NUMBER}"
			set feedShortVersion to "${BUILD_NUMBER}"
			set feedTitle to "${PRODUCT_NAME}_${VERSION_NUMBER}_${BUILD_NUMBER}"
			set feedFile to POSIX file "${UPDATES_BASE}/archives/${ARCHIVE_FILE}.zip"
			set theFeed to null


			-- Find the feed we are using
			repeat with thisFeed in folder items of root folder
				set thisFeedName to name of thisFeed
				if thisFeedName is theFeedItemName then
					set theFeed to thisFeed
					exit repeat
				end if
			end repeat
		end tell

		if theFeed is not null then
			-- get the XML file and find our feed
			tell application "Feeder"
				set theFile to folder file of theFeed
			end tell
			set xmlContent to extract from XML theFile matching "/rss/channel/item/title" expression "text ()" without including output element
			set foundItem to null
			repeat with loopVar in contents of xmlContent
				set thisItem to loopVar as text
				if thisItem is feedTitle then
					set foundItem to thisItem
					exit repeat
				end if
			end repeat
			if foundItem is null then
				tell application "Feeder"
					make new feed item at theFeed with properties {feed:theFeed, sparkle short version:feedVersion, sparkle version:feedShortVersion, sparkle release notes:feedNotes, enclosure upload file:feedFile, item title:feedTitle}
				end tell
			end if
			tell application "Feeder"
				activate
				set latest to number of feed items of theFeed
			end tell
		end if
	EOF

	arch -i386 osascript $TEMPFILE
		#open -a "/Applications/Script Debugger/Script Debugger 4.5.app" $TEMPFILE
		#sed -e 's/http:\/\/updates.pdfgarden.com\//http:\/\/staging.pdfgarden.com\/updates\//' -i .bak $XML_UPDATE_FILE $XML_CONFIG_FILE
		#rsync -auv $UPDATES_BASE/ polymicrosystems.com:sites/staging/pdfgarden.com/updates/
	popd >&/dev/null
	echo "deployment.sh finished"
fi

