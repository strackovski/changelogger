#!/bin/bash
# ============================================================
#
# ChangeLogger make script
#
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
# ============================================================

source ${PWD}/scripts/defaults.sh
source ${PWD}/scripts/io.sh

# ============================================================
#  *  BUILD EXECUTABLE
#
#  $1 - build version
#  $2 - deployer
#  $3 - VCS branch name
# ============================================================
build () {
    MACHINE_OS=$(machine_os)

    cd "$PWD" && scripts/slack/notify.pl "${ACTION_DATA}" "${BUILD_DATA}"

    printc "$(tput bold)\\n➜  Preparing build (${CURRENT_BRANCH})$(tput sgr0)" "blue" "suffix"
    log "build.temp" && log "build.temp" "BUILD STARTED: ${BUILD_ID}" true
    lint

    if [ $? != 0 ]; then
        ACTION_DATA="action:build;status:fail;user:${DEPLOYER}"
        build_fail "Linter errors encountered." "${ACTION_DATA}" true
    fi

    printc " ✓\\n" "green" && printc "➜  Building distributable... "

    STATUS=$(cd "$PWD" && pp --dependent -v -a 'includes/header.txt;header.txt' -a 'includes/config.json;config.json' -a 'includes/cacert.pem;cacert.pem' -X Perl::Critic -C -x -o bin/clogger clogger.pl >> var/logs/build.temp.log 2>&1;echo $?)

    if [ "${STATUS}" != 0 ]; then
        ACTION_DATA="action:build;status:fail;user:${DEPLOYER}"
        build_fail "Error while building." "${ACTION_DATA}" true
    fi

    if [ "${MACHINE_OS}" == 'Linux' ]; then
        cd "$PWD" && md5sum -q bin/clogger > bin/clogger.checksum
    else
        cd "$PWD" && md5 -q bin/clogger > bin/clogger.checksum
    fi

    ACTION_DATA="action:build;status:success;user:${DEPLOYER}"
    build_success "Build complete." "${ACTION_DATA}" true
}

# ============================================================
#  *  RELEASE DISTRIBUTABLE
#
#  $1 - build version
#  $2 - deployer
#  $3 - VCS branch name
# ============================================================
release () {
    log "release" "RELEASE STARTED"
    printc "$(tput bold)\\n➜  Preparing release$(tput sgr0)" "blue" "suffix" && printc "➜  Uploading build to S3..."
    cd "$PWD" && scripts/slack/notify.pl "${ACTION_DATA}" "${BUILD_DATA}"

    STATUS=$(s3_sync "${INSTALLER_ABS_PATH}" "${S3_PROJECT_ROOT}";echo $?)
    if [ ! ${STATUS} -eq 0 ]; then
       ACTION_DATA="action:release;status:fail;user:${DEPLOYER}"
       release_fail "Error uploading project installer to S3." "${ACTION_DATA}" true
    fi

    STATUS=$(s3_acl "${S3_PROJECT_ROOT}installer.sh" "public";echo $?)
    if [ ! ${STATUS} -eq 0 ]; then
        ACTION_DATA="action:release;status:fail;user:${DEPLOYER}"
        release_fail "Error setting S3 ACL on project installer." "${ACTION_DATA}" true
    fi

    STATUS=$(s3_sync "${BIN_DIR_ABS_PATH}" "${S3_DIST_ROOT}" true;echo $?)
    if [ ! ${STATUS} -eq 0 ]; then
        ACTION_DATA="action:release;status:fail;user:${DEPLOYER}"
        release_fail "Error uploading distributable to S3." "${ACTION_DATA}" true
    fi

    STATUS=$(s3_acl "${S3_DIST_ROOT}" "public" true;echo $?)
    if [ ! ${STATUS} -eq 0 ]; then
        ACTION_DATA="action:release;status:fail;user:${DEPLOYER}"
        release_fail "Error setting S3 ACL on distributable." "${ACTION_DATA}" true
    fi

    ACTION_DATA="action:release;status:success;user:${DEPLOYER}"
    release_success "Release complete." "${ACTION_DATA}" true
}

# ============================================================
#  *  RUN MAKE
# ============================================================
if [ $# -eq 0 ] || [ -z "$1" ]; then
    echo "Missing arguments for make"
    exit 1;
fi

if [ "$1" == 'build' ]; then
    ACTION_DATA="action:build;status:start;user:${DEPLOYER}"
    build
elif [ "$1" == 'release' ]; then
    ACTION_DATA="action:release;status:start;user:${DEPLOYER}"
    release
fi
