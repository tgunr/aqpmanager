#!/bin/sh

# development.sh
#
# Created by Dave Carlton on 10/11/10.
# Copyright 2010 PolyMicro Systems. All rights reserved.

# Naming conventions
#FILE		= trailing file name
#DIR		= leading path components to a folder, no trailing slash
#PATH		= partial path component to construct URL or PATHNAME, no leading /
#URL		= $SITE/$DIR/$NAME
#PATHNAME	= full path to a file $DIR/$PATH/$FILE

if [[ "$CONFIGURATION" == 'Development' ]]; then
    echo "development.sh started"
    echo "development.sh finished"
fi