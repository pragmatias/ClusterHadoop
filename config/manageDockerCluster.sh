#!/bin/bash

# Manage ssh
Vl_hostname=${HOSTNAME}
Vl_script=`basename $0`
Vl_RepTmp="/tmp/docker"
Vl_nomfichierCR="${Vl_RepTmp}/${Vl_hostname}_${Vl_script}.CR"
Vl_log="${Vl_RepTmp}/${Vl_hostname}_${Vl_script}.log"

#Start
echo "-1" > ${Vl_nomfichierCR}
rm -f ${Vl_log}

if [ "$1" = "start" ]
then
    /home/hadoop/hadoop/sbin/start-dfs.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/hadoop/sbin/start-yarn.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/spark/sbin/start-master.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/spark/sbin/start-slaves.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "stop" ]
then
    /home/hadoop/spark/sbin/stop-slaves.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/spark/sbin/stop-master.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/hadoop/sbin/stop-yarn.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/hadoop/sbin/stop-dfs.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "format" ]
then
    /home/hadoop/hadoop/bin/hdfs namenode -format >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
    echo "0" > ${Vl_nomfichierCR}

else 
	echo "1" > ${Vl_nomfichierCR}
	exit 1
fi

exit 0
