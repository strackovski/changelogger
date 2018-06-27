#!/bin/bash
# ============================================================
#
# Make helpers
#
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
# ============================================================

SEP_LINE="[$(date +%Y/%m/%d-%H:%M:%S)] -> =====================================================================";

# ============================================================
#  *  WRITE TO LOG FILE
#
#  $1 - log name
#  $2 - log message
# ============================================================
log () {
    if [ $# -eq 0 ] || [ -z "$1" ]; then
        echo "Missing arguments for log"
        exit 1;
    fi

    if [ -z "$2" ]; then
        TEXT=${SEP_LINE}
    else
        TEXT=${2}
    fi

    if [ "$3" == true ]; then
        printf -- "[$(date +%Y/%m/%d-%H:%M:%S)] -> %s\\n%s\\n" "${TEXT}" "${SEP_LINE}" >> var/logs/"${1}".log
    else
        printf -- "%s\\n" "${TEXT}" >> var/logs/"${1}".log
    fi
}

# ============================================================
#  *  PRINT TEXT
#
#  $1 - text to print
#  $2 - color name
#  $3 - print line separator after text (true|false)
# ============================================================
printc(){
    if [ $# -eq 0 ] || [ -z "$1" ]; then
        echo "Missing arguments for printc"
        exit 1;
    fi

    if [ -z "$2" ]; then
        COLOR='DEFAULT'
    else
        COLOR=${2}
    fi

    case "${COLOR}" in
        red)    COLOR_CODE=9;;
        blue)   COLOR_CODE=69;;
        black)  COLOR_CODE=30;;
        white)  COLOR_CODE=97;;
        green)  COLOR_CODE=40;;
        *)      COLOR_CODE=39;;
    esac

    if [ "${3}" == "suffix" ]; then
        printf "%s${1}%s" "$(tput setaf ${COLOR_CODE})" "$(tput sgr0)"
        printf -- '\n---------------------------------------------\n'
    elif [ "${3}" == "prefix" ]; then
        printf -- '\n---------------------------------------------\n'
        printf "%s${1}%s" "$(tput setaf ${COLOR_CODE})" "$(tput sgr0)"
    else
        printf "%s${1}%s" "$(tput setaf ${COLOR_CODE})" "$(tput sgr0)"
    fi

}

# ============================================================
#  *  PRINT FAIL MESSAGE BLOCK, $1 - the message
# ============================================================
fail_msg () {
    printc " ✗\\n" "red" true
    printc "✗  ${1}\\n" "red"
}

# ============================================================
#  *  PRINT SUCCESS MESSAGE BLOCK, $1 - the message
# ============================================================
success_msg () {
    printc " ✓\\n" "green" true
    printc "✓  ${1}\\n" "green"
}

# ============================================================
#  *  GET MACHINE OPERATING SYSTEM
# ============================================================
machine_os () {
    OS_NAME=$(uname -s)

    case "${OS_NAME}" in
        Linux*)     MACHINE_OS=Linux;;
        Darwin*)    MACHINE_OS=macOS;;
        CYGWIN*)    MACHINE_OS=Cygwin;;
        MINGW*)     MACHINE_OS=MinGw;;
        *)          MACHINE_OS="UNKNOWN:${OS_NAME}"
    esac

    echo "${MACHINE_OS}" && return 0
}

