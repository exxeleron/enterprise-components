Logging functionality is integrated into qsl library (see Enterprise Components 3.0 Developers'
Documentation (Qsl)). It is possible to log on five different severity levels
(`FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`) to three destinations (`CONSOLE`, `FILE`, `STDERR`).

### Logging configuration

System logging is configured using several configuration variables in `system.qsd`.

```
+-----------------------------+-----------------------------------------------------------------+
| Configuration variable in   | Description                                                     |
| system.cfg file (variable   |                                                                 |
| in exported to the          |                                                                 |
| environment)                |                                                                 |
+-----------------------------+-----------------------------------------------------------------+
| logPath (`EC_LOG_PATH`)     | Top-level directory to store log files. Each logging component  |
|                             | creates its own log directory under logPath and stores its      |
|                             | files there.                                                    |
+-----------------------------+-----------------------------------------------------------------+
| logLevel (`EC_LOG_LEVEL`)   | Sets the threshold for logger. Messages which are less severe   |
|                             | than level set here will be ignored.                            |
+-----------------------------+-----------------------------------------------------------------+
| logDest (`EC_LOG_DEST`)     | Destination (or collection of destinations) where to write      |
|                             | the log                                                         |
+-----------------------------+-----------------------------------------------------------------+
| logRotate (`EC_LOG_ROTATE`) | Time moment when log rotating occurs. Time is taken according   |
|                             | to timestampMode variable settings                              |
+-----------------------------+------------------+----------------------------------------------+
```

### Example log messages

- Log a string message on `INFO` log level:

    ```
    q) .log.info[`logsrc] "Message on log level"
    ```

- Log a symbol message on `INFO` log level:

    ```
    .log.info[`logsrc] `SampleMessage
    ```
    
- Log a dictionary on `INFO` log level:
    
    ```
    q) .log.info[`logsrc] `arg1`arg2!("val1"; "val2")
    ```

    Messages logging dictionaries result in an easy-to-parse message in the `key=value` pairs
    separated by "|" character:
    
    ```
    INFO 2013.12.01 05:29:47.488 logsrc- | arg1="val1" | arg2="val2"
    ```

- Log a string message on `ERROR` log level:

    ```
    q) .log.error[`logsrc] "Sample error message"
    ```

    Messages logged on `ERROR` level are automatically logged to process’ standard error file
