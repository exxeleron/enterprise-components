@ECHO OFF
IF NOT EXIST BIN GOTO NOBIN

set EC_SYS_PATH=%CD%

REM  ---- q enviroment ----
IF EXIST %EC_SYS_PATH%\bin\q\w32\q.exe set QHOME=%EC_SYS_PATH%\bin\q
IF EXIST %EC_SYS_PATH%\bin\q\w64\q.exe set QHOME=%EC_SYS_PATH%\bin\q
set PATH=%QHOME%\w64;%QHOME%\w32;%PATH%
q.exe 2> NUL
IF %ERRORLEVEL%==9009 GOTO NOQ
REM in case of q64bit - it is recomended to set QLIC as following: QLIC=%EC_SYS_PATH%\etc

REM ---- yak enviroment ----
set YAK_PATH=%EC_SYS_PATH%\bin\yak
set YAK_OPTS=-c %EC_ETC_PATH%/system.cfg -s %EC_SYS_PATH%/data/yak/yak.status -l %EC_SYS_PATH%/log/yak/yak.log
set PATH=%YAK_PATH%;%PATH%

REM ---- ec enviroment ----
set EC_QSL_PATH=%EC_SYS_PATH%/bin/ec/libraries/qsl/
set EC_ETC_PATH=%EC_SYS_PATH%/etc

set EC_SYS_ID="DemoSystem"
set EC_SYS_TYPE="Lesson05"
echo env for system %EC_SYS_ID%/%EC_SYS_TYPE% loaded

GOTO END
:NOBIN
ECHO Expected to find %EC_SYS_PATH%\bin directory. Expecting to run env.bat from the top level ec system directory.
GOTO END
:NOQ
ECHO Missing q binary. Please install q in %EC_SYS_PATH%\bin\q\ directory, see ec\tutorial\Installation.md for instructions.
:END
