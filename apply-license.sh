#!/bin/sh
# Copyright © 2011 Bart Massey

LIBDIR=/usr/local/lib/apply-license

SHORT=true
HEURISTIC=false
RECURSIVE=false
# Get http://wiki.cs.pdx.edu/bartforge/sedit and
# turn this on if you have no GNU-compatible sed
#EDIT=sedit
EDIT="sed --in-place=.orig -f -"

# many temporary files are needed
CFILE=/tmp/al-cfile.$$; TMPFILES="$CFILE"
SCFILE=/tmp/al-scfile.$$; TMPFILES="$SCFILE"
LFILE=/tmp/al-lfile.$$; TMPFILES="$TMPFILES $LFILE"
CTMP=/tmp/al-copyright.$$; TMPFILES="$TMPFILES $CTMP"
LTMP=/tmp/al-license.$$; TMPFILES="$TMPFILES $LTMP"
SCTMP=/tmp/al-scopyright.$$; TMPFILES="$TMPFILES $SCTMP"
SHTMP=/tmp/al-sedh.$$; TMPFILES="$TMPFILES $SHTMP"
STTMP=/tmp/al-sedt.$$; TMPFILES="$TMPFILES $STTMP"
STMP=/tmp/al-sed.$$; TMPFILES="$TMPFILES $STMP"
SSTMP=/tmp/al-ssed.$$; TMPFILES="$TMPFILES $SSTMP"
PTMP=/tmp/al-presed.$$; TMPFILES="$TMPFILES $PTMP"
trap "rm -f $TMPFILES" 0 1 2 3 15

# deal with args
PGM="`basename $0`"
USAGE="$PGM: usage: $PGM [-s|-l|-h] [-r] [copying-file]"
COPYING="COPYING"
while true
do
  case $1 in
  -h) HEURISTIC=true; shift;;
  -l) HEURISTIC=false; SHORT=false; shift;;
  -s) HEURISTIC=false; SHORT=true; shift;;
  -r) RECURSIVE=true; shift;;
  -*) echo "$USAGE" >&2; exit 1;;
  *)  break;;
  esac
done
if [ $# -eq 1 ]
then
  COPYING=$1
  shift
fi
if [ $# -ne 0 ]
then
  echo "$USAGE" >&2
  exit 1
fi
if [ ! -f "$COPYING" ]
then
  echo "$PGM: can't find copying file $COPYING" >&2
  exit 1
fi

# create SCFILE and CFILE
sed '/^$/,$d' < $COPYING > $CFILE
if [ "`read WORD WORDS < $CFILE; echo $WORD`" '!=' 'Copyright' ]
then
  echo "$PGM: bogus copying file $COPYING" >&2
  exit 1
fi
COPYBASE="`basename \"$COPYING\"`"
cat $CFILE > $SCFILE
sed -e '1,/^$/d' -e '/^$/,$d' < $COPYING >>$SCFILE
echo "Please see the file $COPYBASE in the source" >>$SCFILE
echo "distribution of this software for license terms." >>$SCFILE
sed -e '1,/^$/d' -e '/^$/,$d' < $COPYING >>$CFILE
echo "Please see the end of this file for license terms." >> $CFILE

# create LFILE and measure its length for heuristic
sed -e '1,/^$/d' -e '1,/^$/d' < $COPYING > $LFILE
LFILELEN=`wc -l $LFILE | awk '{print $1;}'`
LFILELEN2=`expr $LFILELEN \* 2`

# Build substitution sed script
cat << EOF > $SHTMP
1 {
 h
 r $CTMP
 d
}
2 {
 i\

 x
 G
}
EOF
cat << EOF > $STTMP
\$ {
 a\

 r $LTMP
}
EOF
cat $SHTMP $STTMP > $STMP
cat << EOF > $SSTMP
1 {
 h
 r $SCTMP
 d
}
2 {
 i\

 x
 G
}
EOF

# Process a bunch of filetypes
for i in "$LIBDIR"/1/*.sh
do
    . $i
done

# XXX change head script to avoid first line
# in subsequent processing
echo "1 r $CTMP" > $SHTMP
cat $SHTMP $STTMP > $STMP
echo "1 r $SCTMP" > $SSTMP

for i in "$LIBDIR"/2/*.sh
do
    . $i
done

if $RECURSIVE
then
    if $HEURISTIC
    then
	FORMAT="-h"
    else
	if $SHORT
	then
	    FORMAT="-s"
	else
	    FORMAT="-l"
        fi
    fi
    case "$COPYING" in
    /*) ;;
    *)  COPYING=../"$COPYING" ;;
    esac
    ls |
    while read F
    do
	[ -d "$F" ] || continue
	( cd "$F"
	  $0 -r $FORMAT "$COPYING" )
    done
fi
