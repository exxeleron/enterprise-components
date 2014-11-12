if [ ! -d "bin" ]; then
  echo "Expecting bin subdirectory" && return
fi
export EC_SYS_PATH=${PWD}

# ---- q environment ---- #
QHOME=$EC_SYS_PATH/bin/q/
QLIC=$EC_SYS_PATH/etc/
export QHOME QLIC

# ---- yak environment ---- #
YAK_PATH=$EC_SYS_PATH/bin/yak/
YAK_OPTS="-c $EC_SYS_PATH/etc/system.cfg -v less -s $EC_SYS_PATH/data/yak/yak.status -l $EC_SYS_PATH/log/yak/yak.log"
export YAK_PATH YAK_OPTS
. $YAK_PATH/yak_complete_bash.sh

# ---- path ---- #
export OLDPATH=${OLDPATH:-$PATH}
PATH=$QHOME/l32:$YAK_PATH:$OLDPATH
# override for Mac OS X
if [ "$(uname)" == "Darwin" ]; then
    PATH=$QHOME/m32:$YAK_PATH:$OLDPATH
fi
export PATH

# ---- ec environment ---- #
EC_QSL_PATH=${EC_SYS_PATH}/bin/ec/libraries/qsl/
EC_ETC_PATH=${EC_SYS_PATH}/etc
export EC_QSL_PATH EC_ETC_PATH

# ---- cmd prompt decoration ---- #
EC_SYS_ID="DemoSystem"
EC_SYS_TYPE="Lesson02"
export EC_SYS_ID EC_SYS_TYPE
PS1='[${EC_SYS_ID}(${EC_SYS_TYPE})][\u@\h:\w]\$ '
export PS1

