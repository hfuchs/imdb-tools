#!/bin/bash --

#  IMDB Tools 
#  Copyright (c) 2006 Matthew Johnson
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License Version 2.
#
#  Full licence text is included in the COPYING file with this program.

# Manages IMDB details for films

PREFIX=%PREFIX%
VERSION=%VERSION%
PATH=/bin:/usr/bin:$PREFIX/bin

declare -a files

syntax() {
   echo "Syntax: imdb-get [options]"
   echo "Options:"
   echo "	--help -h - Print syntax and options."
   echo "	--imdbid -l <id> - Lookup by IMDB number."
   echo "	--search -s <string> - Search names."
   echo "	--filename -f <file> - Filename."
   echo "	--id -i - Print IMDB ID (Default)."
   echo "	--title -t - Print title."
   echo "	--director -D - Print director."
   echo "	--writer -w - Print writer."
   echo "	--genre -g - Print list of genres."
   echo "	--tag -T - Print tag line."
   echo "	--plot -p - Print plot."
   echo "	--year -y - Print year."
   echo "	--cast -C - Print cast."
   echo "	--rating -R - Print rating."
   echo "	--cover -c - Print cover art URI."
   echo "	--print-filename -m - Print filename."
   echo "	--all -a - Print all details."
   echo "	--cachedir -e <dir> - Directory to cache results in."
   echo "	--download-cover -d - Download cover art."
   echo "	--refresh -r - Refresh cache from IMDB."
   echo "	--rename -n - Rename file to film title."
   echo "	--update-filename -u - Update filename in cache data."
   echo "	--refresh-cache - Refreshes all details in the cache from IMDB."
   echo "	--no-net -o - Do not connect to IMDB (only search cache)."
   echo "	--prune-duplicates - Prunes duplicate file entries in the cache by deleting all but the most recently modified one."
   echo "	--version -v - Prints the version."
}

doItem() {
   TEMP=$1
   SAVE=$2
   SEDCMD=$3
   NAME=$4
   ID=$5
   VAR=$6

   if [[ "$REALREFRESH" == "true" ]]; then
      echo -n "$NAME: " >> $SAVE
      if [[ "$NAME" == "coverart" && "$DOWNLOADCOVER" == "true" && "$CACHE" != "" ]]; then
         CAURL=`< $TEMP sed -n "$SEDCMD"`
         curl -s -o "$CACHE/$ID.jpg" "$CAURL"
         echo "$CACHE/$ID.jpg" >> $SAVE
      else
         < $TEMP sed -n "$SEDCMD" | sed -e "s/\\([\"']\\)/\\\\\\1/g" | xargs >> $SAVE
      fi
   fi
   if [[ "$VAR" == "true" ]]; then
      grep "^$NAME:" $SAVE
   fi
}

