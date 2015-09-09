### Executing tests

Executing tests (assuming ec is deployed in the bin direcotory):

- prepare env on linux:
    ```bash
    KdbSystemDir> source bin/ec/components/componentX/test/etc/env.sh
    ```

- prepare env on windows:
    ```bash
    KdbSystemDir> bin\ec\components\componentX\test\etc\env.bat
    ```
	
- start tests:
    ```bash
    KdbSystemDir> yak start t.run
    ```

- check progress:
    ```bash
    KdbSystemDir> yak log t.run
    ```

- inspect results once the tests are completed:
    ```q  
    //on the t.run
    .test.report[]
    ```