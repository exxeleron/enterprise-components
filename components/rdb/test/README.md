### `rdb` tests

#### `rdb/rdb` test environment

```txt
               (t0.tickMock)  
             .    18002
          .         |
       .            |
  <t.run> . . . [t0.rdb]          
   18000          18001 
       .            |
          .         |
             . (t0.hdbMock)
                  18003
```

#### `rdb/replay` test environment

```txt
            [t1.stream] [t1.tick1] [t1.tickLF] [t1.tick2]
              . 18018     18013     / 18012     18014
           .         \     /      /      \      /  
        .             \   /     /         \    /    
   <t.run>   .  .  .  [t1.rdb1]         [t1.rdb2]
    18000               18015             18016  .
             .                \        /           .  <using t1.rdb1 or t1.rdb2 cfg>               
                   .           \      /              .   
                         .   (t1.hdbMock) <------ [t1.replay]
                                 18017    <write>   18011
```

#### Test execution
> Assuming `ec` is deployed in the bin directory.

Prepare env on and start tests on linux:
```bash
KdbSystemDir> source bin/ec/components/rdb/test/etc/env.sh
KdbSystemDir> yak start t.run
```

Prepare env on and start tests on windows:
```bash
KdbSystemDir> bin\ec\components\rdb\test\etc\env.bat
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
