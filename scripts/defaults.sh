#!/bin/bash
# ============================================================
#
# ChangeLogger makefile defaults
#
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
# ============================================================

# ============================================================
#  *  PROJECT DEFAULTS
# ============================================================
PROJECT_NAME="changelogger"
PROJECT_VERSION="0.1.0"

# ============================================================
#  *  BUILD CONFIGURATION
# ============================================================
BUILD_BRANCHES=('develop' 'master')
DEPLOYER=$(whoami)
CURRENT_BRANCH=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
MACHINE_TYPE=$(uname -m)
OS_NAME=$(uname -s)

if [ "${MACHINE_TYPE}" == "x86_64" ]; then
    ARCHITECTURE="64"
else
    ARCHITECTURE="32"
fi

BUILD_NAME="${PROJECT_NAME} ${PROJECT_VERSION} (${ARCHITECTURE}-bit, ${OS_NAME})"
BUILD_ID=$(uuidgen)
BUILD_ID=$(echo ${BUILD_ID} | tr '[a-z]' '[A-Z]')
BUILD_DATA="id:${BUILD_ID};name:${BUILD_NAME};version:${PROJECT_VERSION};branch:${CURRENT_BRANCH};architecture:${ARCHITECTURE}-bit"

# ============================================================
#  *  RELEASE CONFIGURATION FOR AWS S3 TARGET
# ============================================================
S3_BUCKET_NAME="nv3-org";
S3_BUCKET_HTTP_ROOT="s3.eu-central-1.amazonaws.com/${S3_BUCKET_NAME}"
S3_PROJECT_ROOT="s3://${S3_BUCKET_NAME}/${PROJECT_NAME}/";
S3_DIST_ROOT="${S3_PROJECT_ROOT}dist/current/${ARCHITECTURE}/"
S3_REPORTS_ROOT_URL="s3://${S3_BUCKET_NAME}/ci/${PROJECT_NAME}/reports/"
REPORTS_ROOT_URL="https://${S3_BUCKET_HTTP_ROOT}/ci/${PROJECT_NAME}/reports/"
BUILD_REPORT_URL="${REPORTS_ROOT_URL}builds/${BUILD_ID}.log"
RELEASE_REPORT_URL="${REPORTS_ROOT_URL}releases/${BUILD_ID}.log"
RELEASE_DOWNLOAD_URL="https://${S3_BUCKET_HTTP_ROOT}/${PROJECT_NAME}"
INSTALLER_ABS_PATH="$PWD/scripts/dist/installer.sh"
BIN_DIR_ABS_PATH="$PWD/bin/"
