## **`tickHF` component**
`tickHF` - tick High Frequency component (based on [kx tick](kx.com))
Component is located in the `ec/components/tickHF`.

### Functionality
[kx tick](kx.com) component extended and integrated with the ec
- logging using ec logger
- in cases when time is not sent in the first column by data provider, current time can be added automatically in both modes: zero-latency and aggregation mode
- support for handling ticks that arrived after midnight but which are still 'belonging' to the previous day (called later as `late ticks`)

> Note:
> `sym` (type:SYMBOL) column is mandatory in the data model for `tickHF` tables

### Configuration
Note: configure port and component name according to your conventions (core.tickHF)

#### system.cfg example
```cfg
  [[core.tickHF]]
    command = "q tickHF.q"
    type = q:tickHF/tickHF
    port = ${basePort} + 10
```

#### dataflow.cfg example
```cfg
[template:quote]
  [[core.tickHF]]
```

#### Late ticks:
- in order to properly process late ticks, eodDelay in system.cfg has to be setup, for example to handle ticks 10 seconds after midnight:
```cfg
eodDelay = 00:00:10.000 #TIME format
```
- this will delay end-of-day for 10 seconds; during this period ticks that belong to the previous day will be published normally and ticks for the next day will be cached in memory
- after this period end-of-day callback will be broadcast and cached ticks will be published to all subscribers
- in order to use this feature late and next day ticks are recognized *only by the time in first column* delivered by the data provider
`eodDelay` is a global variable and will affect all components that have build-in end-of-day procedure: 
[tickLF](../tickLF), [rdb](../rdb), [stream](../stream), [eodMng](../eodMng) and [hdb](../hdb),
queries that are using interface functions from [qsl/query](../../libraries/qsl/query.q)

#### Tick modes:
Tick can work in two modes
- zero-latency - this is the default mode, messages are published as soon as possible
- aggregation mode - messages are cached and published on timer; in order to run tickHF in aggregation mode in system.cfg please setup
```cfg
cfg.aggrInterval = 100 #INT format
```

### Startup
start tickHF component
```bash
> yak start core.tickHF
```

### Simple usage example

#### Globals:
tickHF uses following global variables
```q
q).u.w // dictionary of tables->(handle;syms)
q).u.i // message count
q).u.t // table names
q).u.L // tp log filename, e.g. `:./sym2008.09.11
q).u.l // handle to tp log file
q).u.d // date
```

#### API for pushing data through tickHF:
- `.u.upd` is defined during initialization and the only data format supported by `.u.upd` function is a list of lists
```q
.u.upd[table name:SYMBOL;data:LIST GENERAL]               // definition
.u.upd[`trade;(enlist .z.t; enlist `sym1;enlist 1.0)]     // usage example
```
- *note* - can't use -u because of the client end-of-day
- all described functions are defined in .u namespace (i.e .u.tick)

### Further reading

- [Lesson 1 - basic system](../../tutorial/Lesson01)
- [Lesson 2 - adding `quote` table](../../tutorial/Lesson02)
- [`dist` component](../dist)
- [`tickLF` component](../tickLF)
