# Bash file included with settings

BASEDIR=`dirname $0`
PLATFORM=`uname | tr '[:upper:]' '[:lower:]'`
CLUSTER_NAME="vagrant-${PLATFORM}"