## **`qtest` testSuite example**

`qtest/example/` directory consists of the following artifacts:
- [`qtest/example/componentX.q`](componentX.q) - test subject - dummy component named `componentX`
- [`qtest/example/test`](test/) - directory with tests for `componentX`
- [`qtest/example/test/etc`](test/etc/) - configuration of the test environment
- [`qtest/example/test/componentX_functionalTests.q`](test/componentX_functionalTests.q) - file with actual tests` definition

### test subject - `componentX`
 
`componentX` is a dummy project which contains one function definition `.componentX.getCols`.
This function will be the actual subject of test.

### test environment

Test environment is defined as small system using enterprise components' configuration set.

Test expects following directory structure:
`bin/ec/` - enterprise components package
`bin/yak/` - yak package
`bin/q/` - q package

[`etc/system.cfg`](test/etc/system.cfg) defines three components:
- `t.run` - process which is driving test suite execution. It loads `componentX_functionalTests.q` file 
  and executes all test cases defined in it 
- `t.componentX` - instance of componentX which is being tested  
- `t.hdb` - additional process used to mock external dependencies of the process which is actually tested - `t.componentX`

### test definition - `.componentXTest`

Entire testSuite is defined in `componentX_functionalTests.q` file in one namespace `.componentXTest`.

#### fixture `setUp`
- `.componentXTest.setUp` - fixture executed before each testCase defined in the `.componentXTest` namespace.
```q
.componentXTest.setUp:{
  .test.start[`t.componentX`t.hdb];
  };
```

`.test.start` helper function is used to startup tested component `t.componentX` (instance of `componentX`) and additional `t.hdb` component (instance of hdb mock). Those two components are being freshly started at the beginning of each test. This increases independence of each test case.

#### fixture `tearDown`

- `.componentXTest.tearDown` - fixture executed after each testCase defined in the `.componentXTest` namespace.
```q
.componentXTest.tearDown:{
  .test.stop[`t.componentX`t.hdb];
  };
```
`.test.stop` helper function is used to stop components started in the `setUp` function - `t.componentX` and `t.hdb`.

#### test suite description

```q
.componentXTest.testSuit:"componentX functional tests";
```

Test suite description is specified as string assigned to `.componentXTest.testSuit` global variable.

#### test cases

Test cases are defined as:
- functions in `.test` sub-namespace
- function name should be descriptive
- function body defines actual test case
- test function does not take any input argument

##### test case 1
Following code defines test described as "call_getCols".

```q
.componentXTest.test.call_getCols:{[]
  // Arrange
  tradeChunk:.componentXTest.genTrade[10;2014.01.01];
  
  // Act
  res:.test.h[`t.componentX](`.componentX.getCols;tradeChunk);
  
  // Assert
  .assert.match["return list of columns"; 
    res; cols tradeChunk];
  };
```

Listed testCase is testing `.componentX.getCols` method.

Three steps are performed
- Arrange.
```q
  tradeChunk:.componentXTest.genTrade[10;2014.01.01];
```
 Test data is generated using helper function `.componentXTest.genTrade` defined for that purpose in `componentX_functionalTests.q` along the rest of the `.componentXTest` test suite definition. 
 
- Act.
```q
  res:.test.h[`t.componentX](`.componentX.getCols;tradeChunk);
```
 
 Tested function `.componentX.getCols` is executed remotely on `t.componentX` process using `.test.h` proxy.
 `tradeChunk` generated in previous step is passed as parameter.
 Result from the execution is stored in the local variable `res`.
 
- Assert.
```q
  .assert.match["return list of columns"; 
    res; cols tradeChunk];
  };
```
`res` variable from the previous step is being checked. It should contain a list of columns of `tradeChunk`.
`.assert.match` function is used to execute the check. 
Assert is described with a sentence which is serving as documentation of the test.

##### test case 2

Second test case is defined as following.

```q
.componentXTest.test.failWith_NonTableArg:{[]
  .assert.fail["support only table"; 
    `$"expecting type 98h";
    `t.componentX;(`.componentX.getCols;5)];
  };
```

It consist of one assertion `.assert.fail` which is executing remotely `.componentX.getCols` method with invalid argument - number `5` instead of proper argument - a table.
Normally remote execution would be performed as following 
```q
res:.test.h[`t.componentX](`.componentX.getCols;tradeChunk);
```
however, for convenient catching of an expected signal `.assert.fail` was designed. It does proper protected evaluation execution and records all relevant information in the test log for later analysis. It also allows assertion description as with any other assertion.

### manual test execution

Test expects following directory structure:
- `TEST_DIR/bin/ec/` - enterprise components package
- `TEST_DIR/bin/yak/` - yak package
- `TEST_DIR/bin/q/` - q package

Executing tests (assuming ec is deployed in the bin directory):

- prepare env on linux:
    ```bash
    TEST_DIR> source bin/ec/components/qtest/example/test/etc/env.sh
    ```

- prepare env on windows:
    ```bash
    TEST_DIR> bin\ec\components\qtest\example\test\etc\env.bat
    ```
	
- start tests:
    ```bash
    TEST_DIR> yak start t.run
    ```

- check progress:
    ```bash
    TEST_DIR> yak log t.run
    ```

- inspect results once the tests are completed:
    ```q  
    //on the process `t.run
    q).test.report[]
    ```