doIMDB() {

   TEMP=`mktemp`
   files=("${files[@]}" "$TEMP")
   if [[ "$CACHE" != "" ]]; then
      mkdir -p $CACHE
      SAVE=$CACHE/$1.cache
      INDEX=$CACHE/index
      touch $INDEX
   else
      SAVE=`mktemp`
      files=("${files[@]}" "$SAVE")
      REALREFRESH=true
   fi

   if [[ "$FILENAME" == "" && -f "$SAVE" ]]; then
      FILENAME=`sed -n '/^filename:/s,filename: ,,p' "$SAVE"`
   fi
   if [[ "$REALREFRESH" == "true" || ! -f $SAVE || "$REFRESH" == "true" ]]; then
      if [[ "$NONET" == "true" ]];
      then
         return
      fi
      echo "Getting details from IMDB"  1>&2
      curl -s -o $TEMP http://www.imdb.com/title/$1/
      REALREFRESH=true
      if [[ "$FILENAME" != "" ]]; then
         echo "filename: $FILENAME" > $SAVE
      else
         echo -n > $SAVE
      fi
   fi

   if [[ "$FILENAME" != "" && "$PRINTFILE" != "" ]]; then
      echo "filename: $FILENAME"
   fi

   doItem $TEMP "$SAVE" "/^ *<title>/s,^.*$,$1,p" id $1 $ID
   doItem $TEMP "$SAVE" '/^ *<title>/s, *<title>\(.*\) ([^)]*).*<\/title>,\1,p' title $1 $TITLE
   doItem $TEMP "$SAVE" '/^ *<title>/s, *<title>.* (\([^)]*\)).*<\/title>,\1,p' year $1 $YEAR
   doItem $TEMP "$SAVE" '/Director[s]*:/,/<\/div>$/s,<[^<]*>,,gp' director $1 $DIRECTOR
   doItem $TEMP "$SAVE" '/Writer[s]*:/,/<\/div>$/s,<[^<]*>,,gp' writer $1 $WRITER
   doItem $TEMP "$SAVE" '/^<h4.*>Taglines:<\/h4>/,+1s,^\([^<]*\).*,\1,p' tagline $1 $TAG
   doItem $TEMP "$SAVE" '/^<p>$/,+1s,<[^<]*>,,gp' plot $1 $PLOT
   doItem $TEMP "$SAVE" '/Genre[s]*:/,/<\/div>$/{1,1d;s/<[^<]*>//g;s/&nbsp;/ /gp}' genre $1 $GENRE
   doItem $TEMP "$SAVE" '/<h2>Cast<\/h2>/,/<\/table>/{s,.*<a *href="/name/[^<]*>\(.*\)</a>,\1 as,p;s,.*<a *href="/character/[^<]*>\(.*\)</a>,\1\, ,p}' cast $1 $CAST
   doItem $TEMP "$SAVE" '/^<a.*href="\/media\/.*><img src=.*/s,.*<img src="\(.*\)",\1,p' coverart $1 $COVER
   doItem $TEMP "$SAVE" '/^<span class="rating-rating">.*<\/span>/s,<span class="rating-rating">\(.*\)<span>\/10<\/span><\/span>,\1,p' rating $1 $RATING

   if [[ "$RENAME" == "true" ]]; then
       OLDFILE="$FILENAME"
       if [[ "$OLDFILE" != "" ]]; then
          TITLE=`sed -n '/^title:/s,title: ,,p' $SAVE`
          NEWFILE="`dirname "$OLDFILE"`/$TITLE.`basename "$OLDFILE" | sed 's/[^\.]*\.\(.*\)$/\1/'`"
          if [[ "$OLDFILE" != "$NEWFILE" ]]; then
             echo "Renaming $OLDFILE to $NEWFILE" 1>&2
             mv -i "$OLDFILE" "$NEWFILE"
             sed -i "s%filename: .*%filename: $NEWFILE%" $SAVE
          fi
       fi
   fi

   if [[ "$UPDATEFILENAME" == "true" ]]; then
       OLDFILE=`sed -n '/^filename:/s,filename: ,,p' $SAVE`
       NEWFILE="`realpath "$FILENAME"`"
       if [[ "$OLDFILE" != "$NEWFILE" ]]; then
          sed -i "s%filename: .*%filename: $NEWFILE%" $SAVE
       fi
   fi

   if [[ ( "$UPDATEFILENAME" == "true" || "$REALREFRESH" == "true") && "$FILENAME" != "" ]]; then
      # update index
      NEWFILE="`realpath "$FILENAME"`"
      if [[ "$INDEX" != ""  ]]; then
         if grep "^$NEWFILE" $INDEX &>/dev/null ; then
            sed "s,^$NEWFILE.*$,$NEWFILE $1," -i $INDEX
         else
            echo "$NEWFILE $1" >> $INDEX
         fi
      fi
   fi
   
   if [[ "$CACHE" == "" ]]; then
      rm -f $SAVE
   fi
   rm -f $TEMP
   unset FILENAME
}

