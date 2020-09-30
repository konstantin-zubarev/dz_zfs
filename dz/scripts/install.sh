#!/bin/bash
# Install

yum install http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm -y
gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
yum install zfs -y
yum install epel-release -y
yum install "kernel-devel-uname-r == $(uname -r)" zfs -y
modprobe zfs
