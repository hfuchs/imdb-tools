#!/bin/bash --

#  IMDB Tools 
#  Copyright (c) 2006 Matthew Johnson
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License Version 2.
#
#  Full licence text is included in the COPYING file with this program.

#
# Wrapper that calls the other scripts

PREFIX=%PREFIX%
VERSION=%VERSION%
PATH=/bin:/usr/bin:$PREFIX/bin

if [[ "$1" == "" || "$1" == "--help" ]]; then
   echo "Syntax: imdb [get|link|rename|update-cache|fxd] <command options>"
   echo "   see imdb-get, imdb-link, imdb-rename, imdb-update-cache, imdb-fxd for details of command options"
   exit 1
fi
if [[ "$1" == "--version" ]]; then
   echo "IMDB Tools Version $VERSION"
   exit 1
fi

PROGRAM=$1
shift

case $PROGRAM in
   get|link|rename|update-cache|fxd)
      imdb-$PROGRAM "$@"
      ;;
   *)
      echo "Syntax: imdb [get|link|rename|update-cache|fxd] <command options>"
      echo "   see imdb-get, imdb-link, imdb-rename, imdb-update-cache, imdb-fxd for details of command options"
      exit 1
      ;;
esac
