

============
mul2.sh
============

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

============
mul.sh
============

#!/bin/bash


for j in {1..9}; do
    for i in $(seq 1 $j); do
        echo -e -n "${i}X${j}=$[$i*$j]\t"
    done
    echo
done

============
ping2.sh
============

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

============
rand.sh
============

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

============
summary.sh
============

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


============
useradd.sh
============

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



