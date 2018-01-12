## **`monitor` component**
`monitor` - capturing various information relevant to the system monitoring and profiling.
Component is located in the `ec/components/monitor`.

### Functionality
`monitor` is simply capturing information about the system that is useful for the
administrators. Data provided by the `monitor` cannot be accessed directly, it is pushed to
subscribers. From interface point of view, `monitor` works in a similar way as `tickHF` component:

- It provides publish-subscribe functionality to allow subscription
- It keeps an empty data model to inform subscribers about the format of published tables
- It is journaling captured data to provide fallback after restart of subscribers

The recommended component for subscribing and storing this kind of information is `rdb` and `hdb`.

`monitor`, together with other components (`admin.rdb`, `admin.hdb`, and `admin.ap`)
dedicated for technical (non-business) type of information, is usually located in the namespace
`admin` in `system.cfg` configuration file.

### Configuration
Note: configure port and component name according to your conventions (core.monitor, core.hdb)

#### system.cfg example
```cfg
[group:admin]
  [[admin.monitor]]
    command = "q monitor.q"
    type = q:monitor/monitor
    port = ${basePort} + 16
    cfg.procMaskList = ALL
    cfg.monitorStatusPublishing = FALSE

  [[admin.rdb]]
    command = "q rdb.q"
    libs = queries/queries
    type = q:rdb/rdb
    port = ${basePort} + 17

  [[admin.hdb]]
    command = "q hdb.q"
    type = q:hdb/hdb
    port = ${basePort} + 18

  [[admin.ap]]                         
    command = "q accessPoint.q"         
    type = q:accessPoint/accessPoint    
    port = ${basePort} + 19
    #ap by default connected to admin.rdb and admin.hdb
    cfg.serverAux = admin.rdb, admin.hdb
```


#### dataflow.cfg example

```cfg
[template:adminTable]
  #data model of monitor tables are defined in the monitor/monitor.qsd
  modelSrc = admin.monitor

  [[admin.monitor]]
    #Number of milliseconds between checks of the `monitor`
    frequency = 10000

  [[admin.rdb]]
    #Subscribing to the admin.monitor for updates
    subSrc = admin.monitor
    #At the end of the day writing the data to admin.hdb
    hdbConn = admin.hdb

  [[admin.hdb]]

[template:adminStatsTable]
  #data model of monitor tables are defined in the monitor/monitor.qsd
  modelSrc = admin.monitor

  [[admin.monitor]]

  [[admin.rdb]]
    subSrc = admin.monitor
    hdbConn = admin.hdb

  [[admin.hdb]]

[sysTable:sysStatus]
  template = adminTable

[sysTable:sysConnStatus]
  template = adminTable

[sysTable:sysLogStatus]
  template = adminTable

[sysTable:sysResUsageFromQ]
  template = adminTable

[sysTable:sysResUsageFromOs]
  template = adminTable

[sysTable:sysEvent]
  template = adminTable

[sysTable:sysHdbSummary]
  template = adminStatsTable

  [[admin.monitor]]
    execTime = 03:00:00
    hdbProcList = core.hdb,admin.hdb

[sysTable:sysHdbStats]
  template = adminStatsTable

  [[admin.monitor]]
    execTime = 03:00:00
    hdbProcList = core.hdb,admin.hdb

[sysTable:sysKdbLicSummary]
  template = adminStatsTable

  [[admin.monitor]]
    execTime = 03:00:00

[sysTable:sysFuncSummary]
  template = adminStatsTable

  [[admin.monitor]]
    execTime = 03:00:00
    procList = access.ap
    procNs = .demo
```

### Startup
start admin section
```bash
> yak start admin
```


### Simple usage example

`admin.ap` should load user defined code querying admin components. For example:

```q
/F/ get current sysStatus
/E/ .admin.getSysStatus[]
.admin.getSysStatus:{[]
  .hnd.h[`admin.rdb]"select by sym from sysStatus"
  };
```
