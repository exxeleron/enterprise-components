# --------------------------------------------------------------------------- #
#                       executing all qtest-style tests                       #
# --------------------------------------------------------------------------- #
if [ ! -d "bin" ]; then
  echo "Expecting bin subdirectory" && return
fi
export EC_ROOT_PATH=${PWD}

# ------ qsl/handle tests --------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/libraries/qsl/test/handle/etc/env.sh
yak console t.run -a " -quitAfterRun"

# ------ qsl/tabs tests ----------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/libraries/qsl/test/tabs/etc/env.sh
yak console t.run -a " -quitAfterRun"

# ------ rdb tests ---------------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/components/rdb/test/etc/env.sh
yak console t.run -a " -quitAfterRun"

# ------ hdb tests ---------------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/components/hdb/test/etc/env.sh
yak console t.run -a " -quitAfterRun"

# ------ hdbWriter tests ---------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/components/hdbWriter/test/etc/env.sh
yak console t.run -a " -quitAfterRun"

# ------ Lesson1 tests ---------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/test/tutorialTest/etc/env.sh
yak console t.run1 -a " -quitAfterRun"

# ------ Lesson2 tests ---------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/test/tutorialTest/etc/env.sh
yak console t.run2 -a " -quitAfterRun"

# ------ Lesson3 tests ---------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/test/tutorialTest/etc/env.sh
yak console t.run3 -a " -quitAfterRun"

# ------ Lesson4 tests ---------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/test/tutorialTest/etc/env.sh
yak console t.run4 -a " -quitAfterRun"

# ------ Lesson5 tests ---------------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/test/tutorialTest/etc/env.sh
yak console t.run5 -a " -quitAfterRun"

# ------ collect test results ----------------------------------------------- #
cd ${EC_ROOT_PATH}
source bin/ec/test/collectTestResults/etc/env.sh
yak console t.collectResults

# --------------------------------------------------------------------------- #
