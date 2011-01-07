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