# ============================================================
#  *  LINT SOURCE USING perltidy AND Perl::Critic
#     Tidy will fix code style automatically
# ============================================================
lint () {
    printc "➜  Running tidy..."
    for FILE in lib/ChangeLogger/*.pm
    do
      perltidy "$FILE" -l=120
      mv "$FILE".tdy "$FILE"
    done

    printc " ✓\\n" "green"
    printc "➜  Linting source code..."

    STATUS=$(perlcritic --quiet lib/ChangeLogger/*.pm >> var/logs/lint.log 2>&1;echo $?)
    return ${STATUS}
}

# ============================================================
#  *  S3 Sync
# ============================================================
s3_sync () {
    if [ $# -eq 0 ] || [ -z "$1" ] || [ -z "$2" ]; then
        return 11
    fi

    SOURCE="$1"
    DESTINATION="$2"
    LOG_FILE="$PWD/var/logs/release.temp.log"

    if [ "$3" == true ]; then
        STATUS=$(s3cmd sync -v --no-progress --recursive --exclude ".gitkeep" "${SOURCE}" "${DESTINATION}" >> "${LOG_FILE}" 2>&1;echo $?)
    else
        STATUS=$(s3cmd sync -v --no-progress --exclude ".gitkeep" "${SOURCE}" "${DESTINATION}" >> "${LOG_FILE}" 2>&1;echo $?)
    fi

    if [ ${STATUS} -eq 0 ]; then
        return 0
    else
        return 13
    fi
}

# ============================================================
#  *  S3 Set ACL
# ============================================================
s3_acl () {
    if [ $# -eq 0 ] || [ -z "$1" ] || [ -z "$2" ]; then
        return 11
    fi

    KEY="$1"
    ACL="--acl-$2"
    LOG_FILE="$PWD/var/logs/release.temp.log"

    if [ "$3" == true ]; then
        STATUS=$(s3cmd setacl -v --recursive --no-progress "${KEY}" "${ACL}" >> "${LOG_FILE}" 2>&1;echo $?)
    else
        STATUS=$(s3cmd setacl -v --no-progress "${KEY}" "${ACL}" >> "${LOG_FILE}" 2>&1;echo $?)
    fi

    if [ ${STATUS} -eq 0 ]; then
        return 0
    else
        return 13
    fi
}

# ============================================================
#  *  PRINT FAIL MESSAGE BLOCK, $1 - the message
# ============================================================
report () {
    printc "➜  Publishing report..."
    if [ "${1}" == "build" ]; then
        T=$(cd "$PWD" && cat "var/logs/build.temp.log" | tee -a "var/logs/build.log" "var/logs/${BUILD_ID}.log" > /dev/null 2>&1)
        TST=$(s3cmd put --acl-public --guess-mime-type --quiet "var/logs/${BUILD_ID}.log" "${S3_REPORTS_ROOT_URL}builds/${BUILD_ID}.log" > /dev/null 2>&1)
        rm "var/logs/build.temp.log"
        rm "var/logs/${BUILD_ID}.log"
    elif [ "${1}" == "release" ]; then
        T=$(cd "$PWD" && cat "var/logs/release.temp.log" | tee -a "var/logs/release.log" "var/logs/${BUILD_ID}.log" > /dev/null 2>&1)
        TST=$(s3cmd put --acl-public --guess-mime-type --quiet "var/logs/${BUILD_ID}.log" "${S3_REPORTS_ROOT_URL}releases/${BUILD_ID}.log" > /dev/null 2>&1)
        rm "var/logs/release.temp.log"
        rm "var/logs/${BUILD_ID}.log"
    fi

    printc " ✓\\n" "green"
}

# ============================================================
#  *  PRINT FAIL MESSAGE BLOCK, $1 - the message
# ============================================================
build_fail () {
    REASON=$1
    ACTION_DATA=$2
    SEND_REPORT=$3
    SEP_POS=$4

    printc " ✗\\n" "red"
    if [ "${SEND_REPORT}" == true ]; then
        report "build"
    fi

    cd "$PWD" && scripts/slack/notify.pl "${ACTION_DATA}" "${BUILD_DATA}" "${BUILD_REPORT_URL}" "" "${REASON}"
    printc "✗  FAILED: ${REASON}" "red" "${SEP_POS}"

    exit 1
}

# ============================================================
#  *  PRINT FAIL MESSAGE BLOCK, $1 - the message
# ============================================================
release_fail () {
    REASON=$1
    ACTION_DATA=$2
    SEND_REPORT=$3
    SEP_POS=$4

    printc " ✗\\n" "red"
    if [ "${SEND_REPORT}" == true ]; then
        report "release"
    fi

    cd "$PWD" && scripts/slack/notify.pl "${ACTION_DATA}" "${BUILD_DATA}" "${RELEASE_REPORT_URL}" "" "${REASON}"
    printc "✗  FAILED: ${REASON}" "red" "${SEP_POS}"

    exit 1
}

# ============================================================
#  *  PRINT FAIL MESSAGE BLOCK, $1 - the message
# ============================================================
build_success () {
    MESSAGE=$1
    ACTION_DATA=$2
    SEND_REPORT=$3
    SEP_POS=$4

    printc " ✓\\n" "green"
    log "build.temp"
    log "build.temp" "BUILD COMPLETE" true

    if [ "${SEND_REPORT}" == true ]; then
        report "build"
    fi

    cd "$PWD" && scripts/slack/notify.pl "${ACTION_DATA}" "${BUILD_DATA}" "${BUILD_REPORT_URL}"
    printc "✓  ${MESSAGE}" "green" "${SEP_POS}"
}

# ============================================================
#  *  PRINT FAIL MESSAGE BLOCK, $1 - the message
# ============================================================
release_success () {
    MESSAGE=$1
    ACTION_DATA=$2
    SEND_REPORT=$3
    SEP_POS=$4

    printc " ✓\\n" "green"
    log "release.temp"
    log "release.temp" "RELEASE COMPLETE" true

    if [ "${SEND_REPORT}" == true ]; then
        report "release"
    fi

    cd "$PWD" && scripts/slack/notify.pl "${ACTION_DATA}" "${BUILD_DATA}" "${RELEASE_REPORT_URL}" "${RELEASE_DOWNLOAD_URL}"
    printc "✓  ${MESSAGE}" "green" "${SEP_POS}"
}
