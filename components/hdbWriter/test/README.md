### Executing tests

Executing tests (assuming ec is deployed in the bin direcotory):

- prepare env on linux:
```bash
KdbSystemDir> source bin/ec/components/hdbWriter/test/etc/env.sh
```
- prepare env on windows:
```bash
KdbSystemDir> bin\ec\components\hdbWriter\test\etc\env.bat
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

- inspect results once the tests are completed:
```q  
q)//on the t.run
q).test.report[]
```
