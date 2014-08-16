#!/bin/bash
# Copyright © 2011 Bart Massey
# [This software is released under the "MIT License"]
# Please see the file COPYING in the source
# distribution of this software for license terms.

LIBDIR=/usr/local/lib/apply-license

SHORT=true
HEURISTIC=false
RECURSIVE=false
DELETE=false
# Get http://wiki.cs.pdx.edu/bartforge/sedit and
# turn this on if you have no GNU-compatible sed
#EDIT=sedit
EDIT="sed --in-place=.orig -f -"
# If you are using sedit, then there is no
# convenient way to edit without backing
# up, so comment this out and lose the "-d"
# capability.
EDITX="sed --in-place -f -"

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
if [ "$EDITX" = "" ]
then
  USAGE="$PGM: usage: $PGM [-s|-l|-h] [-r] [copying-file]"
else
  USAGE="$PGM: usage: $PGM [-s|-l|-h] [-r] [-d] [copying-file]"
fi  
COPYING="COPYING"
while true
do
  case $1 in
  -h) HEURISTIC=true; shift;;
  -l) HEURISTIC=false; SHORT=false; shift;;
  -s) HEURISTIC=false; SHORT=true; shift;;
  -r) RECURSIVE=true; shift;;
  -d) if [ "$EDITX" = "" ]
      then
        echo "$USAGE" >&2
	exit 1
      else
        DELETE=true; shift
      fi
      ;;
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
 /^#!/p
 /^#!/!H
 r $CTMP
 d
}
2 {
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
 /^#!/p
 /^#!/!H
 r $SCTMP
 d
}
2 {
 x
 G
}
EOF

function edit1 {
  F="$1"
  if $HEURISTIC
  then
    if [ `wc -l $F | awk '{print $1;}'` -lt $LFILELEN2 ]
    then
      SHORT=true
    else
      SHORT=false
    fi
  fi
  if $SHORT
  then
    ETMP=$SSTMP
  else 
    ETMP=$STMP
  fi
  if head -2 $F | grep -qiw copyright
  then
    if $DELETE
    then
      $EDIT $F <<'EOF'
3,${p;d}
/\<[Cc][Oo][Pp][Yy][Rr][Ii][Gg][Hh][Tt]\>/d
EOF
      $EDITX $F < $ETMP
    fi
  else
    $EDIT $F < $ETMP
  fi
}

function makestuff {
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed -f $PTMP $SCFILE > $SCTMP
}

function editfiles {
  for F in $*
  do
    [ -f "$F" ] && makestuff && edit1 $F
  done
}

function edit {
  for suff in $*
  do
    ls *.$suff >/dev/null 2>&1
    if [ $? = 0 ]
    then
      makestuff
      ls *.$suff |
      while read F
      do
	edit1 $F
      done
    fi
  done
}

# Process a bunch of filetypes

# C comments for C-like code
cat <<'EOF' > $PTMP
1 i\
/*
1,$ s=^= * =
$ a\
 */
EOF
edit c h y l css java

# dash comments for Haskell
echo '1,$ s=^=-- =' > $PTMP
edit hs cabal

# // comments for JavaScript
echo '1,$ s=^=// =' > $PTMP
edit js

# semi comments for Emacs lisp, Common Lisp, Scheme
echo '1,$ s=^=; =' > $PTMP
edit lisp el scm

# dnl comments for m4
echo '1,$ s=^=dnl =' > $PTMP
edit m4

# sharp comments for Makefile
echo '1,$ s=^=# =' > $PTMP
editfiles Makefile makefile

# percent comments for TeX and Matlab/Octave
echo '1,$ s=^=% =' > $PTMP
edit tex cls sty m

## XXX change head script to avoid first line
## in subsequent processing
#echo "1 r $CTMP" > $SHTMP
#cat $SHTMP $STTMP > $STMP
#echo "1 r $SCTMP" > $SSTMP

# // comments for PHP
echo '1,$ s=^=// =' > $PTMP
edit php

# sharp comments for shell script, nickle, etc
echo '1,$ s=^=# =' > $PTMP
edit sh awk 5c rb pl py

# troff comments for manpage
echo '1,$ s=^=.\\" =' > $PTMP
edit man

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
  $DELETE && DFLAG="-d"
  case "$COPYING" in
  /*) ;;
  *)  COPYING=../"$COPYING" ;;
  esac
  ls |
  while read F
  do
    [ -d "$F" ] || continue
    ( cd "$F"
      $0 -r $FORMAT $DFLAG "$COPYING" )
  done
fi
