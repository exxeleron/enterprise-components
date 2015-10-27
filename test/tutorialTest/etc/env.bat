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
set EC_ETC_PATH=%EC_SYS_PATH%/bin/ec/test/tutorialTest/etc/

set EC_SYS_ID=TutorialTest
set EC_SYS_TYPE="FUNC_TYPE"

REM ---- yak enviroment ----
SET YAK_PATH=%EC_SYS_PATH%\bin\yak
set YAK_OPTS=-c %EC_SYS_PATH%/bin/ec/test/tutorialTest/etc/system.cfg -s %EC_SYS_PATH%/data/test/tutorialTest/yak/yak.status -l %EC_SYS_PATH%/log/test/tutorialTest/yak/yak.log
SET PATH=%YAK_PATH%;%PATH%

ECHO env for system %EC_SYS_ID%/%EC_SYS_TYPE% loaded


GOTO END
:NOBIN
ECHO Expected to find %EC_SYS_PATH%\bin directory. Expecting to run env.bat from the top level ec system directory.
GOTO END
:NOQ
ECHO Missing q binary. Please install q in %EC_SYS_PATH%\bin\q\ directory, see ec\tutorial\Installation.md for instructions.
:END

