@ECHO OFF
IF NOT EXIST BIN GOTO NOBIN

SET EC_SYS_PATH=%CD%

REM  ---- q enviroment ----
IF EXIST %EC_SYS_PATH%\bin\q\w32\q.exe SET QHOME=%EC_SYS_PATH%\bin\q
IF EXIST %EC_SYS_PATH%\bin\q\w64\q.exe SET QHOME=%EC_SYS_PATH%\bin\q
SET PATH=%QHOME%\w64;%QHOME%\w32;%PATH%
WHERE /q q.exe || GOTO NOQ
REM in case of q64bit - it is recommended to SET QLIC as following: QLIC=%EC_SYS_PATH%\etc

REM ---- ec enviroment ----
SET EC_QSL_PATH=%EC_SYS_PATH%/bin/ec/libraries/qsl/
SET EC_ETC_PATH=%EC_SYS_PATH%/etc

SET EC_SYS_ID="DemoSystem"
SET EC_SYS_TYPE="Lesson02"

REM ---- yak enviroment ----
SET YAK_PATH=%EC_SYS_PATH%\bin\yak
SET YAK_OPTS=-c %EC_ETC_PATH%/system.cfg -s %EC_SYS_PATH%/data/test/%EC_SYS_ID%/yak/yak.status -l %EC_SYS_PATH%/log/test/%EC_SYS_ID%/yak/yak.log
SET PATH=%YAK_PATH%;%PATH%

ECHO env for system %EC_SYS_ID%/%EC_SYS_TYPE% loaded


GOTO END
:NOBIN
ECHO Expected to find %EC_SYS_PATH%\bin directory. Expecting to run env.bat from the top level ec system directory.
GOTO END
:NOQ
ECHO Missing q binary. Please install q in %EC_SYS_PATH%\bin\q\ directory, see ec\tutorial\Installation.md for instructions.
:END
