#!/bin/sh

dnf -y install git autoconf automake libtool docker sshpass
dnf groupinstall -y "Development Tools"
# ovs compilation requires module 'six' to be installed
easy_install six

chkconfig docker on
systemctl start docker.service
systemctl enable docker.service
usermod -a -G docker vagrant

git clone https://github.com/openvswitch/ovs.git
cd ovs
echo `pwd`
sh boot.sh
sh configure
make install

echo 'export PATH=$PATH:/usr/local/bin' >> /root/.profile
