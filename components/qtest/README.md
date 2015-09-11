## **`qtest` component**
`qtest` - component for writing unit, functional and integration tests for projects in q programming language with special support for `ec`.
Component is located in the `ec/components/qtest` directory.

### Functionality
- execution of tests organized into test suits
- test cases defined as q functions
- set of convenient assertions
- integration with `enterprise-components` - process management helper functions, remote assertions
- facilities for test debugging
- result export to xml file (compatible with `JUnit` format)

### Configuration
Configuration and environment on the example of [functional tests](../hdbWriter/test/) for the [`hdbWriter`](../hdbWriter/) component.
See also [test example](example) - example of `qtest` usage. 

#### Test structure and environment
It is recommended to setup test environment as small system using enterprise components' configuration set.

Test sources and configuration directory:
- [`ec/components/hdbWriter/`](../hdbWriter/) - the `hdbWriter` component
- [`ec/components/hdbWriter/hdbWriter.q`](../hdbWriter/hdbWriter.q) - `hdbWriter` component source
- [`ec/components/hdbWriter/test/`](../hdbWriter/test/) - `hdbWriter` test directory
- [`ec/components/hdbWriter/test/hdbWriter_functionalTest.q`](../hdbWriter/test/hdbWriter_functionalTests.q) - functional tests source
- [`ec/components/hdbWriter/test/etc/`](../hdbWriter/test/etc/) - configuration of the test environment

Recommended test workspace directory structure prepared for test execution:
- `bin/ec/` - enterprise components package
- `bin/yak/` - yak package
- `bin/q/` - q package

#### system.cfg example
[`system.cfg`](../hdbWriter/test/etc/system.cfg) defines three components:
- `t.run` - process which is driving test suite execution. It loads `hdbWriter_functionalTests.q` file 
  and executes all test cases defined in it 
- `t.hdbw` - instance of `hdbWriter` which is being tested  
- `t.hdb` - additional process used to mock external dependencies of the process which is actually tested - `t.hdbw`

```cfg
[group:t]
  [[t.run]]
    command = "q qtestRunner.q"
    type = q:qtest/qtestRunner
    port = ${basePort}
    memCap = 10000
    testFiles = ${EC_SYS_PATH}/bin/ec/components/hdbWriter/test/hdbWriter_functionalTests.q
    testNamespaces = .testHdbWriter

  [[t.hdbw]]
    command = "q hdbWriter.q"
    type = q:hdbWriter/hdbWriter
    port = ${basePort} + 1
    memCap = 10000
    cfg.dstHdb = t.hdb

  [[t.hdb]]
    command = "q hdbMock.q"
    type = q:mock/hdbMock
    port = ${basePort} + 2
    memCap = 10000
```

### Startup
source env
```bash
KdbSystemDir> source bin/ec/components/hdbWriter/test/etc/env.sh
```
in case of windows
```bat
KdbSystemDir> bin\ec\components\hdbWriter\test\etc\env.bat
```

Execute tests:
```bash
> # start tests
> yak start t.run
> # check progress
> yak log t.run
> # check failures only
> yak err t.run
```

#### Test results

A quick way to see see if the tests have passed is to look at the end of the `t.run` process log.
A line similar to the following

```
INFO  2015.09.11 08:23:43.521 qtest - component qtest initialized with 0 fatals, 0 errors, 0 warnings
```

indicates that all tests have been successful.

More detailed test results can be accessed via `.test.report[]` on the `t.run` component:
```q
q).test.report[]
```
Result contains a dictionary containing following tables:
- `testCases` - detailed information about all executed test cases.
- `testCasesFailed` - as in `testCases`, excluding successful test cases.
- `asserts` - detailed information about all executed assertions.
- `assertsFailed` - as in `asserts`, excluding successful assertions.
- `interfaceCoverage` - information about test coverage basing on the interface level function calls

#### Continuous Integration
Test result can be exported to xml file in the format compatible with the `JUnit`  
which is commonly supported by continuous integration systems (for example Jenkins).

Generation of the report is triggered by adding command line argument `-JUnitExport XML_REPORT_PATH` to the yak command (see below for an example).
It activates generation of the xml report at the end of `.test.run` function.

Another command line argument which is useful for test automation is `-runAndQuit` 
which triggers termination of the test runner process at the end of `.test.run` function.

Example of commands to execute tests in the ci environment:
```bash
# 1. prepare dir structure with bin/ec, bin/q, bin/yak and etc
# 2. source environment
> source etc/env.sh
# 3. start tests with proper command line arguments (assuming $WORKSPACE is pointing to the current workspace dir) 
> yak console t.run -a "-JUnitExport $WORKSPACE/report.xml -runAndQuit"
# 4. use report.xml as the result of the test
```

### Writing tests

#### Test suite definition
Entire testSuite should be defined in one namespace e.g. `.testHdbWriter`.

##### Suite name
Test suite name should be specified as string in `testSuite` variable, e.g. `.testHdbWriter.testSuite`

##### Fixture `setUp`
`setUp` - fixture executed before each testCase, 
i.e. `.testHdbWriter.setUp` is invoked before each test case in the `.testHdbWriter.test` namespace.

