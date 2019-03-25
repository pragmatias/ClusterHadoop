FROM centos:7

MAINTAINER pragmatias

#Configuration du proxy
#ENV http_proxy http://usr:pwd@192.168.77.12:8080
#ENV https_proxy http://usr:pwd@192.168.77.12:8080

#Configuration package hadoop
ENV hadoop_pkg hadoop-3.2.0

#Configuration des variables d'environnement
ENV JAVA_HOME /usr/lib/jvm/jre

#Exposition de port
EXPOSE 22
EXPOSE 80
EXPOSE 7077
EXPOSE 8042
EXPOSE 8081
EXPOSE 8080
EXPOSE 8088
EXPOSE 9000
EXPOSE 9001
EXPOSE 9864
EXPOSE 9866
EXPOSE 9870


#Used root
USER root
#definition d'un mot de passe
#RUN echo 'root:rooting' | chpasswd

#Install update
RUN yum -y update && yum clean all

#Installation package centos
RUN yum -y install \
        java-1.8.0-openjdk \
        java-1.8.0-openjdk-devel \
        openssh \
        openssh-server \
        openssh-clients \
        net-tools \
        && yum clean all

#Configuration de la partie SSH
RUN echo 'Y' | ssh-keygen -b 4096 -t rsa -N '' -f /root/.ssh/id_rsa
#COPY --chown=root config/ssh/id_rsa.pub /root/.ssh/authorized_keys

#Configuration du serveur SSH
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config
RUN echo "Host *" >> /etc/ssh/ssh_config
#RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's@HostKey /etc/ssh/ssh_host_dsa_key@#HostKey /etc/ssh/ssh_host_dsa_key@' /etc/ssh/sshd_config
RUN sed -i 's@HostKey /etc/ssh/ssh_host_ecdsa_key@#HostKey /etc/ssh/ssh_host_ecdsa_key@' /etc/ssh/sshd_config
RUN sed -i 's@HostKey /etc/ssh/ssh_host_ed25519_key@#HostKey /etc/ssh/ssh_host_ed25519_key@' /etc/ssh/sshd_config
RUN sed -i 's@PasswordAuthentication yes@PasswordAuthentication no@' /etc/ssh/sshd_config

RUN cp /root/.ssh/id_rsa.pub /etc/ssh/ssh_host_rsa_key.pub
RUN cp /root/.ssh/id_rsa /etc/ssh/ssh_host_rsa_key






#Configuration du user HADOOP
RUN groupadd hadoop
RUN useradd -ms /bin/bash hadoop -g hadoop -G wheel,users
RUN echo 'hadoop:hadoop' | chpasswd


USER hadoop
WORKDIR /home/hadoop


#configuration ssh2 pour hadoop
RUN mkdir /home/hadoop/.ssh
#RUN echo 'Y' | ssh-keygen -b 4096 -t rsa -N '' -f /home/hadoop/.ssh/id_rsa
RUN echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config
RUN echo PasswordAuthentication no >> /home/hadoop/.ssh/config
#COPY --chown=hadoop config/ssh/id_rsa.pub /home/hadoop/.ssh/authorized_keys


#Configuration SSH pour hadoop
#RUN mkdir /home/hadoop/.ssh
#RUN echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config
#RUN echo PasswordAuthentication no >> /home/hadoop/.ssh/config
#COPY --chown=hadoop config/ssh/id_rsa.pub /home/hadoop/.ssh/id_rsa.pub
#COPY --chown=hadoop config/ssh/id_rsa /home/hadoop/.ssh/id_rsa
#COPY --chown=hadoop config/ssh/id_rsa.pub /home/hadoop/.ssh/authorized_keys

#Installation de hadoop
COPY --chown=hadoop package/${hadoop_pkg}.tar.gz /home/hadoop/
RUN tar -xzf ${hadoop_pkg}.tar.gz
RUN mv ${hadoop_pkg} hadoop
RUN rm ${hadoop_pkg}.tar.gz

#Creation repertoire necessaire hadoop
RUN mkdir -p /home/hadoop/hadoop/logs /home/hadoop/data/nameNode /home/hadoop/data/dataNode /home/hadoop/data/namesecondary /home/hadoop/data/tmp
RUN touch /home/hadoop/hadoop/logs/fairscheduler-statedump.log


#Gestion de l'environnement
RUN echo "export PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:\$PATH" >> /home/hadoop/.profile
RUN echo "PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:\$PATH" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.profile

RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /home/hadoop/.profile
RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /home/hadoop/.bashrc


RUN echo JAVA_HOME=/usr/lib/jvm/jre >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_NAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_DATANODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_SECONDARYNAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh


#Copie des fichiers de configuration
COPY --chown=hadoop config/hadoop/core-site.xml config/hadoop/hdfs-site.xml config/hadoop/mapred-site.xml config/hadoop/yarn-site.xml /home/hadoop/hadoop/etc/hadoop/


COPY --chown=hadoop config/manageDockerSSH.sh /home/hadoop/manageDockerSSH.sh
RUN chmod +x /home/hadoop/manageDockerSSH.sh


USER root
#RUN cat /config/hosts > /etc/hosts


#Execution du service SSH 
CMD ["/usr/sbin/sshd", "-D"]



