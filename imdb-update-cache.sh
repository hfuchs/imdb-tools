#!/bin/bash --

#  IMDB Tools 
#  Copyright (c) 2006 Matthew Johnson
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License Version 2.
#
#  Full licence text is included in the COPYING file with this program.

#
# Updates the imdbget cache for a given directory

PREFIX=%PREFIX%
VERSION=%VERSION%
PATH=/bin:/usr/bin:$PREFIX/bin

if [[ "$1" == "" || "$1" == "--help" ]]; then
   echo "Syntax: imdb-update-cache <directory>"
   exit 1
fi

if [[ "$1" == "--version" ]]; then
   echo "IMDB Tools Version $VERSION"
   exit 1
fi

DIR=$1
IFS='
'

for i in `find $DIR -type f`;
do
   imdb-get -f "$i"
done
