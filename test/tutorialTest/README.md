### Tutorial functional tests

#### Test environment

There are five testing components `t.run1` to `t.run5` corresponding to the number of tutorial lessons. They are configured
on the same port `18000` as each lesson is tested separately. Each component executes test from its own namespace .testLesson01
to .testLesson05. All tests are located in the same file `tutorialLesson.q`. 

As the tutorial is written in the incremental way all namespaces starting from the second one are defined as copies of the previous. 
```q
q) .testLesson02:.testLesson01;
``` 
This way we copy the scope of previous tests like in the table below: 

| component | namespace    | tests                                                           |
| --------- | :----------: | ---------------------------------------------------------------:|
| t.run1    | testLesson01 | testLesson1                                                     |
| t.run2    | testLesson02 | testLesson1, testLesson2                                        |
| t.run3    | testLesson03 | testLesson1, testLesson2, testLesson3                           |
| t.run4    | testLesson04 | testLesson1, testLesson2, testLesson3, testLesson4              |
| t.run5    | testLesson05 | testLesson1, testLesson2, testLesson3, testLesson4, testLesson5 |

##### Test setUp and tearDown
All components share the same `setUp` function called with three arguments: 
* `lessonNumber` which indicates which `etc` directory should be linked for test purposes
* `user` used for connecting to the tested components
* `pass` used for connecting to the tested components 

The test environment is created in `setUp` function in separated directory: `/bin/ec/test/tutorialTest/rootPath`. 
The directory is removed in `tearDown` function. The number of components started by `t.run1-5` depends on the lesson tested.

#### Test execution
> Assuming `ec` is deployed in the bin directory.

Prepare env on and start tests on linux:
```bash
KdbSystemDir> source bin/ec/test/tutorialTest/etc/env.sh
KdbSystemDir> yak start t.run1
```

Prepare env on and start tests on windows:
```bash
KdbSystemDir> bin\ec\ec\test\tutorialTest\etc\env.bat
KdbSystemDir> yak start t.run1
```
#### Switch between lesson tested
```bash
> yak stop t.run1
> yak start t.run2
```

#### Test result
Check `log` to see the test progress:
```bash
> yak log t.run1
```

Following line at the end of the `log` of the `t.run1` process indicates successful test execution:

```INFO  2015.09.11 08:23:43.521 qtest - component qtest initialized with 0 fatals, 0 errors, 0 warnings```

Following line at the end of the log of the `t.run` process indicates test failure:

```ERROR 2015.09.11 08:57:44.472 qtest - component qtest initialized with 0 fatals, 3 errors, 0 warnings```

Check `stderr` file to see the details of errors and test failures:
```bash
> yak err t.run1
```

Full test results can be inspected directly in q process once the tests are completed:
```q  
q)//execute on the t.run [port 18000]
q).test.report[]
q).test.report[]`testCases
q).test.report[]`asserts
q).test.report[]`testCasesFailed
q).test.report[]`assertsFailed
```
