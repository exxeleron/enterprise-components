# **rproc - Realtime Processing component**

-------------------------------------------------------------------------------

## quick start
`rproc` - Realtime Processing is a component which allows performing calculation on live data streams.
`rproc` component is subscribing to the realtime `source data stream` (i.e. `tickHF`) and calculates `derived data stream`.
`rproc` component is located in `ec/components/rproc`

`rproc` component alone does not provide any useful functionality - it is just a `container`. It requires additional code called `plugin` which defines the logic for calculation of `derived data`.

`rproc` package consist of some sample predefined plugins (`snap`, `mrvs`, `ohlc`) which show how a plugin code can be defined. Those plugins are described in more detail below.

-------------------------------------------------------------------------------
### derived data


`Derived data` can be kept in memory for ad-hoc queries, it can be also further published with publish-subscribe method to the clients.

`Derived data` calculation logic is defined by a set of plug-in functions.

-------------------------------------------------------------------------------
#### derived data publish-subscribe
`plugin` can publish the data using `.u.pub[tab;data]` function from `qsl/u` library. In that case clients can subscribe to `rproc` component and retrieve the `derived data` updates.  

There is no facility for the journaling of the published `derived data`. Subscriber can consume the state of the in-memory table kept in the `rproc` component (depending on the actual `plugin` definition), but there is no journal that could be replyaed as in the data published through the standard `tickHF`.

-------------------------------------------------------------------------------

### configuration

#### system.cfg

Example of `system.cfg` configuration entry for the `rproc` component with predefined `mrvs` plug-in (component is named `t.mrvs`).

```cfg
  [[t.mrvs]]
    command = "q rproc.q"
    type = q:rproc/rproc
    port = ${basePort} + 6
    memCap = 10000
	requires = t.hdb, t.tick
	libs = mrvs
	cfg.serverAux = t.hdb
```

1. `libs` field should point to the plugin file.  
 Example config points to the `mrvs`, which results in loading `mrvs.q` plugin.

2. It is recommended to set `requires` field to the servers used during plugin initialisation. This filed is specifying the order of `yak start` command,

3. Any auxiliary servers required for e.g. initialization should be listed under `cfg.serverAux` field.  
Example config points to the `t.hdb`, as `mrvs` plugin is using `t.hdb` server to initialize its state.  
`cfg.serverAux` is optional, by default it is set to `NULL`

#### dataflow.cfg
```cfg
  [[t.mrvs]]
  subSrc = t.tick
```

1. `subSrc` field should point to the `source data stream`.  
 Example config points to the `t.tick`.

2. Subsection `[[t.mrvs]]` should be added to each table should be processed by the `t.mrvs` process.  


-------------------------------------------------------------------------------

### plugin definition
The following functions are used to define a `plugin`.  
All of those functions have default `empty` implementation.  
Custom code should overwrite some or all of them, depending on the use case.

#### .rp.plug.init[srv]
Plug-in `.rp.plug.init[srv]` is invoked during component initialization. The role of this callback is to initialize the data model and optionally insert start-up content for each `derived table` in the `rproc` component.
It is invoked `after` opening of the connection to the `cfg.serverAux` servers.

#### .rp.plug.upd[tab;data]
Plug-in `.rp.plug.upd[tab;data]` is invoked on each data receive from `tickHF` process. The role of this callback is to calculate `derived data` based on the `source data update`. This callback is the essential element of the implementation as it actually defines the logic for data processing.

#### .rp.plug.end[day]
Plug-in `.rp.plug.end[day]` is invoked on at end of day (triggered by the `tickHF`). May be used for day wrap-up actions, e.g. memory clearing.

#### tickLF callbacks
If component is using tickLF data source, it could also overwrite `tickLF callbacks`:
- `.tickLF.upd[] `/ `.tickLF.jUpd[]`
- `.tickLF.ups[]` / `.tickLF.jUps[]`
- `.tickLF.img[]` / `.tickLF.jImg[]`
- `.tickLF.del[]` / `.tickLF.jDel[]`  

By default those are loaded from `ec/libraries/qsl/sub_tickLF.q`,
Default callbacks are also available in memory in `.sub.tickLF.default` global variable.

Note that using tickLF protocol for stream calculation can lead to significant increase of the custom logic complexity, as the plugin should handle correctly all types of actions including upserts and deletes.

