### All tests

#### Test execution
> Assuming `ec` is deployed in the bin directory.

Execute all tests on linux:
```bash
KdbSystemDir> bin/ec/test/runAllTests.sh
```

Execute all tests on windows:
```bash
KdbSystemDir> bin\ec\test\runAllTests.bat
```

#### Test result collection
```txt
                                  . {data/test/qslHandleTest/t.run/test.result}
                            .				    
                      .             {data/test/qslTabsTest/t.run/test.result}
		.      
  <t.collectResults>     .    .   . {data/test/rdbTest/t.run/test.result}
        18000     .
                       .            {data/test/hdbTest/t.run/test.result}
                             . 
                                   .{data/test/hdbWriterTest/t.run/test.result}
```

`t.collectResults` is executed via console at the end of the `runAllTests` script:
```bash
> yak console t.collectResults
```

Following line at the end of the `log` of the `t.collectResults` process indicates successful test execution:

```INFO  2015.09.15 07:27:03.100 test  - ==========================> Test Execution COMPLETED with: Test suites: 6/6, Test cases: 33/33```

Following line in the log of the `t.collectResults` process indicates test failure:

```ERROR 2015.09.15 07:21:17.510 test  - ==========================> Test Execution FAILED with: Test suites: 5/6, Test cases: 32/33```
 
> Details of testCase errors and test failures are also printed as errors.

Full test results can be inspected directly in q process once the tests are completed:
```q
q)//execute on the t.collectResults [port 18000]
q).test.report[]
q).test.report[]`testCases
q).test.report[]`asserts
q).test.report[]`testCasesFailed
q).test.report[]`assertsFailed
```
