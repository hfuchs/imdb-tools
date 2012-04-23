#!/bin/bash --

PREFIX=%PREFIX%
VERSION=%VERSION%
PATH=/bin:/usr/bin:$PREFIX/bin

declare -a files
set -e

syntax() {
   echo "Syntax: imdb-fxd <fxd-file> [options]"
   echo "Options:"
   echo "	--help -h - Print syntax and options."
   echo "	--imdbid -l <id> - Lookup by IMDB number."
   echo "	--filename -f <file> - Filename."
   echo "	--cachedir -e <dir> - Directory to cache results in."
   echo "	--download-cover -d - Download cover art."
   echo "	--no-net -o - Do not connect to IMDB (only search cache)."
   echo "	--version -v - Prints the version."
}


FXD="$1"
shift

IMDBOPTS="-a"

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
         IMDBOPTS="$IMDBOPTS\0-l\0$2"
         shift
         ;;
      --cachedir|-e)
         CACHE=$2
         IMDBOPTS="$IMDBOPTS\0-e\0$2"
         shift
         ;;
      --filename|-f)
         FILE=$2
         IMDBOPTS="$IMDBOPTS\0-f\0$2"
         shift
         ;;
      --no-net|-o)
         NONET=true
         IMDBOPTS="$IMDBOPTS\0-o"
         ;;
      --download-cover|-d)
         DOWNLOADCOVER=true
         IMDBOPTS="$IMDBOPTS\0-d"
         ;;
      *)
         echo "Unknown option: $1"
         syntax
         exit 1
         ;;   
   esac

   shift

done

if [[ "" == "$FXD" ]]; then
   syntax
   exit 1
fi
if [[ "" == "$FILE" && "" == "$IMDBID" ]]; then
   syntax
   exit 1
fi

IFS='
'
for i in `echo -e $IMDBOPTS | xargs -0 imdb get | grep -v "^ *$" | sed 's/: /="/;s/$/"/;s/^/export / '`;
do 
   eval $i; 
done

((j=0))
TRIMMEDFILE=`echo $filename | sed 's/\.[^\/]*$//'`
FILES="`echo $TRIMMEDFILE*`"
if [[ "$FILES" == "$TRIMMEDFILE*" ]]; then
   files=("$filename")
else
   for i in $TRIMMEDFILE*;
   do 
      files[$((j++))]=$i
   done
fi
   

cat > $FXD <<EOF
<?xml version='1.0' ?>
<freevo>
   <copyright>
      The information in this file are from the Internet Movie Database (IMDb).
      Please visit http://www.imdb.com for more informations.
      <source url='http://www.imdb.com/title/$id/'/>
   </copyright>
   <movie title="$title">
      <cover-img source='$coverart'>$coverart</cover-img>
      <video>
EOF
for (( k=0; k<j; k++)); 
do 
   echo "         <file id='f$k'>${files[$k]}</file>" >> $FXD
done
cat >> $FXD <<EOF
      </video>
      <info>
         <tagline>$tagline</tagline>
         <year>$year</year>
         <genre>$genre</genre>
         <plot>$plot</plot>
      </info>
   </movie>
</freevo>
EOF

