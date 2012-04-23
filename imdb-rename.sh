#!/bin/bash --

#  IMDB Tools 
#  Copyright (c) 2006 Matthew Johnson
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License Version 2.
#
#  Full licence text is included in the COPYING file with this program.

#
# Renames files based on IMDB titles from the cache

PREFIX=%PREFIX%
VERSION=%VERSION%
PATH=/bin:/usr/bin:$PREFIX/bin

if [[ "$1" == "" || "$1" == "--help" ]]; then
   echo "Syntax: imdb-rename <files>"
   exit 1
fi

if [[ "$1" == "--version" ]]; then
   echo "IMDB Tools Version $VERSION"
   exit 1
fi

while [[ "$1" != "" ]];
do
   imdb-get -f "`realpath "$1"`" -n
   shift
done
