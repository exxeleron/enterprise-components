## **`accessPoint` component**
`accessPoint` - Access point component - abstraction layer for user accessing system.
Component is located in the `ec/components/accessPoint`.

### Functionality
- provides abstraction level for users to effortlessly query both historical [hdb](../hdb) 
  and real-time data [hdb](../rdb) using the same interface described in the [qsl/query](../../libraries/qsl/query.q) library
- applying user authorization performed by the <authorization.q> library
- providing access control by defining functions that are permitted to specific users, described in the [qsl/authorization](../../libraries/qsl/authorization.q) library

### Configuration
Note: configure port and component name according to your conventions (core.monitor, core.hdb)

#### system.cfg example
```cfg
  [[core.ap]]                         
    command = "q accessPoint.q"         
    type = q:accessPoint/accessPoint    
    port = ${basePort} + 15
    #assuming core.rdb and core.hdb are defined in the system.cfg
    cfg.serverAux = core.rdb, core.hdb
```

### Startup
start accessPoint component
```bash
> yak start core.ap
```

### Further reading

- [Lesson 4 - user queries](../../tutorial/Lesson04) - setting up accessPoint component and adding user queries
- [Lesson 5 - authorization and authentication](../../tutorial/Lesson05)
- [Security model description](../../doc/Security-model-description.md)
- [access.cfg configuration](../../doc/Configuration-access.cfg.md)
- [authentication component](../authentication/)
- [qsl/authorization library](../../libraries/qsl/authorization.q)
