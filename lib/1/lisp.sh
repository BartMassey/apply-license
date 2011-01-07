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