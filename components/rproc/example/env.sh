if [ ! -d "bin" ]; then
  echo "Expecting bin subdirectory" && return
fi
export EC_SYS_PATH=${PWD}

# ---- cmd prompt decoration ---- #
EC_SYS_ID="rprocExample"
EC_SYS_TYPE="EXAMPLE"
export EC_SYS_ID EC_SYS_TYPE
PS1='[${EC_SYS_ID}(${EC_SYS_TYPE})][\u@\h:\w]\$ '
export PS1

# ---- ec environment ---- #
EC_QSL_PATH=${EC_SYS_PATH}/bin/ec/libraries/qsl/
EC_ETC_PATH=${EC_SYS_PATH}/bin/ec/components/rproc/example/
export EC_QSL_PATH EC_ETC_PATH

# ---- yak environment ---- #
YAK_PATH=$EC_SYS_PATH/bin/yak/
YAK_OPTS="-c $EC_ETC_PATH/system.cfg -v less -s $EC_SYS_PATH/data/test/${EC_SYS_ID}/yak/yak.status -l $EC_SYS_PATH/log/test/${EC_SYS_ID}/yak/yak.log"
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
which q >/dev/null || echo "Missing q binary. Please install q in $EC_SYS_PATH/bin/q/ directory, see ec/tutorial/Installation.md for instructions."

echo env for system ${EC_SYS_ID}/${EC_SYS_TYPE} loaded
