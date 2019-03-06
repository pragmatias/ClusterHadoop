#!/bin/bash

# Manage ssh

if [ "$1" = "get_ssh" ]
then
    echo 'Y' | ssh-keygen -b 4096 -t rsa -N '' -f /home/hadoop/.ssh/id_rsa
    cat /home/hadoop/.ssh/id_rsa.pub >> /config/authorized_keys
fi

if [ "$1" = "set_ssh" ]
then
    cp /config/authorized_keys /home/hadoop/.ssh/authorized_keys
    chmod 600 /home/hadoop/.ssh/authorized_keys
fi

if [ "$1" = "get_host" ]
then
    ssh-keyscan $2 | grep -v "^#" >> /config/known_hosts
fi


if [ "$1" = "set_host" ]
then
    cp /config/known_hosts /home/hadoop/.ssh/known_hosts
    chmod 600 /home/hadoop/.ssh/known_hosts
fi
