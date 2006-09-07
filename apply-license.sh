#!/bin/sh
# Copyright (c) 2006 Bart Massey
# All Rights Reserved
# Please see the end of this file for license information.

# many temporary files are needed
CFILE=/tmp/al-cfile.$$; TMPFILES="$CFILE"
LFILE=/tmp/al-lfile.$$; TMPFILES="$TMPFILES $LFILE"
CTMP=/tmp/al-copyright.$$; TMPFILES="$TMPFILES $CTMP"
LTMP=/tmp/al-license.$$; TMPFILES="$TMPFILES $LTMP"
SHTMP=/tmp/al-sedh.$$; TMPFILES="$TMPFILES $SHTMP"
STTMP=/tmp/al-sedt.$$; TMPFILES="$TMPFILES $STTMP"
STMP=/tmp/al-sed.$$; TMPFILES="$TMPFILES $STMP"
PTMP=/tmp/al-presed.$$; TMPFILES="$TMPFILES $PTMP"
trap "rm -f $TMPFILES" 0 1 2 3 15

# deal with args
PGM="`basename $0`"
USAGE="$PGM: usage: $PGM [-f] [copying-file]"
COPYING="COPYING"
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
  echo "$PGM: can't find copying file" >&2
  exit 1
fi

# create CFILE and LFILE
sed '/^$/,$d' < $COPYING > $CFILE
echo "Please see the end of this file for license information." >> $CFILE
sed -e '1,/^$/d' -e '1,/^$/d' < $COPYING > $LFILE

# Build substitution sed script
cat << EOF > $SHTMP |
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
cat << EOF > $STTMP |
\$ {
 a\

 r $LTMP
}
EOF
cat $SHTMP $STTMP > $STMP

# C comments for C-like code
ls *.[chyl] >/dev/null 2>&1
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
  ls *.[chyl] |
  while read F
  do
    sed '2 !d; s/^ \* //; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
	sedit $F < $STMP
      fi
    )
  done
fi

# sharp comments for Makefile
if [ -f Makefile ]
then
  echo '1,$ s=^=# =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sed '1 !d; s/^# //; s/ .*$//' < $Makefile | (
    read WORD
    if [ "$WORD" != Copyright ]
    then
      sedit Makefile < $STMP
    fi
  )
fi

# XXX change head script to avoid first line
# in subsequent processing
echo "1 r $CTMP" > $SHTMP
cat $SHTMP $STTMP > $STMP

# troff comments for manpage
ls *.man >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=.\\" =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  ls *.man |
  while read F
  do
    sed '2 !d; s/^\.\\" //; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
	sedit $F < $STMP
      fi
    )
  done
fi

# sharp comments at line 2 for shell script
ls *.sh >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=# =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  ls *.sh |
  while read F
  do
    sed '2 !d; s/^# //; s/ .*$//' < $F | (
      read WORD
      if [ "$WORD" != Copyright ]
      then
        sedit $F < $STMP
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
