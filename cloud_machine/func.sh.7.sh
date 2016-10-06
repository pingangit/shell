#!/bin/sh 


basePath=/opt/cloud


function downloadFile() 
{ 
    # $1  download url
    # $2  dest local directory path
    # $3  dest local file name  (optional)
    # return 0  succ
    # return 1  wget fail
    # return 2  mkdir fail

    url=$1
    path=$2
    fileName=$3

    if [[ ${path:0:1} != "/" ]]
    then
        path=$basePath/$path
    fi
    if [[ ${path: -1} == "/" ]]
    then
        path=${path:0:((${#path}-1))}
    fi
    if [[ $fileName == ""  ]]
    then
        fileName=`echo "$url" | awk -F "/" '{print $NF}'`
    fi
# echo $url
# echo $path
# echo $fileName 
    if [[ ! -d $path ]]
    then
        mkdir $path
    fi
    if [[ ! -d $path ]]
    then
        echo "fail"
        return 2
    fi

    wget -q -T 5 -t 3 -O $path/$fileName $url
    if [[ $? -eq 0 ]]
    then
        echo "succ"
        return 0
    else
        echo "fail"
        return 1
    fi
}

function downloadDirectory()
{
# $1  download url
# $2  dest local path

    url=$1
    path=$2
    fileName=$3
    if [[ ${path:0:1} != "/" ]]
    then
        path=$basePath/$path
    fi
    if [[ ${path: -1} == "/" ]]
    then
        path=${path:0:((${#path}-1))}
    fi

    if [[ ! -d $path ]]
    then
        mkdir -p "$path"
    fi

    tmpDir="$basePath/scripts/downloadTmp/$RANDOM$RANDOM"
    if [[ ! -d $tmpDir ]]
    then
        mkdir -p "$tmpDir"
    fi
    wget -q -t 1 -T 2 -r -np -P  "$tmpDir" "$url"
    if [[ $? == 0 ]]
    then
        cPath=`echo "$url"|awk -F  "//" '{print $2}'`
        mvPath="$tmpDir/$cPath"
        if [[ ${mvPath: -1} == "/" ]]
        then
            mvPath=${mvPath:0:((${#mvPath}-1))}
        fi

        # clear index.html
        for indexFile in `find "$mvPath" -name "index.html"`
        do
            isRemove=`cat "$indexFile" |grep "<title>Directory Listing For"`
            if [[ $isRemove != "" ]]
            then
                rm -f $indexFile
            fi
        done
        # echo mv "$mvPath/*"  "$path"
        mv "$mvPath/"*  "$path"
        echo "succ"
        return 0
    else
        echo "fail"
        return 1
    fi

}

function getVrIp()
{
    # return 0  succ
    # return 1  fail

    DHCP_FOLDERS="/var/lib/dhclient/* /var/lib/dhcp3/* /var/lib/dhcp/*"
    file_count=0

    for DHCP_FILE in $DHCP_FOLDERS
    do
        if [[ -f $DHCP_FILE ]]
        then
            file_count=$((file_count+1))
            vrIp=$(grep dhcp-server-identifier $DHCP_FILE | tail -1 | awk '{print $NF}' | tr -d '\;')

            if [[ -n "$vrIp" ]]
            then
                echo $vrIp
                return 0
            fi
        fi
    done
    return 1
}

function getVmIp()
{
    vmip=`ifconfig  |grep 'broadcast' |head -1 |awk '{print $2}'`
    if [[ $vmip != "" ]]
    then
        echo $vmip
        return 0
    fi
    return 1
}

function getVmUUid()
{
    dmidecode -t system |grep  "UUID:" |awk -F ":" '{print $2}' |awk '{print $1}' | tr "A-Z" "a-z"
    return $?
}

function refreshUserData()
{
    vmip=$(getVmIp)
    vrIp=$(getVrIp)

    if [[ $vmip != "" ]] &&  [[ $vrIp != "" ]]
    then
        rm -f $basePath/scripts/user-data
        isSucc=$(downloadFile "http://$vrIp:80/userdata/$vmip/user-data" "scripts")
        if [[ $isSucc == "succ" ]]
        then
            echo "succ"
            return 0
        fi
    fi
    echo "fail"
    return 1
}


function getSingleSecValue()
{
    # $* search str
    if [[ ! -f $basePath/scripts/user-data ]]
    then
        refreshUserData
    fi

    if [[ ! -f $basePath/scripts/user-data ]]
    then
        echo ""
        return 1
    fi

    grepStr=""
    for arg in $*
    do
        if [[ $arg == "?" ]]
        then
            grepStr="$grepStr:\w*"
        else
            grepStr="$grepStr:$arg"
        fi
    done
    beginGrepStr="##=sec begin$grepStr(:\w*)*#"
    endGrepStr="##=sec end$grepStr(:\w*)*#"

    #echo $beginGrepStr

    beginLineNum=`cat $basePath/scripts/user-data |grep -n -E "$beginGrepStr" | awk -F ":" '{print $1}' |head -1`
    endLineNum=`cat $basePath/scripts/user-data |grep -n -E "$endGrepStr" |  awk -F ":" '{print $1}' |head -1`

    if [[ $beginLineNum != "" ]] && [[ $endLineNum != "" ]]
    then
        secName=`cat $basePath/scripts/user-data  |grep -E "$beginGrepStr" | awk -F ":" '{print $2}'`
        beginLineNum=$(($beginLineNum+1))
        endLineNum=$(($endLineNum-1))
        # echo $beginLine
        # echo $endLine
        sed -n "$beginLineNum","$endLineNum"p $basePath/scripts/user-data
        return 0
    else
        return 2
    fi
}


function getServerIp()
{
    # $1 serverName
    serverName=$1
    servers=$(getSingleSecValue "?" "serverList")
    if [[ $? == 0 ]]
    then
        for line in $servers
        do
            if [[ "$line" =~ "$serverName:" ]]
            then
                echo $line | awk -F ":" '{print $2}'
                return 0
            fi
        done
    else
        return 2
    fi
    return 1
}

function getTools()
{
  if [[ ! -f $basePath/scripts/user-data ]]
  then
      refreshUserData
  fi
  if [[ ! -f $basePath/scripts/user-data ]]
  then
      echo ""
      return 1
  fi
  cat $basePath/scripts/user-data | grep -E "##=sec begin:(\w+)" |grep -vE "whenStop|server" |awk -F: '{print $2}' | sort | uniq 
}


function strSplit()
{
    # $1	str which to be splited
    # $2	split regex
    # return str array
    OLD_IFS="$IFS"
    IFS=$2
    arr=($1)
    IFS="$OLD_IFS"
    for s in ${arr[@]}
    do
    echo "$s" 
    done
}


function report()
{
    # $1	reportId / type  eg. vmagent.create  vmagent.start
    # $2	state
    # $3  details  , base64 it
    uuid=$(getVmUUid)
    reportServer=$(getServerIp "reportServer")

    if [[ $3 != "" ]]
    then
        detail=`echo $3 |base64`
        curl -d "Uuid=$uuid&reportId=$1&state=$2&detail=$detail" http://$reportServer:8080/report/Report.do
    else
        curl -d "Uuid=$uuid&reportId=$1&state=$2" http://$reportServer:8080/report/Report.do
    fi
}


# ���ɶ�������Ľű�
function buildScripts()
{
    # $1 type
    # $2 secName; default is all
    type=$1
    if [[ ! -f $basePath/scripts/user-data ]]
    then
        refreshUserData
    fi

    if [[ ! -f $basePath/scripts/user-data ]]
    then
        echo ""
        return 1
    fi

    searchSecName="\w+"
    if [[ $2 != "" ]] && [[ $2 != "all" ]] && [[ $2 != "ALL" ]]
    then
        searchSecName=$2
    fi

    beginGrepStr="##=sec begin:$searchSecName:$type(:\w*)*#"
#	echo $beginGrepStr
    OLD_IFS="$IFS"
    IFS=$'\n'
    for line in `cat $basePath/scripts/user-data |grep -n -E "$beginGrepStr"`
    do
        # echo "------------ $line"
        beginLineNum=`echo $line | awk -F ":" '{print $1}' `
        secName=`echo $line | awk -F ":" '{print $3}'`
        # echo " =========== $secName"
        endGrepStr="##=sec end:$secName:$type(:\w*)*#"
        endLineNum=`cat $basePath/scripts/user-data |grep -n -E "$endGrepStr" |  awk -F ":" '{print $1}' |head -1`

        if [[ $beginLineNum != "" ]] && [[ $endLineNum != "" ]]
        then
            beginLineNum=$(($beginLineNum+1))
            endLineNum=$(($endLineNum-1))
            if [[ ! -d "$basePath/scripts/$secName" ]]
            then
                mkdir -p "$basePath/scripts/$secName"
            fi
            if [[ ! -d "$basePath/$secName" ]]
            then
                mkdir -p "$basePath/$secName"
            fi

            # sed -n "$beginLineNum","$endLineNum"p "$basePath/scripts/user-data"
            umask 022
            echo "#!/bin/bash" > "$basePath/scripts/$secName/$type.sh.auto"
            echo "source $basePath/scripts/func.sh" >> "$basePath/scripts/$secName/$type.sh.auto"
            echo "cd $basePath/$secName" >> "$basePath/scripts/$secName/$type.sh.auto"
            echo "" >> "$basePath/scripts/$secName/$type.sh.auto"
            sed -n "$beginLineNum","$endLineNum"p "$basePath/scripts/user-data" >> "$basePath/scripts/$secName/$type.sh.auto"
            chmod 750 $basePath/scripts/$secName/$type.sh.auto
            echo "$basePath/scripts/$secName/$type.sh.auto"
        fi
    done
    IFS="$OLD_IFS"
    return 0
}

function getVrHostname()
{
    vmip=$(getVmIp)
    vrIp=$(getVrIp)
    tmpDir="$basePath/scripts/downloadTmp/$RANDOM$RANDOM"
    mkdir -p $tmpDir
    if [[ $vmip != "" ]] &&  [[ $vrIp != "" ]]
    then
        isSucc=$(downloadFile "http://$vrIp:80/metadata/$vmip/local-hostname" "$tmpDir")
        if [[ $isSucc == "succ" ]]
        then
            cat "$tmpDir/local-hostname"
            # rm -rf $tmpDir
            return 0
        fi
    fi
    echo "fail"
    return 1
}

function getOsPlatform()
{
    if [ -f /etc/redhat-release ]
    then
       platform=$(sed 's/^\(.\+\) release.*/\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]')
       version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
       if echo $platform | grep -q 'red hat';then
           echo "rhel$version"
           return 0
       fi
           echo "$platform$version"
           return 0
    elif [ -f /etc/SuSE-release ]
    then
        if grep -q 'Enterprise' /etc/SuSE-release
        then
            version=`awk '/^VERSION/ {V = $3}; /^PATCHLEVEL/ {P = $3}; END {print V "." P}' /etc/SuSE-release`
            echo "sles$version"
            return 0
        fi
    fi
    echo "fail"
    return 1
}

function vrStatus() 
{
    i=0
    ip=$(getVrIp)
    while [ $? -eq 0 ] && [ $i -lt 35 ]
    do
       ping -c 2 $ip && return 0 || sleep 5
       (( i = i + 1 ))
    done
    logger "cloudTools:vr ping failed in 60s"
}
