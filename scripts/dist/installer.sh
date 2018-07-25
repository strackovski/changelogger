#!/bin/bash
# ============================================================
#
# ChangeLogger installer
#
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
# ============================================================

printf "$(tput setaf 69)\n Installing ChangeLogger \n$(tput sgr0)"
printf -- '---------------------------------------------\n'
printf '➜  Detecting platform architecture...    ';
MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
    printf "$(tput setaf 40) ✓\n$(tput sgr0)"
    DIST_URL='https://s3.eu-central-1.amazonaws.com/nv3-org/changelogger/dist/current/64/clogger';
    CHECKSUM_URL='https://s3.eu-central-1.amazonaws.com/nv3-org/changelogger/dist/current/64/clogger.checksum';
else
    printf "$(tput setaf 40) ✓\n$(tput sgr0)"
    DIST_URL='https://s3.eu-central-1.amazonaws.com/nv3-org/changelogger/dist/current/32/clogger';
    CHECKSUM_URL='https://s3.eu-central-1.amazonaws.com/nv3-org/changelogger/dist/current/32/clogger.checksum';
fi

printf '➜  Checking operating system support...  ';
OS_NAME="$(uname -s)"
case "${OS_NAME}" in
    Linux*)     MACHINE_OS=Linux;;
    Darwin*)    MACHINE_OS=macOS;;
    CYGWIN*)    MACHINE_OS=Cygwin;;
    MINGW*)     MACHINE_OS=MinGw;;
    *)          MACHINE_OS="UNKNOWN:${OS_NAME}"
esac

if [ ${MACHINE_OS} == 'Linux' ] || [ ${MACHINE_OS} == 'macOS' ]; then
    printf "$(tput setaf 40) ✓\n$(tput sgr0)"
else
    printf "$(tput setaf 9) ✗\n$(tput sgr0)"
    printf -- '---------------------------------------------\n'
    printf "$(tput setaf 9)✗  Installation failed: \n$(tput sgr0)"
    printf "$(tput setaf 9)   Super sorry, no support for ${MACHINE_OS}.\n$(tput sgr0)"
    exit
fi

printf "➜  Downloading distributable package...  "
curl -s ${DIST_URL} > clogger;

if [ -e clogger ]; then
    printf "$(tput setaf 40) ✓\n$(tput sgr0)"
else
    printf "$(tput setaf 9) ✗\n$(tput sgr0)"
    printf -- '---------------------------------------------\n'
    printf "$(tput setaf 9)✗  Installation failed: \n$(tput sgr0)"
    printf "$(tput setaf 9)   Failed downloading distributable file.\n$(tput sgr0)"
    exit
fi

printf "➜  Downloading MD5 checksum...           "
curl -s clogger ${CHECKSUM_URL} > clogger.checksum;

if [ -e clogger.checksum ]; then
    printf "$(tput setaf 40) ✓\n$(tput sgr0)"
    MD5_SUM=`cat clogger.checksum`
else
    printf "$(tput setaf 9) ✗\n$(tput sgr0)"
    printf -- '---------------------------------------------\n'
    printf "$(tput setaf 9)✗  Installation failed: \n$(tput sgr0)"
    printf "$(tput setaf 9)   Failed downloading checksum.\n$(tput sgr0)"
    exit
fi

printf '➜  Verifying downloaded file integrity...';

if [ ${MACHINE_OS} == 'Linux' ]; then
    FILE_CHECKSUM_MD5=$(md5sum clogger);
else
    FILE_CHECKSUM_MD5=$(md5 -q clogger);
fi

if [ "$FILE_CHECKSUM_MD5" == "$MD5_SUM" ]; then
    printf "$(tput setaf 40) ✓\n$(tput sgr0)"
    rm clogger.checksum
else
    printf "${FILE_CHECKSUM_MD5}"
    printf '\n'
    printf "${MD5_SUM}"
    printf "$(tput setaf 9) ✗\n$(tput sgr0)"
    printf -- '---------------------------------------------\n'
    printf "$(tput setaf 9)✗  Installation failed: \n$(tput sgr0)"
    printf "$(tput setaf 9)   Integrity check failed.\n$(tput sgr0)"
    exit
fi

mv clogger /usr/local/bin/clogger && chmod 755 /usr/local/bin/clogger
printf '➜  Installing to path directory...';
if [ -e /usr/local/bin/clogger ]; then
    printf "$(tput setaf 40) ✓\n$(tput sgr0)"
    printf -- '---------------------------------------------\n'
    printf "$(tput setaf 40)✓  Installation complete:\n$(tput sgr0)"
    printf "   Execute 'clogger' anywhere to run.\n\n"
else
    printf "$(tput setaf 9) ✗\n$(tput sgr0)"
    printf -- '---------------------------------------------\n'
    printf "$(tput setaf 9)✗  Installation failed: \n$(tput sgr0)"
    printf "   Unable to move file to path directory.\n\n"
    exit
fi
