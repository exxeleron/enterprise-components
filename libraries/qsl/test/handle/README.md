 ### Executing tests

Executing tests (assuming ec is deployed in the bin direcotory):

- prepare env on linux:
```bash
KdbSystemDir> source bin/ec/libraries/qsl/test/handle/etc/env.sh
```
- prepare env on windows:
```bash
KdbSystemDir> bin\ec\libraries\qsl\test\handle\etc\env.bat
```
  
- execute tests:
```bash
> # start tests
> yak start t.run
> # check progress
> yak log t.run
> # check errors and test failures
> yak err t.run
```

There will be a line at the end of the log of the t.run process similar to the following:

```
INFO  2015.09.11 08:23:43.521 qtest - component qtest initialized with 0 fatals, 0 errors, 0 warnings
```

This line can be used as a quick way to see if the tests have passed. If some of the tests have failed this line looks as follows:

```
ERROR 2015.09.11 08:57:44.472 qtest - component qtest initialized with 0 fatals, 3 errors, 0 warnings
```

- inspect results once the tests are completed:
```q  
q)//on the t.run
q).test.report[]
q).test.asserts
```