-------------------------------------------------------------------------------

### additional variables

The following global variables are available for the plugin definition.

#### .rp.cfg.model
`.rp.cfg.model` is a dictionary where the `key` is a table name and the `value` is its data model. It contains data model for each table in the `dataflow.cfg` file which has current component configured.

#### .rp.cfg.srcTabs
 `.rp.cfg.srcTabs` contains a list of the tables which are actually the `source tables` for the `rproc` component (those contain `subSrc` field in the `dataflow.cfg`)

-------------------------------------------------------------------------------

### recovery
Component does not provide any functionality for preserving its intermediate state.
At startup it must fully initialize based on the source server (`tickHF`) journal and optionally based on the auxliary servers (e.g. `hdb`).

-------------------------------------------------------------------------------

## example plug-ins:

The following use cases are implemented using the `rproc` component to show its functionality.  
Ready-to-use configuration sample can be found in `ec/components/rproc/test/etc/`.  
Instructions to start this mini system can be found in `ec/components/rproc/test/README.md`  

### use case 1 - minute snapshots
`snap` implements the following functionality:
- calculation of 1-minute snapshots for each symbol
- generic snapshots calculation works for any table with `time` and `sym` columns
- snapshots are not published but kept in memory for ad-hoc queries
- snapshots calculated for `today` only, reset at the end of the day

#### configuration

`system.cfg`:
```cfg
  [[t.snap]]
    command = "q rproc.q"
    type = q:rproc/rproc
    port = ${basePort} + 7
    memCap = 10000
	requires = t.hdb, t.tick
	libs = snap
```
`dataflow.cfg`:
```cfg
  [[t.snap]]
  subSrc = t.tick
```

#### initialization
 initialization of the `derived data model` based on the `source data model` located in `.rp.cfg.model` dictionary.
 `.rp.cfg.srcTabs` contains a list of the tables which are subscribed.
```q
.rp.plug.init:{[srv];
  :{[tab] tab set update`g#sym from select by time.minute, sym from .rp.cfg.model[tab]}each .rp.cfg.srcTabs;
  };
```

#### upd processing
Each in-memory table is `upserted` with the latest update from `tickHF` process.
```q
.rp.plug.upd:{[tab;data]
  tab upsert select by time.minute, sym from data
  };
