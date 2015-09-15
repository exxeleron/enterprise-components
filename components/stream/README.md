## **`stream` component**
`stream` - processing real-time `streaming` data from tickHF on the fly
Component is located in the `ec/components/stream`.

### Functionality
- facilitating processing on stream of data using tickHF [tickHF](../tickHF) protocol
- subscription to streaming data source ([tickHF](../tickHF)-compatible server)
- subscription to additional data sources ([tickLF](../tickLF)-compatible server)
- calculation of derived data e.g. mrvs, snapshots, etc.
- serving derived data in memory
- publishing and journaling of derived data
- savepoint functionality for faster recovery after component restart
- data caching facility
- high level plugin interface

### Configuration
Note: configure port and component name according to your conventions (core.stream)

#### system.cfg example
Example configuration of the `stream` component with `mrvs` (most recent values) plugin in the `system.cfg`:
```cfg
  [[core.stream]]
    type = q:mrvs/mrvs
    command = "q stream.q"
    libs = streamMrvs
    cfg.timeout = 100
    cfg.tsInterval = 1000
    cfg.serverAux = core.rdb
```

#### dataflow.cfg example
Example configuration of the `stream` component with `mrvs` (most recent values) plugin in the `dataflow.cfg`:
```cfg
[template:quote]
  [[core.stream]]
    srcServer = core.tickHF
```

### Startup
start stream component
```bash
> yak start core.stream
```

### Simple usage example
- `stream.q` itself does not provide any business logic code for data processing
- specific functionality of data processing has to be loaded additionally in a form of a plugin code
- plugin code should be defined in a separate file and loaded into `stream.q` using `libs` configuration field

####Plugins:

##### Defining plugin in "lowLevel" mode
- provides more flexibility but requires more implementation
- definition of mode is done by implementation of direct callbacks from the data source
- plugin must implement *all* low-level callbacks
```q
jUpd[tabName;data] //callback function for retrieving high frequency data from journal file
upd[tabName;data]  //callback function for retrieving high frequency data from tick server
sub[server;schema] //callback invoked after subscription to tick server but before the journal replay
```
- timers can be defined if required using qsl/timer.q library (i.e. add new timer with `.tmr.start[]`)

##### Defining plugin using "cache" mode
- provides less flexibility but requires less implementation
- pre-defined callbacks implemented in "lowLevel" mode can be readily used
- following plugin functions must be defined in order to specify mode logic
```q
.stream.plug.init[] // invoked during initialization of stream process
.stream.plug.sub[]  // invoked after successful subscription to the data source
.stream.plug.ts[]   // invoked on timer with frequency defined via configuration entry cfg.tsInterval
                    //  The timer is:
                    //    - activated after .stream.plug.init[] callback
                    //    - active during whole lifetime of stream process
                    //  Notes: 
                    //    - it is possible that .stream.plug.ts[] is invoked before .plug.stream.sub[] callback
                    //    - .stream.plug.ts[] is invoked using protected execution mode
                    //    - .stream.plug.ts[] is invoked directly before eod callback .stream.plug.eod[]
.stream.plug.eod[]  // invoked after eod (end of day) event in stream process.
```

Functionality can be implemented using predefined helper interface
```q
q).stream.initPub[]
q).stream.pub[]
q).stream.savepoint[]
```
