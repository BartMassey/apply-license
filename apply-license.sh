#!/bin/sh

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
NOFORCE="true"
COPYING="COPYING"
if [ $# -ge 1 ] && [ "$1" = "-f" ]
then
  NOFORCE="false"
  shift
fi
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
if $NOFORCE && [ -f .apply-license ]
then
  echo "$PGM: license already applied" >&2
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
  sedit *.[chyl] < $STMP
fi

# sharp comments for Makefile
if [ -f Makefile ]
then
  echo '1,$ s=^=# =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sedit Makefile < $STMP
fi

# troff comments for manpage
ls *.man >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=.\\" =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sedit *.man < $STMP
fi

# XXX change head script for scripts to
# avoid #! line
echo "1 r $CTMP" > $SHTMP
cat $SHTMP $STTMP > $STMP

# sharp comments at line 2 for shell script
ls *.sh >/dev/null 2>&1
if [ $? = 0 ]
then
  echo '1,$ s=^=# =' > $PTMP
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sedit *.sh < $STMP
fi

# mark license as applied
echo "License information applied by apply-license" > .apply-license
