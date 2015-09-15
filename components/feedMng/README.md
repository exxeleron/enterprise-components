## **feedMng component**
`feedMng` - Feed management component - managing subscription universe in feed handlers
Component is located in the `ec/components/feedMng`.

### Functionality
- basic universe management (division of the universe between multiple feeds)
- providing interface for subscription and un-subscription
Notes:
- universe is derived from the reference data received from tickLF [tickLF](../tickLF) component
- universe is distributed by the tickLF interface as sysUniverse table
- intraday updates of the sysUniverse can be modified only by the reference data and should be triggered from [tickLF](../tickLF)
- manual modification of the sysUniverse is not supported and can cause inconsistency of the universe inside the system

### Configuration
Note: configure port and component name according to your conventions (core.feedMng)

#### system.cfg example
```cfg
  [[core.feedMng]]
    command = "q feedMng.q"
    type = q:feedMng/feedMng
    port = ${basePort} + 20
    cfg.serverAux = core.rdb
```

#### dataflow.cfg example
```cfg
[table:referenceData]
  [[core.feedMng]]
    subSrc = core.tickLF
[sysTable:sysUniverse]
  [[core.feedMng]]
    subSrc = core.tickLF
```

### Startup
start feedMng component
```bash
> yak start core.feedMng
```

### Simple usage example

#### Workflow:
1. - FeedMng on initialization replays current state of the sysUniverse using `.feedMng.plug.jrn[]` interface
2. - Restored sysUniverse is cross-checked whether any actions are required to add/delete instruments
3. - During run-time updates of the reference data are processed by plugins

#### Plugins:
Updates of the sysUniverse can be implemented through plugins, examples of plugins can be found in `pluginExample.q`
- receiving reference data during the day from tickLF
```q
.feedMng.plug.img[tabName][data] // data images
.feedMng.plug.upd[tabName][data] // data inserts
.feedMng.plug.ups[tabName][(data;constraints;bys;aggregates)] // data upserts
.feedMng.plug.del[tabName][(constraints;bys;aggregates)] // deletes
```
where
```q
tabName:SYMBOL - table name of the reference data, that is received form tickLF
data:TABLE - data
constraints:LIST GENERAL - list of constraints
bys:DICTIONARY - dictionary of group-bys
aggregates:DICTIONARY - dictionary of aggregates
```

- replay reference data on initialization, plugin to create latest sysUniverse from reference data restored from the journal file
```q
q).feedMng.plug.jrn // return sysUniverse, takes no arguments
```
