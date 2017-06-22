#!/bin/bash

cd ~
export DEBEMAIL=sjtuhjh@hotmail.com
export DEBFULLNAME=Open-Estuary
wget -O - http://repo.linaro.org/ubuntu/linarorepo.key | apt-key add -
apt-get update
apt-get install expect -y
apt-get install automake -y
apt-get install dh-make -y
apt-get install devscripts -y

echo "DEBSIGN_KEYID=24CC6CF4" >> /etc/devscripts.conf
passphrase=$(cat /root/KEY_PASSPHRASE)

SRC_DIR=$1
TAR_FILENAME=$2
FILENAME="${TAR_FILENAME%*.orig.tar.gz}"
if [ x"${TAR_FILENAME}" == x"${FILENAME}" ] ; then
    FILENAME=${TAR_FILENAME%*.tar.gz}
fi
if [ x"${TAR_FILENAME}" == x"${FILENAME}" ] ; then
    FILENAME=${TAR_FILENAME%*.tar.bz2}
fi
DISTRI=$3

if [ $DISTRI = "debian" ]; then
	DESDIR=debbuild
fi
if [ $DISTRI = "ubuntu" ]; then
	DESDIR=ububuild
fi

if [ ! -d ${SRC_DIR} ]; then
    echo "${SRC_DIR} directory does not exist !"
    exit 1
fi

if [ $TAR_FILENAME = "oprofile-1.1.0.tar.gz" ];then
	apt-get update
	apt-get install default-jdk=2:1.7-52 default-jre=2:1.7-52 default-jre-headless=2:1.7-52 -y
fi

if [ -d /root/${DESDIR}/SOURCES/${FILENAME} ]; then
    echo "${FILENAME} had been builded before, now begin clean the directory."
    rm -rf /root/${DESDIR}/SOURCES/${FILENAME}/*
else
    mkdir -p /root/${DESDIR}/SOURCES/${FILENAME}
fi

#Step1 : Copy necessary files to SOURCES directory
cp ${SRC_DIR}/* /root/${DESDIR}/SOURCES/${FILENAME}/

#Step2 : Decompress necessary files
if [ -z "$(echo ${TAR_FILENAME} | grep '.orig.tar.gz')" ] ; then
    if [ ! -z "$(echo ${TAR_FILENAME} | grep 'tar.bz2')" ] ; then
        tar -jxvf /root/${DESDIR}/SOURCES/${FILENAME}/${TAR_FILENAME} -C /root/${DESDIR}/SOURCES/${FILENAME}/
    else 
        tar -zxvf /root/${DESDIR}/SOURCES/${FILENAME}/${TAR_FILENAME} -C /root/${DESDIR}/SOURCES/${FILENAME}/
    fi
fi

cd /root/${DESDIR}/SOURCES/${FILENAME}/
if [ ! -z "$(ls *.dsc 2>/dev/null)" ] ; then
    dpkg-source -x *.dsc
fi

SUBDIR=""
for filename in /root/${DESDIR}/SOURCES/${FILENAME}/*
do
    if [ x"${filename}" == x"." ] || [ x"${filename}" == x".." ] ; then
        continue
    fi

    if [ -d ${filename} ] ; then
        SUBDIR=${filename}
        break
    fi
done
if [ -f /root/${DESDIR}/SOURCES/${FILENAME}/debian.tar.gz ] ; then
    tar -zxvf /root/${DESDIR}/SOURCES/${FILENAME}/debian.tar.gz -C ${SUBDIR}/
fi

#Step3: Build deb packages
cd ${SUBDIR}
dh_make -s --copyright gpl2 -f ../${TAR_FILENAME} -y
#apt-get build-dep ${FILENAME} -y
mk-build-deps -i -t 'apt-get -y' debian/control
rm *build-deps*.deb

expect <<-END
        set timeout -1
        spawn debuild
        expect {
                "Enter passphrase:" {send "${passphrase}\r"}
                timeout {send_user "Enter pass phrase timeout\n"}
        }
        expect {
                "Enter passphrase:" {send "${passphrase}\r"}
                timeout {send_user "Enter pass phrase timeout\n"}
        }
        expect eof
END

if [ ! -d /root/${DESDIR}/DEBS ]; then
        mkdir -p /root/${DESDIR}/DEBS
fi

if [ ! -d /root/${DESDIR}/SDEBS ]; then
        mkdir -p /root/${DESDIR}/SDEBS
fi

if [ ! -d /root/${DESDIR}/BUILDS ]; then
        mkdir -p /root/${DESDIR}/BUILDS
fi

if [ ! -d /root/${DESDIR}/CHANGES ]; then
        mkdir -p /root/${DESDIR}/CHANGES
fi

cp /root/${DESDIR}/SOURCES/${FILENAME}/*.deb /root/${DESDIR}/DEBS/
cp /root/${DESDIR}/SOURCES/${FILENAME}/*.dsc /root/${DESDIR}/SDEBS/
cp /root/${DESDIR}/SOURCES/${FILENAME}/*.orig.tar.gz /root/${DESDIR}/SDEBS/
cp /root/${DESDIR}/SOURCES/${FILENAME}/*.debian.tar.xz /root/${DESDIR}/SDEBS/
cp /root/${DESDIR}/SOURCES/${FILENAME}/*.build /root/${DESDIR}/BUILDS/
cp /root/${DESDIR}/SOURCES/${FILENAME}/*.changes /root/${DESDIR}/CHANGES/

echo "Please check deb under ~/${DESDIR}/DEBS/ or ~/${DESDIR}/SDEBS/ directory !"
