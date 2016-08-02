#!/bin/bash
# usage: sh script.sh
#
cd /tmp;
for mtpoint in `cat /proc/mounts  | grep -i "ext" | awk '{print $2}' | grep -vE "^/dev|^/proc|^/sys|nfs|net|misc" | sort -u`
do
    touch ${mtpoint}/tmp.log > /dev/null 2>&1;
    echo "123" > ${mtpoint}/tmp.log;
    if [ $? -ne 0 ]
    then
        lv=`df -h | grep -B1 -i "${mtpoint}" | grep -v "${mtpoint}"`;
        for pids in `lsof +D ${mtpoint} | grep -vi "pid" | awk '{print $2}'`
        do
            kill -9 $pids;
        done
        umount ${mtpoint};
        fsck.ext4 ${lv} -y;
        mount ${lv} ${mtpoint};
    fi
    rm -rf ${mtpoint}/tmp.log;
done