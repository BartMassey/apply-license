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