#!/bin/sh
CTMP=/tmp/al-copyright.$$
LTMP=/tmp/al-license.$$
STMP=/tmp/al-sed.$$
PTMP=/tmp/al-presed.$$
trap "rm -f $CTMP $LTMP $STMP $PTMP" 0 1 2 3 15

# set up
PGM="`basename $0`"
if [ $# -ne 1 ]
then
  echo "$PGM: usage: $PGM [mit]" >&2
  exit 1
fi
CFILE="$HOME/etc/copyright.txt"
if [ ! -f "$CFILE" ]
then
  echo "$PGM: unknown copyright" >&2
  exit 1
fi
LFILE="$HOME/etc/$1-license.txt"
if [ ! -f "$LFILE" ]
then
  echo "$PGM: unknown license $1" >&2
  exit 1
fi

# Build substitution sed script
cat << EOF > $STMP |
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
\$ {
 a\

 r $LTMP
}
EOF

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
  cat <<'EOF' > $PTMP
  1,$ s=^=# =
EOF
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sedit Makefile < $STMP
fi

# troff comments for manpage
ls *.man >/dev/null 2>&1
if [ $? = 0 ]
then
  cat <<'EOF' > $PTMP
  1,$ s=^=.\\" =
EOF
  sed -f $PTMP $CFILE > $CTMP
  sed -f $PTMP $LFILE > $LTMP
  sedit *.man < $STMP
fi

# create COPYING file if needed
if [ ! -f COPYING ]
then
  cat $CFILE > COPYING
  echo "" >> COPYING
  cat $LFILE > COPYING
fi
