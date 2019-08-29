#!/bin/bash
. ~/.profile

# Manage ssh
Vl_hostname=${HOSTNAME}
Vl_script=`basename $0`
Vl_RepTmp="/tmp/docker"
Vl_nomfichierCR="${Vl_RepTmp}/${Vl_hostname}_${Vl_script}.CR"
Vl_log="${Vl_RepTmp}/${Vl_hostname}_${Vl_script}.log"

#Start
echo "-1" > ${Vl_nomfichierCR}
rm -f ${Vl_log}

if [ "$1" = "start_hadoop" ]
then
    /home/hadoop/hadoop/sbin/start-dfs.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    #check hdfs master service
    Vl_testOK=`/usr/bin/jps | grep -E "\sNameNode|\sSecondaryNameNode" | wc -l`
    if [ ${Vl_testOK} -ne 2 ]
    then
        echo "Dont find NameNode or SecondaryNameNode with /usr/bin/jps" >> ${Vl_log} 2>&1
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/hadoop/sbin/start-yarn.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    #check yarn master service
    Vl_testOK=`/usr/bin/jps | grep "\sResourceManager" | wc -l`
    if [ ${Vl_testOK} -ne 1 ]
    then
        echo "Dont find ResourceManager with /usr/bin/jps" >> ${Vl_log} 2>&1
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "stop_hadoop" ]
then
    /home/hadoop/hadoop/sbin/stop-yarn.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    #check yarn master service
    Vl_testOK=`/usr/bin/jps | grep "\sResourceManager" | wc -l`
    if [ ${Vl_testOK} -gt 0 ]
    then
        echo "Find ResourceManager with /usr/bin/jps" >> ${Vl_log} 2>&1
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/hadoop/sbin/stop-dfs.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    #check hdfs master service
    Vl_testOK=`/usr/bin/jps | grep -E "\sNameNode|\sSecondaryNameNode" | wc -l`
    if [ ${Vl_testOK} -gt 0 ]
    then
        echo "Find NameNode or SecondaryNameNode with /usr/bin/jps" >> ${Vl_log} 2>&1
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "start_spark" ]
then

    #Creation of the spark-logs repository for history server service
    /home/hadoop/hadoop/bin/hdfs dfs -mkdir -p /user/hadoop/spark-logs >> ${Vl_log} 2>&1
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

    #check spark master service
    Vl_testOK=`/usr/bin/jps | grep "\sMaster" | wc -l`
    if [ ${Vl_testOK} -ne 1 ]
    then
        echo "Dont find Master with /usr/bin/jps" >> ${Vl_log} 2>&1
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    /home/hadoop/spark/sbin/start-slaves.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi


    /home/hadoop/spark/sbin/start-history-server.sh >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]
    then 
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    #check spark master service
    Vl_testOK=`/usr/bin/jps | grep "\sHistoryServer" | wc -l`
    if [ ${Vl_testOK} -ne 1 ]
    then
        echo "Dont find HistoryServer with /usr/bin/jps" >> ${Vl_log} 2>&1
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "stop_spark" ]
then



    Vl_testJump=`/usr/bin/jps | grep "\sHistoryServer" | wc -l`
    if [ ${Vl_testJump} -gt 0 ]
    then
        /home/hadoop/spark/sbin/stop-history-server.sh >> ${Vl_log} 2>&1
        if [ ${?} -ne 0 ]
        then 
            echo "1" > ${Vl_nomfichierCR}
            exit 1
        fi

        #check spark master service
        Vl_testOK=`/usr/bin/jps | grep "\sHistoryServer" | wc -l`
        if [ ${Vl_testOK} -gt 0 ]
        then
            echo "Find HistoryServer with /usr/bin/jps" >> ${Vl_log} 2>&1
            echo "1" > ${Vl_nomfichierCR}
            exit 1
        fi
    fi


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


    #check spark master service
    Vl_testOK=`/usr/bin/jps | grep "\sMaster" | wc -l`
    if [ ${Vl_testOK} -gt 0 ]
    then
        echo "Find Master with /usr/bin/jps" >> ${Vl_log} 2>&1
        echo "1" > ${Vl_nomfichierCR}
        exit 1
    fi

    echo "0" > ${Vl_nomfichierCR}


elif [ "$1" = "format_hadoop" ]
then
    /home/hadoop/hadoop/bin/hdfs namenode -format >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
    echo "0" > ${Vl_nomfichierCR}

else 
	echo "1" > ${Vl_nomfichierCR}
	exit 1
fi

exit 0
