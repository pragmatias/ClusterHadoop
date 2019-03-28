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

if [ "$1" = "get_ssh" ]
then
    echo 'Y' | ssh-keygen -b 4096 -t rsa -N '' -f /home/hadoop/.ssh/id_rsa  >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
    cat /home/hadoop/.ssh/id_rsa.pub >> ${Vl_RepTmp}/authorized_keys
	if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
    echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "set_ssh" ]
then
    cp -f ${Vl_RepTmp}/authorized_keys /home/hadoop/.ssh/authorized_keys  >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
    chmod 600 /home/hadoop/.ssh/authorized_keys  >> ${Vl_log} 2>&1
	if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
    echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "get_host" ]
then
    ssh-keyscan $2 | grep -v "^#" >> ${Vl_RepTmp}/known_hosts
    if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
    echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "set_host" ]
then
    cp -f ${Vl_RepTmp}/known_hosts /home/hadoop/.ssh/known_hosts  >> ${Vl_log} 2>&1
    if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
    chmod 600 /home/hadoop/.ssh/known_hosts  >> ${Vl_log} 2>&1
	if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
	echo "0" > ${Vl_nomfichierCR}

elif [ "$1" = "cp_root_host" ]; then
	cp -f ${Vl_RepTmp}/hosts /etc/hosts  >> ${Vl_log} 2>&1
	if [ ${?} -ne 0 ]; then echo "1" > ${Vl_nomfichierCR} ; exit 1 ; fi
	echo "0" > ${Vl_nomfichierCR}

else 
	echo "1" > ${Vl_nomfichierCR}
	exit 1
fi

exit 0