```

#### end of day
At the `end of the day` data is deleted from memory.
```q
.rp.plug.end:{[day]
  {update`g#sym from delete from x}each .rp.cfg.srcTabs;
  };
```

-------------------------------------------------------------------------------

### use case 2 - configurable minute snapshots
`snapX` implements the following functionality:
- calculation of x-minute snapshots for each symbol and table
- generic snapshots calculation works for any table with `time` and `sym` columns
- snapshots are not published but kept in memory for ad-hoc queries
- snapshots calculated for `today` only, reset at the end of the day

#### configuration

`system.cfg`:
```cfg
  [[t.snapX]]
  command = "q rproc.q"
  type = q:rproc/rproc
  port = ${basePort} + 8
  memCap = 10000
  requires = t.hdb, t.tick
  libs = snapX
```
`dataflow.cfg`:
```cfg
  [[t.snapX]]
  subSrc = t.tick
  snapMinuteInterval = 1
```

#### initialization
 first `snapMinuteInterval` field is loaded from `dataflow.cfg` and dictionary `.rp.cfg.snapMinuteInterval` with table name and snapshot interval is created.
 `derived data model` is initialized based on the `source data model` from `.rp.cfg.model` and `.rp.cfg.snapMinuteInterval` dictionaries.
 `.rp.cfg.srcTabs` contains a list of the tables which are subscribed.
```q
.rp.plug.init:{[srv];
  .rp.cfg.snapMinuteInterval:exec sectionVal!finalValue from .cr.getCfgTab[`THIS;`table`sysTable;`snapMinuteInterval];
  :{[tab] tab set update`g#sym from select by  .rp.cfg.snapMinuteInterval[tab] xbar time.minute, sym from .rp.cfg.model[tab]}each .rp.cfg.srcTabs;
  };
```

#### upd processing
Each in-memory table is `upserted` with the latest update from `tickHF` process.
`.rp.cfg.snapMinuteInterval` dictionary is used to calculate different minute snapshots for each table.
```q
.rp.plug.upd:{[tab;data]
  tab upsert select by .rp.cfg.snapMinuteInterval[tab] xbar time.minute, sym from data
  };
```

#### end of day
At the `end of the day` data is deleted from memory.
```q
.rp.plug.end:{[day]
  {update`g#sym from delete from x}each .rp.cfg.srcTabs;
  };
```

-------------------------------------------------------------------------------

### use case 3 - most recent values
`mrvs` implements the following functionality:
- maintaining the most recent record for each symbol
- generic snapshots calculation works for any table with `sym` columns
- most recent values are not published but kept in memory for ad-hoc queries
- process can be initialized with the yesterday's data from the historical database `hdb`

#### configuration
`system.cfg`:
```cfg
[[t.mrvs]]
    command = "q rproc.q"
    type = q:rproc/rproc
    port = ${basePort} + 6
    memCap = 10000
	requires = t.hdb, t.tick
	libs = mrvs
	cfg.serverAux = t.hdb
```
`dataflow.cfg`:
```cfg
  [[t.mrvs]]
  subSrc = t.tick
```

#### initialization
 There are two options for `mrvs` initialization:
 1. initialization of the `derived data model` based on the `source data model` located in `.rp.cfg.model` dictionary.
 2. initialization from the `hdb` process. Activated when `cfg.serverAux` is set in the configuration.
In this case `mrvs` process will start with the most recent values from `yesterday`.

```q
.rp.plug.init:{[srv];
  if[srv~();
    :{[hdb;tab]tab set update`u#sym from .hnd.h[hdb](.mrvs.hdb.lastBySym;tab;.z.d-1)}[srv]each .rp.cfg.srcTabs;
    ];
  :{[tab] tab set update`u#sym from select by sym from .rp.cfg.model[tab]}each .rp.cfg.srcTabs;
  };
```

#### upd processing
Each in-memory table is `upserted` with the latest update from `tickHF` process. as the action is simple `upsert` it can be defined as following:
```q
.rp.plug.upd:upsert;
```

#### end of day
No eod action required for the `mrvs`, current values are initializing the next day.

-------------------------------------------------------------------------------

### use case 4 - open-high-low-close
`ohlc` implements the following functionality:
- calculating `open-high-low-close` based on the `trade` table
- `ohlc` records are kept in memory for ad-hoc queries and published to the subscribers.
- users can subscribes for `ohlc` table using classical kx subscription protocol - see `.u.sub[]` function and `ec/libraries/qsl/u.q` publishing library.

#### configuration
`system.cfg`:
```cfg
  [[t.ohlc]]
    command = "q rproc.q"
    type = q:rproc/rproc
    port = ${basePort} + 1
    memCap = 10000
	requires = t.hdb, t.tick
	libs = ohlc
	cfg.serverAux = t.hdb
```
`dataflow.cfg`:
```cfg
  [[t.ohlc]]
  subSrc = t.tick
```

Additionally `ohlc` table model is defined as following:
```cfg
[table:ohlc]
  model = sym(SYMBOL), open(FLOAT), high(FLOAT), low(FLOAT), close(FLOAT), volume(LONG)
  [[t.rproc]]

```

#### initialization

 Initialization of the `ohlc` table data model is based on the configuration entry

```cfg
[table:ohlc]
  model = sym(SYMBOL), open(FLOAT), high(FLOAT), low(FLOAT), close(FLOAT), volume(LONG)
  [[t.ohlc]]
```

`ohlc` is a keyed table with the `key` on `sym` column. For each instrument that was processed we will have exactly one record.

```q
.rp.plug.init:{[servers];
  ohlc::`sym xcol .rp.cfg.model[`ohlc];
  };
```

#### upd processing
In-memory `ohlc` table is updated with the latest `trade` update from `tickHF` process.  
In a second step the records of `ohlc` table which were affected by the change are being published with the `.u.pub[tabName;data]` function.
```q
.rp.plug.upd:{[tab;data]
  ohlc::select first open, max high,min low,last close,sum volume by sym from(0!ohlc),select sym,open:price,high:price,low:price,close:price,volume:size from data;
  syms:exec distinct sym from data;
  .u.pub[`ohlc;0!select from ohlc where sym in syms];
  };
```

#### end of day
No eod action is required for the `ohlc`.

-------------------------------------------------------------------------------
