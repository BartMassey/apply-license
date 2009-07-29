#!/bin/sh
# Copyright (c) 2006-2007 Bart Massey
# ALL RIGHTS RESERVED
# Please see the end of this file for license information.

SHORT=true
HEURISTIC=false
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
USAGE="$PGM: usage: $PGM [-s|-l|-h] [copying-file]"
COPYING="COPYING"
while true
do
  case $1 in
  -h) HEURISTIC=true; shift;;
  -l) HEURISTIC=false; SHORT=false; shift;;
  -s) HEURISTIC=false; SHORT=true; shift;;
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
cat $CFILE > $SCFILE
sed -e '1,/^$/d' -e '/^$/,$d' < $COPYING >>$SCFILE
echo "Please see the file $COPYING in the source" >>$SCFILE
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

# C comments for C-like code
for suff in c h y l css java
do
  ls *.$suff >/dev/null 2>&1
  if [ $? = 0 ]
  then
    cat <<'EOF' > $PTMP
    1 i\
/*
    1,$ s=^= * =
    $ a\
 */
EOF
    sed -f $PTMP $CFILE > $CTMP
    sed -f $PTMP $LFILE > $LTMP
    sed -f $PTMP $SCFILE > $SCTMP
    ls *.$suff |
    while read F
    do
      sed '2 !d; s/^ \* //; s/ .*$//' < $F | (
	read WORD
	if [ "$WORD" != Copyright ]
	then
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
	    $EDIT $F < $SSTMP
	  else
	    $EDIT $F < $STMP
	  fi
	fi
      )
    done
  fi
done

# sharp comments for Makefile
if [ -f Makefile ]
then
  echo '1,$ s=^=# =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed -f $PTMP $SCFILE > $SCTMP
  sed '1 !d; s/^# //; s/ .*$//' < Makefile | (
    read WORD
    if [ "$WORD" != Copyright ]
    then
      if $HEURISTIC
      then
	  if [ `wc -l Makefile | awk '{print $1;}'` -lt $LFILELEN2 ]
	  then
	     SHORT=true
	  else
	     SHORT=false
	  fi
      fi
      if $SHORT
      then
	$EDIT Makefile < $SSTMP
      else
	$EDIT Makefile < $STMP
      fi
    fi
  )
fi

# dnl comments for m4
ls *.m4 >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=dnl =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed -f $PTMP $SCFILE > $SCTMP
  ls *.m4 |
  while read F
  do
    sed '1 !d; s/^dnl //; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
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
	  $EDIT $F < $SSTMP
	  echo "1,/^$/s/^$/dnl/" | $EDIT $F
	else
	  $EDIT $F < $STMP
	  echo "1,/^$/s/^$/dnl/" | $EDIT $F
	fi
      fi
    )
  done
fi

# dash comments for haskell
ls *.hs >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=--- =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed -f $PTMP $SCFILE > $SCTMP
  ls *.hs |
  while read F
  do
    sed '1 !d; s/^--- //; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
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
	  $EDIT $F < $SSTMP
	else
	  $EDIT $F < $STMP
	fi
      fi
    )
  done
fi

# percent comments for TeX
ls *.tex >/dev/null 2>&1 ||
ls *.cls >/dev/null 2>&1 ||
ls *.sty >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=% =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed -f $PTMP $SCFILE > $SCTMP
  ls *.tex *.cls *.sty 2>/dev/null |
  while read F
  do
    sed '1 !d; s/^% //; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
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
	  $EDIT $F < $SSTMP
	else
	  $EDIT $F < $STMP
	fi
      fi
    )
  done
fi

# semi-semi comments for Emacs lisp and Common Lisp
for suff in lisp el
do
  ls *.$suff >/dev/null 2>&1
  if [ $? = 0 ]
  then
    echo '1,$ s=^=;; =' > $PTMP
    sed -f $PTMP $CFILE > $CTMP
    sed -f $PTMP $LFILE > $LTMP
    sed -f $PTMP $SCFILE > $SCTMP
    ls *.$suff |
    while read F
    do
      sed '1 !d; s/^;;*[ 	][ 	]*//; s/ .*$//' < $F | (
	read WORD
	if [ "$WORD" != Copyright ]
	then
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
	    $EDIT $F < $SSTMP
	  else
	    $EDIT $F < $STMP
	  fi
	fi
      )
    done
  fi
done

# // comments for JavaScript
ls *.js >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=// =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed -f $PTMP $SCFILE > $SCTMP
  ls *.js |
  while read F
  do
    sed '1 !d; s=^//*[ 	][ 	]*==; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
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
	  $EDIT $F < $SSTMP
	else
	  $EDIT $F < $STMP
	fi
      fi
    )
  done
fi

# XXX change head script to avoid first line
# in subsequent processing
echo "1 r $CTMP" > $SHTMP
cat $SHTMP $STTMP > $STMP
echo "1 r $SCTMP" > $SSTMP

# troff comments for manpage
ls *.man >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=.\\" =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed -f $PTMP $SCFILE > $SCTMP
  ls *.man |
  while read F
  do
    sed '2 !d; s/^\.\\" //; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
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
	  $EDIT $F < $SSTMP
	else
	  $EDIT $F < $STMP
	fi
      fi
    )
  done
fi

# sharp comments at line 2 for shell script, nickle, etc
for suff in sh awk 5c rb pl
do
  ls *.$suff >/dev/null 2>&1
  if [ $? = 0 ]
  then
    echo '1,$ s=^=# =' > $PTMP
    sed -f $PTMP $CFILE > $CTMP
    sed -f $PTMP $LFILE > $LTMP
    sed -f $PTMP $SCFILE > $SCTMP
    ls *.$suff |
    while read F
    do
      sed '2 !d; s/^# //; s/ .*$//' < $F | (
	read WORD
	if [ "$WORD" != Copyright ]
	then
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
	    $EDIT $F < $SSTMP
	  else
	    $EDIT $F < $STMP
	  fi
	fi
      )
    done
  fi
done

# // comments at line 2 for PHP
ls *.php >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=// =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed -f $PTMP $SCFILE > $SCTMP
  ls *.php |
  while read F
  do
    sed '2 !d; s=^// ==; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
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
	  $EDIT $F < $SSTMP
	else
	  $EDIT $F < $STMP
	fi
      fi
    )
  done
fi

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the
# Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall
# be included in all copies or substantial portions of the
# Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
