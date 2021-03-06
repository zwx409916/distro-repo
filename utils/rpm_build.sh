#!/bin/bash

CUR_DIR=$(cd `dirname $0`; pwd)
echo "Begin to build RPM Packages for aarch64 platform"

if [ -d ~/rpmbuild/RPMS ] ; then
    echo "Previous RPM build still exists, so it might be necessary to clear them before building new one"
fi 

if [ "$(uname -m)" != "aarch64" ] ; then
    echo "Please build this package on arm64 platform"
    exit 1
fi

if [ -z "$(which rpmsign 2>/dev/null)" ] ; then
    sudo yum install rpm-sign
fi

SRC_DIR=$1
SPEC_FILE=$2

if [ ! -d ${SRC_DIR} ] ; then
    echo "${SRC_DIR} directory does not exist !"
    exit 1
fi

sudo yum-builddep -y ${SRC_DIR}/${SPEC_FILE}
passphrase=`cat /home/KEY_PASSPHRASE`
expect <<-END
	set timeout -1
	spawn rpmbuild --sign  --target aarch64 -ba ${SRC_DIR}/${SPEC_FILE} "--define=_sourcedir ${SRC_DIR}" "--define=_specdir ${SRC_DIR}" ${@:3}
	expect {
                "Enter pass phrase:" {send "${passphrase}\r"}
		timeout {send_user "Enter pass phrase timeout\n"}
        }
	expect eof
END
echo "Please check rpm under ~/rpmbuild/RPMS/ or ~/rpmbuild/SRPMS/ directory !"
