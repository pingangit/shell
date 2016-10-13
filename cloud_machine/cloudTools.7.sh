#!/bin/bash
# chkconfig: 2345 85 12
# description: This is cloudTools load
# HOME:/cloud-tools
# 

basePath=/opt/cloud
source $basePath/scripts/func.sh
. /etc/init.d/functions

prog=cloudTools
lockfile=/var/lock/subsys/$prog

toolFlag=$basePath/scripts/.createList

[ ! -e $toolFlag ] && touch $toolFlag
[ ! -d $basePath/scripts/tmp ] && mkdir -p $basePath/scripts/tmp

#vrStatus && refreshUserData  1>&2 > /dev/null 

runScript() {
    scripts=$(buildScripts ${1} ${2})
    for i in $scripts;do
       sh $scripts
       logger "cloudTool:$1:$2:exit $?"
    done
}

start() {
   # init will be run at every time before start when the vm's startup, 
   # and the x0 status is record by createList.
   #

   vrStatus && refreshUserData  1>&2 > /dev/null; 
   [ `cat $basePath/scripts/user-data|wc -l` -eq 0 ] && logger "cloudTool.start refreshUserData fail" && exit 1
   whenCreate=$(buildScripts whenCreate)
   whenStart=$(buildScripts whenStart)

   installed=$(grep -vE "^#|^$" $toolFlag | xargs echo | sed s/" "/'|'/g)
   logger "cloudTool:Get Installed: $installed"

   tools=($(getTools))
   logger "cloudTool:Get UserData's Tools: ${tools[@]}"

   for i in "${tools[@]}" 
   do
      >$basePath/scripts/tmp/subscprit.${i}
      if ! grep -w $i $toolFlag;then
         ls $whenCreate | grep -vwE "$installed " |grep -w $i > $basePath/scripts/tmp/subscprit.${i}
         [ $? == 0 ] &&  echo "[ \$? == 0 ] &&  echo $i >> $toolFlag || logger \"cloudTool:$i create failed\"" \
          >> $basePath/scripts/tmp/subscprit.${i}
      fi
      ls $whenStart | grep $i >> $basePath/scripts/tmp/subscprit.${i} \
      && echo "[ \$? != 0 ] &&  logger \"cloudTool:$i start failed\"" >> \
      $basePath/scripts/tmp/subscprit.${i}
      sh $basePath/scripts/tmp/subscprit.${i} &  >/dev/null
   done
}

test() {
   cd $basePath/scripts
   cp ./test/user-data ./
   >$toolFlag

   case $1 in 
   start)
        echo "Start whenCreate and Start testing ..."
        start
    touch $lockfile
          ;;
   stop)
       echo "Start whenStop testing ..."
       runScript "whenStop"
          ;;
   clean)
       find ./ -maxdepth 1 -type d |grep -vEw "test|./$" | xargs rm -r
       rm -f /etc/chef/client*
           rm -f /etc/chef/*.pem
           rm -f $lockfile
          ;;
      *)
       echo "This test juest for start|stop|clean"
         ;;
   esac
}

case $1 in
   start)
         echo "Start $prog:"
         start
         touch $lockfile
            ;;
   stop)
         echo "Stopping $prog:"
         runScript "whenStop" 
         rm -f $lockfile
            ;;
   test)
          test $2
            ;;
      *)
          echo "You can run create force, to clear the create Tools record."
          echo $"Usage: $prog {start|stop|test}"
            ;;
esac
