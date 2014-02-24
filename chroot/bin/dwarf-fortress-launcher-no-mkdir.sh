#! /bin/bash
#
#exec >>/logs/dwarf-fortress-launcher.log 2>&1
#echo `date`
#exec 2>>/tmp/debug.log


user=$1
#don't use / for end of path so find/replace works correctly

dfdir="%%CHROOT_DFDIR%%/df_linux"
userdir="%%CHROOT_DFDIR%%/df_$user"


#exec ./df
exec strace -v -s 4096 -ff -o /tmp/traces/trace.$$. $userdir/df 
 

