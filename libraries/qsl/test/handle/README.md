### `qsl/handle` functional tests

#### Test environment

```txt
              <t.run>
               18000
                 .
                 .
             [t0.proc1]
                18001
             /         \
            /           \
   [t0.proc2] ---------- [t0.proc3]
     18002                 18003
```

#### Test execution
> Assuming `ec` is deployed in the bin directory.

Prepare env on and start tests on linux:
```bash
KdbSystemDir> source bin/ec/libraries/qsl/test/handle/etc/env.sh
KdbSystemDir> yak start t.run
```

Prepare env on and start tests on windows:
```bash
KdbSystemDir> bin\ec\libraries\qsl\test\handle\etc\env.bat
KdbSystemDir> yak start t.run
```
  
#### Test result

Check `log` to see the test progress:
```bash
> yak log t.run
```

Following line at the end of the `log` of the `t.run` process indicates successful test execution:

```INFO  2015.09.11 08:23:43.521 qtest - component qtest initialized with 0 fatals, 0 errors, 0 warnings```

Following line at the end of the log of the `t.run` process indicates test failure:

```ERROR 2015.09.11 08:57:44.472 qtest - component qtest initialized with 0 fatals, 3 errors, 0 warnings```

Check `stderr` file to see the details of errors and test failures:
```bash
> yak err t.run
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
