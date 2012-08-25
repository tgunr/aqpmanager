#!/bin/sh

# postrun.sh
#
# Created by Dave Carlton on 12/27/10.
# Copyright 2010 PolyMicro Systems. All rights reserved.


# Naming conventions
#NAME		= trailing file name
#DIR		= leading path components to a folder, no trailing slash
#PATH		= partial path component to construct URL or PATHNAME, no leading /
#URL		= $SITE/$DIR/$NAME
#PATHNAME	= full path to a file $DIR/$PATH/$FILE

set -o errexit
#set -x

source "$SRCROOT"/Misc/scripts/set_plist.sh
source "$SRCROOT"/Misc/scripts/development.sh
source "$SRCROOT"/Misc/scripts/deployment.sh
source "$SRCROOT"/Misc/scripts/asrelease.sh

echo "postrun.sh finished"