doFilename() {
   FILE=$1
   TRIMMEDFILE=`echo $FILE | sed 's/\.[^\/]*$//'`
   NAME=`basename "$TRIMMEDFILE"`
   if [[ "$CACHE" == "" ]]; then
      echo "No Cache, searching for filename \`$FILE'" 1>&2
      doSearch "$NAME"
   else
      if [[ "$DEBUG" == "true" ]]; then
         echo grep -r "$FILE" "$CACHE/index" '|' sed 's,.* \([^ ]*\)$,\1,'
      fi
      IMDB=`grep -r "$FILE" "$CACHE/index" | sed 's,.* \([^ ]*\)$,\1,'`
      if [[ "$IMDB" == "" ]]; then
         echo "Checking symlinks" 1>&2
         if [[ "$DEBUG" == "true" ]]; then
            echo grep -r "$(readlink -f "$FILE")" "$CACHE/index" '|' sed 's,.* \([^ ]*\)$,\1,'
         fi
         
         IMDB=`grep -r "$(readlink -f "$FILE")" "$CACHE/index" | sed 's,.* \([^ ]*\)$,\1,'`
      fi
      if [[ "$IMDB" == "" ]]; then
         echo "Checking without extensions" 1>&2
         if [[ "$DEBUG" == "true" ]]; then
            echo grep -r "$TRIMMEDFILE" "$CACHE/index" '|' sed 's,.* \([^ ]*\)$,\1, '
         fi
         IMDB=`grep -r "$TRIMMEDFILE" "$CACHE/index" | sed 's,.* \([^ ]*\)$,\1,'`
      fi
      if [[ "$IMDB" == "" ]]; then
         echo "Checking without path" 1>&2
         if [[ "$DEBUG" == "true" ]]; then
            echo grep -r "$NAME" "$CACHE/index" '|' sed 's,.* \([^ ]*\)$,\1,'
         fi
         IMDB=`grep -r "$NAME" "$CACHE/index" | sed 's,.* \([^ ]*\)$,\1,'`
      fi
      if [[ "$IMDB" == "" ]]; then
         echo "Cannot find file in cache, searching for filename \`$FILE'" 1>&2
         doSearch "$NAME"
      else
         doIMDB $IMDB
      fi
   fi
}

doSearch() {
   TEMP=`mktemp`
   files=("${files[@]}" "$TEMP")
   TEMPHEADERS=`mktemp`
   files=("${files[@]}" "$TEMPHEADERS")
   if [[ "$NONET" == "true" ]];
   then
      return
   fi
   curl -s "http://www.imdb.com/find?q=`echo $1 | sed 's/ /%20/g'`"  -o $TEMP -D $TEMPHEADERS
   if grep 'HTTP/1.1 302 Found' $TEMPHEADERS >/dev/null; then
      IMDB=`< $TEMPHEADERS sed -n '/^Location/s,Location: http://www.imdb.com/title/\([a-z0-9A-Z]*\)/.*,\1,p'`
      doIMDB $IMDB
   else
      TEMPCHOICES=`mktemp`
      files=("${files[@]}" "$TEMPCHOICES")
      < $TEMP tidy -iq -w 1000 2>/dev/null | sed 's/<t\([dr][^>]*\)>/<t\1>\n/g' | sed -n '/^ *<a href="\/title\/tt/s,^ *<a href="/title/\(tt[0-9]*\)/".*>\([^<]\+\)</a> \([^<]*\).*,\1%\2 \3,p' > $TEMPCHOICES
      (( i = 1 ))
      IFS='
'
      for l in `cat $TEMPCHOICES`; do
         echo -n "$i: "
         echo $l | cut -d% -f2
         (( i++ ))
      done
      
      echo -n "Select a Film: "
      read n </dev/tty
      IMDB=`head -n $n $TEMPCHOICES | tail -n1 | cut -d% -f1`
      if [[ "$IMDB" == "" ]]; then
         echo "Find aborted"
      else
         doIMDB $IMDB
      fi
      rm -f $TEMPCHOICES
   fi
   rm -f $TEMPHEADERS
   rm -f $TEMP
}

