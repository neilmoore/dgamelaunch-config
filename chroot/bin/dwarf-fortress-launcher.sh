#! /bin/bash
#

user=$1
#don't use / for end of path so find/replace works correctly

dfdir="%%CHROOT_DFDIR%%/df_linux"
userdir="%%CHROOT_DFDIR%%/df_$user"

#check to see if dir exist

if [ ! -d "$userdir" ]; then

  mkdir $userdir

  cd $userdir
  (cd $dfdir; find -type d ! -name .) |xargs mkdir -p

  cd $userdir
  for file in `find $dfdir -type f`
  do
      dfdir_path=$(dirname $file)
      user_path="${dfdir_path/$dfdir/$userdir}"
      cd $user_path
      ln  $dfdir_path/$(basename $file)
  done

  chmod -R 755 $user_path


  #then delete saved games
  rm -r $userdir/data/save
  mkdir $userdir/data/save

  #delete the gamelog.txt then touch the new one
  rm -r $userdir/gamelog.txt
  touch $userdir/gamelog.txt

  #do a regular copy of the data/init/init.txt file
  rm $userdir/data/init/init.txt
  cp $dfdir/data/init/init.txt $userdir/data/init/init.txt


fi

#now run the game
exec $userdir/df
#exec strace -v -s 4096 -ff -o /tmp/traces/trace.$$. $userdir/df 
 

