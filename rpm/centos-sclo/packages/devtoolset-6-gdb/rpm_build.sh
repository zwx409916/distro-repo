#!/bin/bash

CUR_DIR=$(cd `dirname $0`; pwd)

sudo yum install -y devtoolset-6-gcc
sudo yum install -y devtoolset-6-gcc-c++
sudo yum install -y devtoolset-6-libstdc++-devel

source /opt/rh/devtoolset-6/enable

SRC_RPM_FILE=devtoolset-6-gdb-7.12-24.el7.src.rpm
SRC_DIR=src
if [ ! -f ${CUR_DIR}/${SRC_DIR}/${SRC_RPM_FILE} ] ; then
    if [ ! -d ${CUR_DIR}/${SRC_DIR} ] ; then
        mkdir -p ${CUR_DIR}/${SRC_DIR}
    fi
    wget -O ${CUR_DIR}/${SRC_DIR}/${SRC_RPM_FILE} http://vault.centos.org/centos/7/sclo/Source/rh/devtoolset-6/${SRC_RPM_FILE}
    pushd ${CUR_DIR}/${SRC_DIR} > /dev/null
    rpm2cpio ${SRC_RPM_FILE} | cpio -div
    popd > /dev/null
fi

${CUR_DIR}/../../../../utils/rpm_build.sh  ${CUR_DIR}/${SRC_DIR}  gdb.spec
