@ECHO OFF
IF NOT EXIST BIN GOTO NOBIN

set EC_SYS_PATH=%CD%

REM  ---- q enviroment ----
set QHOME=%EC_SYS_PATH%\bin\q
set QLIC=%EC_SYS_PATH%\etc

REM ---- yak enviroment ----
set YAK_PATH=%EC_SYS_PATH%\bin\yak
set YAK_OPTS=-c %EC_SYS_PATH%/etc/system.cfg -s %EC_SYS_PATH%/data/yak/yak.status -l %EC_SYS_PATH%/log/yak/yak.log

REM ---- path ----
set PATH=%QHOME%\w32;%YAK_PATH%;%PATH%

REM ---- ec enviroment ----
set EC_QSL_PATH=%EC_SYS_PATH%/bin/ec/libraries/qsl/
set EC_ETC_PATH=%EC_SYS_PATH%/etc

set EC_SYS_ID="DemoSystem"
set EC_SYS_TYPE="Lesson05"

GOTO END
:NOBIN
ECHO expected bin subdirectory
:END

