## **`eodMng` component**
`eodMng` - End-of-day Manager component
Component is located in the `ec/components/eodMng`.

### Functionality
End-of-day is a procedure – executed at midnight – responsible for journal files rollover and data
storing from real time database [`rdb`](../rdb) to historical database [`hdb`](../hdb).

`eodMng` is a service that performs housekeeping jobs on `hdb` and synchronizes databases across
multiple hosts. `eodMng` logic is executed after end-of-day process finishes. 
`eodMng` is responsible for:
- detecting rdb end of day process
- housekeeping - compressing / conflating / deleting old partitions
- synchronizing data with mirror hosts

### Configuration
Note: configure port and component name according to your conventions (core.eodMng)

#### system.cfg example
```cfg
  [[core.eodMng]]
    command = "q eodMng.q"
    type = q:eodMng/eodMng
    port = ${basePort} + 10
```

#### dataflow.cfg example
```cfg
[template:quote]
  [[core.eodMng]]
```

#### sync.cfg example
 File `sync.cfg` in the in the configuration directory (etc/) needs to be used to specify the order of the hosts, more specifically the cfg.eodOrder variable has to be defined, for example:
```cfg
 [group:core]
    [[core.eodMng]]
       cfg.eodOrder = core.eodMng, prod2.eodMng, prod3.eodMng
```
- In the above example, the core.eodMng process is considered to be master (as is listed first), and prod2.eodMng, prod3.eodMng processes will synchronize data with it
- File sync.cfg is read by eodMng process before synchronisation and can be used to select master host for synchronisation. For example, consider a case when host of core.eodMng malfunctions and can no longer be used as a source of synchronisations, but prod2.eodMng works well. Then change in the order will result in prod2.eodMng becoming source of data for synchronisation for next end of day process. If host of core.eodMng becomes available again, the previous order can be restored
- The only case when sync.cfg is not required, is a setup, where there is only one host (ie. no synchronisation will ever be performed)

### Startup
start eodMng component
```bash
> yak start core.eodMng
```

### Status table

 Overall status can be seen in the `.eodmng.status` table
```q
q).eodmng.status
 | host         | state | syncDate   | timeStamp               |    db    | current | cold | lastSyncHost |
 |--------------|-------|------------|-------------------------|----------|---------|------|--------------|
 | core.eodMng  | idle  | 2013.02.16 | 2013.02.15T15:48:50.498 | :kdb/db0 | 0       | 0    |none          |
 | prod2.eodMng | idle  | 2013.02.16 | 2013.02.15T15:48:36.102 | :kdb/db1 | 1       | 0    |core.eodMng   |
 | prod3.eodMng | error | 2013.02.15 | 2013.02.15T15:48:47.112 | :kdb/db2 | 0       | 1    |core.eodMng   |
```

 where
- host - process name (defined in system configuration file) of the eodMng process 
- state - state of eodMan process
- syncDate - date of next synchronization / end of day processing
- timeStamp - timestamp of the last status update from given host
- db - path to hdb
- current [boolean] - true indicates that this host is a current process
- cold [boolean] - true indicates that host is in cold standby (no eodMng process running)
- lastSyncHost [symbol] - process name (as in host column) pointing to source of last synchronisation (or none if no sync performed)

 
### Further reading

Following sections describe end-of-day procedure in more detail:
- [eodMng implementation details](doc/eodMng-implementation-details.md)
- [Testing the end-of-day procedure](doc/Testing-the-end-of-day-procedure.md)
- [hdb housekeeping](doc/hdb-housekeeping.md)
- [hdb synchronization](doc/hdb-synchronization.md)

- [`qsl/store` library](../../libraries/qsl/store.q)
- [`rdb` component](../rdb)

