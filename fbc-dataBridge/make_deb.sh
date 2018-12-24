#!/bin/bash
#===============================================================================
#
#          FILE: make_deb.sh
#
#         USAGE: ./make_deb.sh -i roadDB.deb
#
#   DESCRIPTION: To make deb file for roadDB
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Ken Chen, <Ken.Chen@ygomi.com>
#  ORGANIZATION: YGOMI
#       CREATED: 2016-03-07
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

SCRIPT_VER="0.1.0"
SCRIPT_FILE=`readlink -f $0`
SCRIPT_DIR=$(dirname ${SCRIPT_FILE})
RUN_DIR=`pwd`

#-----------------------------------------------------------------------
# log4bash
#-----------------------------------------------------------------------
function log4bash_init()
{
    local log_level=$1;

    if [ $log_level == "DEBUG" ]; then
        LOG_LEVEL=1
    elif [ $log_level == "INFO" ]; then
        LOG_LEVEL=2
    elif [ $log_level == "WARN" ]; then
        LOG_LEVEL=3
    elif [ $log_level == "ERROR" ]; then
        LOG_LEVEL=4
    else
        ERROR "Unknown level $log_level"
    fi
}

# default level
log4bash_init "INFO"
log4bash_init "DEBUG"

# Log color
declare -r LOG_DEFAULT_COLOR="\033[0m"
declare -r LOG_DEBUG_COLOR="\033[1;34m"
declare -r LOG_INFO_COLOR="\033[1m"
declare -r LOG_WARN_COLOR="\033[1;33m"
declare -r LOG_ERROR_COLOR="\033[1;31m"

log () {
    local log_text=$1
    local log_level_num=$2
    local log_level_name=$3
    local log_color=$4

    if [[ $log_level_num -ge $LOG_LEVEL ]]; then
        echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level_name}] ${log_text}${LOG_DEFAULT_COLOR}";
    fi

    return 0;
}

DEBUG()     { log "$1" 1 "DEBUG" "${LOG_DEBUG_COLOR}"; }
INFO()      { log "$1" 2 "INFO" "${LOG_INFO_COLOR}"; }
WARN()      { log "$1" 3 "WARN" "${LOG_WARN_COLOR}"; }
ERROR()     { log "$1" 4 "ERROR" "${LOG_ERROR_COLOR}"; cd $RUN_DIR; exit 1; }

#-----------------------------------------------------------------------
# check parameter
#-----------------------------------------------------------------------

function usage ()
{
cat <<- EOT

    Usage: $0 [options] [--]

    Options:
        -i|file            Output deb file name
        -h|help            Display this message
        -v|version         Display script version

    Example:
        ./make_deb.sh -i roadDB.deb

EOT
}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

DEB_PATH=0

while getopts "i:hv" opt
do
    case $opt in

        i|file)
            DEB_PATH=$OPTARG
            ;;

        h|help)
            usage
            exit 0
            ;;

        v|version)
            echo "$0 -- Version $SCRIPT_VER"
            exit 0
            ;;

        \?)
            usage
            exit 1
            ;;

    esac    # --- end of case ---
done
shift $(($OPTIND-1))

# verify whether file extenstion is equal to deb
if [[ "${DEB_PATH}" == "0" ]]; then
    usage
    ERROR "need DEB file name\n"
fi

if [[ "${DEB_PATH##*.}" != "deb" ]]; then
    usage
    ERROR "deb file's extenstion needs to be equal to deb\n"
fi

#-----------------------------------------------------------------------
# change dir and remove temporary files
#-----------------------------------------------------------------------
cd $SCRIPT_DIR && rm -rf *deb

if [[ -n "$RDB_VERSION" ]]; then
    sed -i "s#BUILD_VERSION#$RDB_VERSION#g" "$SCRIPT_DIR/src/DEBIAN/control"
else
    sed -i "s#BUILD_VERSION#0.0.0.0#g" "$SCRIPT_DIR/src/DEBIAN/control"
fi

find ./src -name '.DS_Store' -print0 | xargs -0 -I{} rm -rf {}
find ./src -name '.gitignore' -print0 | xargs -0 -I{} rm -rf {}

#-----------------------------------------------------------------------
# create deb
#-----------------------------------------------------------------------
INFO "Creating ${DEB_PATH} ..."
DEBUG "dpkg -b ./src ${DEB_PATH}"
chmod 755 -R ./src
dpkg -b ./src "$DEB_PATH"
if [ $? != 0 ] || [ ! -f "${DEB_PATH}" ]; then
    ERROR "creation of ${DEB_PATH} failed!"
fi

cd $RUN_DIR
INFO "Done. Created: ${DEB_PATH}"
