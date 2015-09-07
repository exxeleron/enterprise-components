if [ ! -d "bin" ]; then
  echo "Expecting bin subdirectory" && return
fi
export EC_SYS_PATH=${PWD}

# ---- yak environment ---- #
YAK_PATH=$EC_SYS_PATH/bin/yak/
YAK_OPTS="-c $EC_SYS_PATH/etc/system.cfg -v less -s $EC_SYS_PATH/data/yak/yak.status -l $EC_SYS_PATH/log/yak/yak.log"
export YAK_OPTS
. $YAK_PATH/yak_complete_bash.sh
NEWPATH=$YAK_PATH

# ---- q environment ---- #
# search for q binary in bin/q/ (cover MacOS and Linux)
if [ "$(uname)" == "Darwin" ]; then OS_LETTER=m; else OS_LETTER=l; fi
if [ -f "$EC_SYS_PATH/bin/q/${OS_LETTER}32/q" ]; then QHOME=$EC_SYS_PATH/bin/q/ && NEWPATH=$QHOME/${OS_LETTER}32/:$NEWPATH; fi
if [ -f "$EC_SYS_PATH/bin/q/${OS_LETTER}64/q" ]; then QHOME=$EC_SYS_PATH/bin/q/ && NEWPATH=$QHOME/${OS_LETTER}64/:$NEWPATH; fi
# QLIC set to etc/, in case of q64, k4.lic should be placed in $QLIC directory
QLIC=$EC_SYS_PATH/etc/
export QHOME QLIC

# ---- path ---- #
export OLDPATH=${OLDPATH:-$PATH}
PATH=$NEWPATH:$OLDPATH
export PATH
#check if q is available on PATH
command -v q >/dev/null 2>&1 || { echo "Missing q binary. Please install q in $EC_SYS_PATH/bin/q/ directory, see ec/tutorial/Installation.md for instructions." >&2; return; }

# ---- ec environment ---- #
EC_QSL_PATH=${EC_SYS_PATH}/bin/ec/libraries/qsl/
EC_ETC_PATH=${EC_SYS_PATH}/etc
export EC_QSL_PATH EC_ETC_PATH

# ---- cmd prompt decoration ---- #
EC_SYS_ID="DemoSystem"
EC_SYS_TYPE="Lesson03"
export EC_SYS_ID EC_SYS_TYPE
PS1='[${EC_SYS_ID}(${EC_SYS_TYPE})][\u@\h:\w]\$ '
export PS1

