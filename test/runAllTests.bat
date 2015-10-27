REM ---------------------------------------------------------------------------
REM                     executing all qtest-style tests
REM ---------------------------------------------------------------------------

@ECHO OFF
IF NOT EXIST BIN GOTO NOBIN
SET EC_ROOT_PATH=%CD%

REM ---- qsl/handle tests -----------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\libraries\qsl\test\handle\etc\env.bat
yak console t.run -a " -quitAfterRun"

REM ---- qsl/tabs tests -------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\libraries\qsl\test\tabs\etc\env.bat
yak console t.run -a " -quitAfterRun"

REM ---- rdb tests ------------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\components\rdb\test\etc\env.bat
yak console t.run -a " -quitAfterRun"

REM ---- hdb tests ------------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\components\hdb\test\etc\env.bat
yak console t.run -a " -quitAfterRun"

REM ---- hdbWriter tests ------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\components\hdbWriter\test\etc\env.bat
yak console t.run -a " -quitAfterRun"

REM ---- Lesson1 tests ------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\test\tutorialTest\etc\env.bat
yak console t.run1 -a " -quitAfterRun"

REM ---- Lesson2 tests ------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\test\tutorialTest\etc\env.bat
yak console t.run1 -a " -quitAfterRun"

REM ---- Lesson2 tests ------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\test\tutorialTest\etc\env.bat
yak console t.run2 -a " -quitAfterRun"

REM ---- Lesson3 tests ------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\test\tutorialTest\etc\env.bat
yak console t.run3 -a " -quitAfterRun"

REM ---- Lesson4 tests ------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\test\tutorialTest\etc\env.bat
yak console t.run4 -a " -quitAfterRun"

REM ---- Lesson5 tests ------------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\test\tutorialTest\etc\env.bat
yak console t.run5 -a " -quitAfterRun"


REM ---- collect test results -------------------------------------------------
CD %EC_ROOT_PATH%
CALL bin\ec\test\collectTestResults\etc\env.bat
yak console t.collectResults

REM ---------------------------------------------------------------------------
GOTO END
:NOBIN
ECHO Expected to find %EC_ROOT_PATH%\bin directory. Expecting to run env.bat from the top level ec system directory.
:END
