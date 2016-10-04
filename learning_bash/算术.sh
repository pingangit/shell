

#============
#mul2.sh
#============

#!/bin/bash
#
declare -i i=1
declare -i j=1

while [ $j -le 9 ]; do
    while [ $i -le $j ]; do
        echo -e -n "${i}X${j}=$[$i*$j]\t"
        let i++
    done
    echo
    let i=1
    let j++
done


# 用 until 实现
declare -i j=1
declare -i i=1

until [ $j -gt 9 ]; do
    until [ $i -gt $j ]; do
        echo -n -e "${i}X${j}=$[$i*$j]\t"
        let i++
    done
    echo
    let i=1
    let j++
done

#============
#mul.sh
#============

#!/bin/bash


for j in {1..9}; do
    for i in $(seq 1 $j); do
        echo -e -n "${i}X${j}=$[$i*$j]\t"
    done
    echo
done

#============
#ping2.sh
#============

#!/bin/bash
#

declare -i i=1
declare -i uphosts=0
declare -i downhosts=0
net='202.69.28'

while [ $i -le 20 ]; do
    if ping -c 1 -w 1 $net.$i &> /dev/null; then
        echo "$net.$i is up."
        let uphosts++
    else
        echo "$net.$i is down."
        let downhosts++
    fi
    let i++
done

echo "Up hosts: $uphosts."
echo "Down hosts: $downhosts."

#============
#rand.sh
#============

#!/bin/bash
#
declare -i max=0
declare -i min=0
declare -i i=1

rand=$RANDOM
echo $rand

max=$rand
min=$rand

while [ $i -le 9 ]; do
    rand=$RANDOM
    echo $rand
    if [ $rand -gt $max ]; then
        max=$rand
    fi
    if [ $rand -lt $min ]; then
        min=$rand
    fi
    let i++
done


echo "MAX: $max."
echo "MIN: $min."

#============
#summary.sh
#============

#!/bin/bash
#
declare -i sum=0
declare -i i=1

while [ $i -le 100 ]; do
    let sum+=$i
    let i++
done

echo "$i"
echo "Summary: $sum"


# 用 until 实现
declare -i i=1
declare -i sum=0

until [ $i -gt 100 ]; do
    let sum+=$i
    let i++
done

echo "Sum: $sum"


#============
#useradd.sh
#============

#!/bin/bash
#

declare -i i=1
declare -i users=0

while [ $i -le 10 ]; do
    if ! id user$i &> /dev/null; then
        useradd user$i
        echo "Add user: user$i."
        let users++
    fi
    let i++
done

echo "Add $users users."


#=========
#even.sh
#=========

#!/bin/bash
#

declare -i i=0
declare -i sum=0

until [ $i -gt 100 ]; do
    let i++
    if [ $[$i%2] -eq 1 ]; then
        continue
    fi
    let sum+=$i
done

echo "Even sum: $sum"



#===========
#user_log.sh
#===========
#!/bin/bash
#

read -p "Enter a user name: " username

while true; do
    if who | grep "^$username" &> /dev/null; then
        break
    fi
    sleep 3
done
echo "$username logged on." >> /tmp/user.log



# 改写
#!/bin/bash
#

read -p "Enter a user name: " username
while ! who | grep "^$username" &> /dev/null; do
        break
    sleep 3
done
echo "$username logged on." >> /tmp/user.log

# 改写
#!/bin/bash
#

read -p "Enter a user name: " username
until who | grep "^$username" &> /dev/null; do
        break
    sleep 3
done
echo "$username logged on." >> /tmp/user.log


#=========
#evenid.sh
#=========
#!/bin/bash

while read line; do
    if [ $[$(echo $line | cut -d: -f3) % 2] -eq 0 ]; then
        echo -e -n "username: $(echo $line | cut -d: -f1)\t"
        echo "uid: $(echo $line | cut -d: -f3)"
    fi
done < /etc/passwd


#========
#sum2.sh
#========
# for 的特殊格式
#!/bin/bash
#
declare -i sum=0

for ((i=1;i<=100;i++)); do
    let sum+=$i
done

echo "Sum: $sum."

# 9X9乘法表
#!/bin/bash
#

for ((j=1;j<=9;j++)); do
    for ((i=1;i<=j;i++)); do
        echo -e -n "${i}X${j}=$[$i*$j]\t"
    done
    echo
done


#==========
#sysinfo.sh
#==========
#!/bin/bash
#
cat << EOF
cpu) show cpu information;
mem) show memory information;
disk) show disk information;
quit) quit
============================
EOF

read -p "Enter a option: " option
while [ "$option" != 'cpu' -a "$option" != 'mem' -a "$option" != 'disk' -a "$option" != 'quit' ]; do
    read -p "Wrong option,Enter again: " option
done

if [ "$option" == 'cpu' ]; then
    lscpu
elif [ "$option" == 'mem' ]; then
    cat /proc/meminfo
elif [ "$option" == 'disk' ]; then
    fdisk -l
else
    echo "Quit"
    exit 0
fi


# case 实现
#!/bin/bash
#
cat << EOF
cpu) show cpu information;
mem) show memory information;
disk) show disk information;
quit) quit
============================
EOF

read -p "Enter a option: " option
while [ "$option" != 'cpu' -a "$option" != 'mem' -a "$option" != 'disk' -a "$option" != 'quit' ]; do
    read -p "Wrong option,Enter again: " option
done

case "$option" in
cpu)
    lscpu
    ;;
mem)
    cat /proc/meminfo
    ;;
disk)
    fdisk -l
    ;;
*)
    echo "Quit..."
    exit 0
esac


#=============
#function 练习
#=============
#!/bin/bash
#
username='myuser'
function adduser {
    if id $username &> /dev/null; then
        echo "$username exists."
        return 1
    else
        useradd $username
        [ $? -eq 0 ] && echo "Add $username finished." && return 0
    fi
}

adduser


#===========
#服务脚本
#===========
#!/bin/bash
#
# chkconfig: - 88 12
# description: test service script
#
prog=$(basename $0)
lockfile=/var/lock/subsys/$prog

start() {
    if [ -f $lockfile ]; then
        echo "$prog is already running."
        return 0
    else
        touch $lockfile
        [ $? -eq 0 ] && echo "Starting $prog finished."
    fi
}

stop() {
    if [ -f $lockfile ]; then
        rm -f $lockfile && echo "Stop $prog ok."
    else
        echo "$prog is stopped yet."
    fi
}

status() {
    if [ -f $lockfile ]; then
        echo "$prog is running."
    else
        echo "$prog is stoped."
    fi
}

usage(){
    echo "Usage: $prog {start|stop|restart|status}"
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

case $1 in
start)
    start
    ;;
stop)
    stop
    ;;
restart)
    stop
    start
    ;;
status)
    status
    ;;
*)
    usage
    ;;
esac

#=============
#array.sh
#=============
#!/bin/bash
#
declare -a rand
declare -i max=0

for i in {0..9}; do
    rand[$i]=$RANDOM
    echo ${rand[$i]}
    [ ${rand[$i]} -gt $max ] && max=${rand[$i]}
done

echo "Max: $max"