##### Fixture `tearDown`
`tearDown` - fixture executed after each testCase, 
i.e. `.testHdbWriter.tearDown` is invoked after each test case in the `.testHdbWriter.test` namespace.

##### Test cases
Test cases are defined as:
- functions in `.test` namespace, e.g. all function the `.testHdbWriter.test` namespace
- function name should be descriptive, e.g. `.testHdbWriter.test.smokeTest_insertTradeDay` or `.testHdbWriter.test.scenario2_appendTradeToParitionWithData`
- function body defines actual test case
- test function does not take any input arguments

#### Process management
Tests setup usually consists of multiple processes
- test runner, e.g. `t.run`
- tested process, e.g. `t.hdbw`
- test environment, e.g. `t.hdb`

Following set of functions allow easy process management in `setUp`, `tearDown` and test case functions:
- `.test.start[procNames]` - helper function is used to start processes.
- `.test.stop[procNames]` - helper function is used to stop processes.
- `.test.clearProcDir[procNames]` - helper function is used clear all the data processes' `dataPath`'s.

Remote execution of commands from the test code should be executed via `.test.h` function:
- `.test.h[componentId;tree]`

#### Assertions

##### Standard assertions
Standard assertions have following input parameters:
- msg:STRING - first argument is always a message describing purpose of the assertion
- actual:ANY - second argument is always actual analyzed value
- expected:ANY - third argument is an expected value (not all assertions have this arg)

List of available assertions:
- `.assert.match[msg;actual;expected]`
- `.assert.true[msg;actual]`
- `.assert.false[msg;actual]`
- `.assert.type[msg;actual;expected]`
- `.assert.contains[msg;actual;expected]`
- `.assert.in[msg;actual;expected]`
- `.assert.within[msg;actual;expected]`
- `.assert.allIn[msg;actual;expected]`
- `.assert.allWithin[msg;actual;expected]`
- `.assert.lessEq[msg;actual;expected]`
- `.assert.moreEq[msg;actual;expected]`
- `.assert.matchModel[msg;actual;expected]`

A special type of assertion is `.assert.fail`:
- `.assert.fail[msg;expression;expectedSig]` - designed for capturing q-signals,
   second argument in this case is `q parse tree` that after execution is expected to throw a signal (expectedSig).

##### Remote assertions
`qtest` has another type of assertions - remote assertions.
Some tests consist of multiple processes and require testing of parallel execution and asynchronous calls.
For this purpose a set of `remote assertions` is implemented.

All remote assertions have following arguments:
- msg:STRING - first argument is always message describing purpose of the assertion
- serverName:SYMBOL - logical name of the remote component
- expression:LIST -  `q parse tree` that should be executed on `serverName` process
Additionally assertions with periodic re-execution of the command have following arguments:
- checkPeriodMs:INT - `expression` will be executed on `serverName` every `checkPeriodMs` until the test condition is fulfilled.
- maxWaitMs:INT - maximum time for re-execution in milliseconds

List of available remote assertions:
- `.assert.remoteFail[msg;serverName;expression;expectedSig]` - equivalent of `.assert.fail` for the code that should be executed on remote process.
- `.assert.remoteWaitUntilTrue[msg;serverName;expression;checkPeriodMs;maxWaitMs]` - execute remotely until `expression` is TRUE
- `.assert.remoteWaitUntilEqual[msg;serverName;expression;expected;checkPeriodMs;maxWaitMs]` - execute remotely until `expression` is `expected`

##### Assertion results
Each assertion result is inserted into `.test.asserts` table:
```q
q).test.asserts
```

which consists of following columns:
- testSuite:SYMBOL - test suite name
- testCase:SYMBOL - full test case function name
- assert:SYMBOL - assertion description (see `msg` argument in assertions)
- assertType:SYMBOL - assertion type, e.g. `MATH, `TRUE, `FALSE, `WAIT_UNTIL_TRUE, 
- result:SYMBOL - assertion result `SUCCESS or `FAILURE
- failureInfo:SYMBOL - detailed description of the failure in case result=`FAILURE
- expected:ANY - expected value passed to the assertion
- actual:ANY - actual value passed to the assertion

#### Failure debugging
`.test.printTest[tCase]` prints:
- test case failure information 
- setUp code
- test case code
- tearDown code
- re-execution statement using `.test.runOneTest[]`

e.g.:
```q
q).test.printTest`.testHdbWriter.test.scenario2_appendTradeToParitionWithData
```

This allows easy execution of the entire test case line by line.

##### Assertions during debugging
If test case is executed line by line, user can dynamically see detailed assertion information.
- in case of assertion success, assertion returns simply `SUCCESS symbol
- in case of assertion failure, assertion returns dictionary with detailed information, 
  containing fields as columns in .test.asserts (see `Assertion results` chapter above)

##### Re-execution of one testCase
One test case can be re-executed using `.test.runOneTest` function, e.g.:
```q
q).test.runOneTest`.testHdbWriter.test.invalidOrder_finalizeWithoutOrganize
```
  
### Further reading
- [qtest example](example) - example of `qtest` usage
- [`hdbWriter` tests](../hdbWriter/test/) - example of functional tests for `hdbWriter` component
- [`qsl/tabs` tests](../../libraries/qsl/test/tabs/) - example of functional tests for `qsl/tabs` library
