#!/bin/bash
# ============================================================
#
# ChangeLogger pre-push hook for git
#
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
# ============================================================

source ${PWD}/scripts/defaults.sh
source ${PWD}/scripts/io.sh

printc "$(tput bold)\\n➜  Invoking pre-push hook$(tput sgr0)" "blue" "suffix"

PROTECTED_BRANCH='master'
DEV_BRANCH='develop'
PUSH_COMMAND=$(ps -ocommand= -p $PPID)
IS_DESTRUCTIVE='force|delete|\-f'
WILL_REMOVE_PROTECTED_BRANCH=':'${PROTECTED_BRANCH}

POLICY_GIT_FP="Force push not allowed for branch: \\n   $(tput bold)${CURRENT_BRANCH}$(tput sgr0)"
POLICY_GIT_RM="Delete not allowed for branch: \\n   $(tput bold)${CURRENT_BRANCH}$(tput sgr0)"
POLICY_LINT="See var/logs/lint.log and fix errors before pushing"

# ==============================
# Abort if policy breached
# ==============================
do_exit(){
    printc " ✗\\n" "red" true
    printc "✗  ${1}\\n" "red"
    printf -- "$(tput setaf 9)---------------------------------------------\\n$(tput sgr0)"
    exit 1
}

# ==============================
# Release version
# ==============================
do_release(){
    log "release" "RELEASE STARTED"
    printc "$(tput bold)➜  Release started\\n$(tput sgr0)"  && printc "➜  Uploading release to S3..."
    cd "$PWD" && scripts/slack/notify.pl "${R_ACTION_DATA}" "${BUILD_DATA}"

    STATUS=$(s3_sync "${INSTALLER_ABS_PATH}" "${S3_PROJECT_ROOT}";echo $?)
    if [ ! ${STATUS} -eq 0 ]; then
       R_ACTION_DATA="action:release;status:fail;user:${DEPLOYER}"
       release_fail "Error uploading project installer to S3." "${R_ACTION_DATA}" true "suffix"
    fi

    STATUS=$(s3_acl "${S3_PROJECT_ROOT}clogger-installer.sh" "public";echo $?)
    if [ ! ${STATUS} -eq 0 ]; then
        R_ACTION_DATA="action:release;status:fail;user:${DEPLOYER}"
        release_fail "Error setting S3 ACL on project installer." "${R_ACTION_DATA}" true "suffix"
    fi

    STATUS=$(s3_sync "${BIN_DIR_ABS_PATH}" "${S3_DIST_ROOT}" true;echo $?)
    if [ ! ${STATUS} -eq 0 ]; then
        R_ACTION_DATA="action:release;status:fail;user:${DEPLOYER}"
        release_fail "Error uploading distributable to S3." "${R_ACTION_DATA}" true "suffix"
    fi

    STATUS=$(s3_acl "${S3_DIST_ROOT}" "public" true;echo $?)
    if [ ! ${STATUS} -eq 0 ]; then
        R_ACTION_DATA="action:release;status:fail;user:${DEPLOYER}"
        release_fail "Error setting S3 ACL on distributable." "${R_ACTION_DATA}" true "suffix"
    fi

    R_ACTION_DATA="action:release;status:success;user:${DEPLOYER}"
    release_success "Release complete." "${R_ACTION_DATA}" true "suffix"
}

# ==============================
# Build version
# ==============================
do_build(){
    MACHINE_OS=$(machine_os)
    cd "$PWD" && scripts/slack/notify.pl "${B_ACTION_DATA}" "${BUILD_DATA}"
    log "build.temp" && log "build.temp" "BUILD STARTED: ${BUILD_ID}" true
    printc "$(tput bold)➜  Build started\\n$(tput sgr0)" && printc "➜  Building distributable..."

    STATUS=$(cd "$PWD" && pp -v -a 'includes/header.txt;header.txt' -a 'includes/cacert.pem;cacert.pem' -X Perl::Critic -C -x -o bin/clogger clogger.pl >> var/logs/build.temp.log 2>&1;echo $?)

    if [ "${STATUS}" != 0 ]; then
        B_ACTION_DATA="action:build;status:fail;user:${DEPLOYER}"
        build_fail "Error while building." "${B_ACTION_DATA}" true "suffix"
    fi

    if [ "${MACHINE_OS}" == 'Linux' ]; then
        cd "$PWD" && md5sum -q bin/clogger > bin/clogger.checksum
    else
        cd "$PWD" && md5 -q bin/clogger > bin/clogger.checksum
    fi

    B_ACTION_DATA="action:build;status:success;user:${DEPLOYER}"
    build_success "Build complete." "${B_ACTION_DATA}" true "suffix"
}

printc "➜  Checking policy compliance..."

if [[ ${PUSH_COMMAND} =~ $IS_DESTRUCTIVE ]] && [ ${CURRENT_BRANCH} = ${PROTECTED_BRANCH} ]; then
  do_exit "${POLICY_GIT_FP}"
fi

if [[ ${PUSH_COMMAND} =~ $IS_DESTRUCTIVE ]] && [[ ${PUSH_COMMAND} =~ ${PROTECTED_BRANCH} ]]; then
  do_exit "${POLICY_GIT_FP}"
fi

if [[ ${PUSH_COMMAND} =~ ${WILL_REMOVE_PROTECTED_BRANCH} ]]; then
  do_exit "${POLICY_GIT_RM}"
fi

printf "$(tput setaf 40) ✓\n$(tput sgr0)"

lint

if [ $? != 0 ]; then
    do_exit "${POLICY_LINT}"
else
    printf "$(tput setaf 40) ✓\n$(tput sgr0)"
    rm 'var/logs/lint.log'
fi

printc "✓  Policy satisfied." "green" "suffix"

if [ ${CURRENT_BRANCH} = ${PROTECTED_BRANCH} ]; then
  B_ACTION_DATA="action:build;status:start;user:${DEPLOYER}"
  R_ACTION_DATA="action:release;status:start;user:${DEPLOYER}"
  do_build
  do_release
fi

printc "➜  Pushing to remote... \\n" "green"
printf -- "---------------------------------------------\\n$"

exit 0