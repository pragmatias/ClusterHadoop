#!/bin/bash

# Manage ssh

if [ "$1" = "get_ssh" ]
then
    echo 'Y' | ssh-keygen -b 4096 -t rsa -N '' -f /home/hadoop/.ssh/id_rsa
    if [ ${?} -ne 0 ]; then exit 1 ; fi
    cat /home/hadoop/.ssh/id_rsa.pub >> /tmp_docker/authorized_keys
	if [ ${?} -ne 0 ]; then exit 1 ; fi
    exit 0

elif [ "$1" = "set_ssh" ]
then
    cp /tmp_docker/authorized_keys /home/hadoop/.ssh/authorized_keys
    if [ ${?} -ne 0 ]; then exit 1 ; fi
    chmod 600 /home/hadoop/.ssh/authorized_keys
	if [ ${?} -ne 0 ]; then exit 1 ; fi
	exit 0

elif [ "$1" = "get_host" ]
then
    ssh-keyscan $2 | grep -v "^#" >> /tmp_docker/known_hosts
    if [ ${?} -ne 0 ]; then exit 1 ; fi

elif [ "$1" = "set_host" ]
then
    cp /tmp_docker/known_hosts /home/hadoop/.ssh/known_hosts
    if [ ${?} -ne 0 ]; then exit 1 ; fi
    chmod 600 /home/hadoop/.ssh/known_hosts
	if [ ${?} -ne 0 ]; then exit 1 ; fi
	exit 0
else 
	sleep 20
	exit 1
fi
