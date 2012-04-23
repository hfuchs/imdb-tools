#!/bin/bash --

#  IMDB Tools 
#  Copyright (c) 2006 Matthew Johnson
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License Version 2.
#
#  Full licence text is included in the COPYING file with this program.

#
# Symlinks files based on IMDB Genres

PREFIX=%PREFIX%
VERSION=%VERSION%
PATH=/bin:/usr/bin:$PREFIX/bin

if [[ "$2" == "" || "$1" == "--help" ]]; then
   echo "Syntax: imdb-link <target> <files...>"
   exit 1
fi

if [[ "$1" == "--version" ]]; then
   echo "IMDB Tools Version $VERSION"
   exit 1
fi

TARGET=$1
shift

while [[ "$1" != "" ]];
do
   FILE=`realpath "$1"`
   GENRES=$(imdb-get -f "$FILE" -g | cut -d: -f2)
   IFS=' /|'
   for i in $GENRES; do
      mkdir -p "$TARGET/$i"
      if [[ ! -e "$TARGET/$i/`basename "$FILE"`" ]]; then
         ln -s "$FILE" "$TARGET/$i/"
      fi
   done
   shift
done