cleanup() {
   if [[ "${files[*]}" != "" ]]; then
      rm -f "${files[@]}"
   fi
}

if [[ -f /etc/imdbgetrc ]]; then
   . /etc/imdbgetrc
fi

if [[ -f $HOME/.imdbgetrc ]]; then
   . $HOME/.imdbgetrc
fi

trap cleanup INT TERM EXIT

while [[ "$1" != "" ]]; do

   case $1 in
      --version|-v)
         echo "IMDB Tools Version $VERSION"
         exit 1
         ;;
      --help|-h)
         syntax
         exit 1
         ;;
      --imdbid|-l)
         IMDBID=$2
         shift
         ;;
      --update-filename|-u)
         UPDATEFILENAME=true
         ;;
      --search|-s)
         SEARCH=$2
         shift
         ;;
      --cachedir|-e)
         CACHE=$2
         shift
         ;;
      --filename|-f)
         FILENAME=$2
         shift
         ;;
      --no-net|-o)
         NONET=true
         ;;
      --download-cover|-d)
         DOWNLOADCOVER=true
         ;;
      --refresh|-r)
         REFRESH=true
         ;;
      --rename|-n)
         RENAME=true
         ;;
      --cover|-c)
         COVER=true
         ;;
      --director|-D)
         DIRECTOR=true
         ;;
      --rating|-R)
	 RATING=true
         ;;
      --writer|-w)
         WRITER=true
         ;;
      --genre|-g)
         GENRE=true
         ;;
      --cast|-C)
         CAST=true
         ;;
      --tag|-T)
         TAG=true
         ;;
      --plot|-p)
         PLOT=true
         ;;
      --title|-t)
         TITLE=true
         ;;
      --id|-i)
         ID=true
         ;;
      --print-filename|-m)
         PRINTFILE=true
         ;;
      --year|-y)
         YEAR=true
         ;;
      --refresh-cache)
         REFRESHCACHE=true
         ;;
      --prune-duplicates)
         PRUNEDUPLICATES=true
         ;;
      --all|-a)
         COVER=true
         GENRE=true
         CAST=true
         DIRECTOR=true
         WRITER=true
         TAG=true
         PLOT=true	
         TITLE=true
         YEAR=true
	 RATING=true
         ID=true
         PRINTFILE=true
         ;;
      *)
         echo "Unknown option: $1"
         syntax
         exit 1
         ;;   
   esac

   shift

done

if [[ "$COVER" != "true" &&
      "$GENRE" != "true" &&
      "$DIRECTOR" != "true" &&
      "$CAST" != "true" &&
      "$WRITER" != "true" &&
      "$TAG" != "true" &&
      "$PLOT" != "true" &&
      "$RATING" != "true" &&
      "$TITLE" != "true" &&
      "$YEAR" != "true" &&
      "$ID" != "true" ]]; then
   ID=true
fi

if [[ "$IMDBID" != "" ]]; then

   doIMDB $IMDBID

elif [[ "$SEARCH" != "" ]]; then

   doSearch "$SEARCH"

elif [[ "$FILENAME" != "" ]]; then

   doFilename "$FILENAME"
   
elif [[ "$PRUNEDUPLICATES" != "" ]]; then

   if [[ "$CACHE" == "" ]]; then
      echo "Must specify --cachedir to prune cache."
      exit 1
   else
      cd "$CACHE"
      grep ^filename *cache | sort -k2 | uniq -f1 -D | cut -f1 -d: | xargs ls -t1 | sed -n '2,$p' | xargs rm
   fi

elif [[ "$REFRESHCACHE" != "" ]]; then

   REFRESH=true

   if [[ "$CACHE" == "" ]]; then
      echo "Must specify --cachedir to refresh cache."
      exit 1
   else
      for i in `ls $CACHE | grep cache$`; do
         doIMDB ${i%.cache}
      done
   fi
else
   echo "Must specify one of IMDB ID, filename or search string; or --refresh-cache"
   syntax
   exit 1
fi
