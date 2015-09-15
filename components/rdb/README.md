## **`rdb` component**
`rdb` - real-time database component - serving intraday data for queries
Component is located in the `ec/components/rdb`.

### Functionality
- subscribes to the realtime data soureces [tickHF](../tickHF), [tickLF](../tickLF) and/or [dist](../dist) 
- keeps today`s data in memory
- executes end-of-day procedure
- allows custom plugins

### Configuration
Note: configure port and component name according to your conventions (core.rdb)

#### system.cfg example
```cfg
  [[core.rdb]]
    command = "q rdb.q"
    type = q:rdb/rdb
    port = ${basePort} + 11
```

#### dataflow.cfg example
```cfg
[template:quote]
  [[core.rdb]]
    serverSrc = core.tickHF
    hdbConn = core.hdb
    eodClear = TRUE
    eodPerform = TRUE
```

### Startup
start rdb component
```bash
> yak start core.rdb
```

### Simple usage example

`.sub.status[]` returns status of all subscribed tables:

```q
q).sub.status[]
```

### Further reading

- [Lesson 1 - basic system](../../tutorial/Lesson01)
- [Lesson 2 - adding `quote` table](../../tutorial/Lesson02)
