#!/bin/bash

set -e

ETCD_DEFAULT_VERSION="3.2.12"

if [ "$1" != "" ]; then
  ETCD_VERSION=$1
else
  echo -e "\033[33mWARNING: ETCD_VERSION is blank,use default version: ${ETCD_DEFAULT_VERSION}\033[0m"
  ETCD_VERSION=${ETCD_DEFAULT_VERSION}
fi

function download_etcd(){
    if [ ! -f "etcd-v${ETCD_VERSION}-linux-arm64.tar.gz" ]; then
        wget https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz
        tar -zxvf etcd-v${ETCD_VERSION}-linux-arm64.tar.gz
    fi
}

function uninstall_etcd(){
    echo -e "\033[33mWARNING: Delete etcd!\033[0m"
    rm -f /usr/local/bin/etcd /usr/local/bin/etcdctl

    echo -e "\033[33mWARNING: Delete etcd config!\033[0m"
    rm -rf /etc/etcd
    
    echo -e "\033[33mWARNING: Delete etcd systemd config!\033[0m"
    if [ -z "/lib/systemd/system/etcd.service" ]; then 
        systemctl stop etcd.service
        rm -f /lib/systemd/system/etcd.service
    fi
    systemctl daemon-reload
}

function preinstall(){
	getent group etcd >/dev/null || groupadd -r etcd
	getent passwd etcd >/dev/null || useradd -r -g etcd -d /var/lib/etcd -s /sbin/nologin -c "etcd user" etcd
}

function install_etcd(){
    echo -e "\033[32mINFO: Copy etcd...\033[0m"
	tar -zxvf etcd-v${ETCD_VERSION}-linux-arm64.tar.gz
	cp etcd-v${ETCD_VERSION}-linux-arm64/etcd /usr/local/bin/etcd
	cp etcd-v${ETCD_VERSION}-linux-arm64/etcdctl /usr/local/bin/etcdctl
	rm -rf etcd-v${ETCD_VERSION}-linux-arm64

    echo -e "\033[32mINFO: Copy kubernetes config...\033[0m"
    cp -r conf /etc/etcd
    mkdir /etc/etcd/ssl

    echo -e "\033[32mINFO: Copy kubernetes systemd config...\033[0m"
    cp systemd/*.service /lib/systemd/system
    systemctl daemon-reload
}

function postinstall(){
    if [ ! -d "/var/lib/etcd" ]; then
        mkdir /var/lib/etcd
        chown -R etcd:etcd /var/lib/etcd
    fi
}


download_etcd
uninstall_etcd
preinstall
install_etcd
postinstall


 