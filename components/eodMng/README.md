## **`eodMng` component**
`eodMng` - set of components for handling `hdb` after the `end-of-day` procedure.
Components are located in the `ec/components/eodMng`.

### Functionality

#### End of day
End-of-day is a procedure – executed at midnight – responsible for journal files rollover and data
storing from real time database [`rdb`](../rdb) to historical database [`hdb`](../hdb).

#### `eodMng` package components:
End of day management module consists of following components:
- [eodMng/eodMng](#eodmngeodmng-component) - End of day Manager - [`eodMng.q`](eodMng.q)
  - core component of the package, it monitors rdb state (regarding eod) and triggers housekeeping and synchronization when needed 
   (by detecting which hosts should be synchronized and passing necessary parameters to `hdbSync.q`); it also reports warnings and errors
- [eodMng/hdbHk](#eodmnghdbhk-component) - Hdb housekeeping script - [`hdbHk.q`](hdbHk.q) 
  - is a plug-in based process that handles hdb housekeeping (deletion of old partitions, data compression, snapshots etc.); 
    `hdbHk.q` has its own configuration specifying tasks that need to be performed (see `hdbHk.q` for details)
- [eodMng/hdbSync](#eodmnghdbsync-component) - Synchronization script [`hdbSync.q`](hdbSync.q)
  - uses `rsync` to synchronize `hdb` in two cases:
     1. - slave host pulls data from primary host 
     2. - primary host pushes data to slave hosts in cold standby for synchronization 

-------------------------------------------------------------------------------
## **`eodMng/eodMng` component**
`eodMng` - End-of-day Manager component.
Component is located in the `ec/components/eodMng`.

### Functionality
- `eodMng` logic is executed after end-of-day process finishes
- `eodMng` is detecting rdb end of day process
- `eodMng` triggers [housekeeping](#eodmnghdbhk-component) jobs on `hdb` - compressing / conflating / deleting old partitions / custom actions
- `eodMng` triggers [synchronization](#eodmnghdbsync-component) of the databases across multiple hosts. 

### Configuration
> Note: configure port and component name according to your conventions (core.eodMng)

#### system.cfg example
```cfg
  [[core.eodMng]]
    command = "q eodMng.q"
    type = q:eodMng/eodMng
    port = ${basePort} + 10
    cfg.rdbName = core.rdb
    cfg.hdbConn = core.hdb
    cfg.eodMngList = ((eodMng(core.eodMng), rdb(core.rdb), hdb(core.hdb)), (eodMng(prod2.eodMng), rdb(prod2.rdb), hdb(prod2.hdb)))
    cfg.syncProcessName = core.sync
    cfg.hkProcessName = core.hkConflation
```

#### sync.cfg example
 File `sync.cfg` in the in the configuration directory (etc/) needs to be used to specify the order of the hosts, 
 more specifically the `cfg.eodOrder` variable has to be defined, for example:
```cfg
  [group:core]
    [[core.eodMng]]
      cfg.eodOrder = core.eodMng, prod2.eodMng
```
- In the above example, the `core.eodMng` process is considered to be master (as is listed *first*), and `prod2.eodMng` process will synchronize data with it
- File `sync.cfg` is read by eodMng process before synchronisation and can be used to select *master host* for synchronisation. 
  For example, consider a case when host of `core.eodMng` malfunctions and can no longer be used as a source of synchronisations, 
  but `prod2.eodMng` works well. Then change in the order will result in `prod2.eodMng` becoming source of data for synchronisation for next end of day process. 
  If host of `core.eodMng` becomes available again, the previous order can be restored
- The only case when `sync.cfg` is not required, is a setup, where there is only one host (i.e. no synchronisation will ever be performed)

### Startup
start eodMng component
```bash
> yak start core.eodMng
```

### `eodMng` status
`eodMng` status can be set to one of the following:
- `unknown` - initial state (right after process start) changes after first rdb status reading
- `idle` - end of day processing for the last day finished successfully and database is not performing any activities regarding end of day processing
- `eod_during` - end of day processing in progress
- `housekeeping` - performing housekeeping on rdb
- `sync_with_cold` - housekeeping finished - sending data to cold hosts (if any)
- `sync_before` - waiting for the primary host to be in the idle mode for the synchronization to start
- `sync_during` - synchronization with primary host in progress
- `recovery` - recoverable error during end of day processing occurred, however, the synchronization can still be performed 
   (for now this situation occurs only when ‘wsfull signal is intercepted); if eodMng is in recovery state 
   and none of the hosts with higher priority succeeded with end of day processing, hosts with lower priority are checked
- `error` - last end of day processing failed (eg. out of memory, out of disk space etc.), as a result data in hdb might be corrupted; 
  if next end of day is successful, eodMng will be back into idle state; 

> *Notes*
> * Underlying cause of the error state is logged, please check the monitor or log file for the eodMng
> * When housekeeping processes are completed on the primary host, the status is switched to idle (with date increased by 1 day)
> * This state indicates that all secondary hosts can synchronize data with it; please remember that active hosts pull data from primary host, 
> * while for cold hosts data is pushed by the primary host

#### Example statuses
Primary host:

  Action                                          | `eodMng` status  
 -------------------------------------------------|-----------------
  eodMng is waiting for EOD event                 | `idle`           
  rdb starts EOD process                          | `idle`           
  eodMng reads EOD status file                    | `eod_during`     
  rdb completes EOD process                       | `eod_during`     
  eodMng reads EOD status file                    | `housekeeping`   
  eodMng starts housekeeping                      | `housekeeping`   
  housekeeping completed                          | `sync_before`    
  eodMng pushes data to cold hosts                | `sync_with_cold` 
  secondary hosts sync data with primary host     | `idle`           

Secondary host:

  Action                                          | `eodMng` status 
 -------------------------------------------------|-----------------
  eodMng is waiting for EOD event                 | `idle`          
  rdb starts EOD process                          | `idle`          
  eodMng reads EOD status file                    | `eod_during`    
  rdb completes EOD process                       | `eod_during`    
  eodMng reads EOD status file                    | `housekeeping`  
  eodMng starts housekeeping                      | `housekeeping`  
  housekeeping completed                          | `sync_before`   
  eodMng waits for primary host to finish its EOD | `sync_before`    
  secondary hosts pulls data from primary host    | `sync_during`   
  synchronisation completed successfully          | `idle`          

#### Status table
Overall status can be seen in the `.eodmng.status` table
```q
q).eodmng.status
 | host         | state | syncDate   | timeStamp               |    db    | current | cold | lastSyncHost |
 |--------------|-------|------------|-------------------------|----------|---------|------|--------------|
 | core.eodMng  | idle  | 2013.02.16 | 2013.02.15T15:48:50.498 | :kdb/db0 | 0       | 0    |none          |
 | prod2.eodMng | idle  | 2013.02.16 | 2013.02.15T15:48:36.102 | :kdb/db1 | 1       | 0    |core.eodMng   |
```
- `host` - process name (defined in system configuration file) of the `eodMng` process 
- `state` - state of `eodMng` process
- `syncDate` - date of next synchronization / end of day processing
- `timeStamp` - timestamp of the last status update from given host
- `db` - path to `hdb`
- `current` [boolean] - true indicates that this host is a current process
- `cold` [boolean] - true indicates that host is in cold standby (no `eodMng` process running)
- `lastSyncHost` [symbol] - process name (as in host column) pointing to source of last synchronisation (or `none` if no sync performed)

#### `eodMng` internal status file
`[eodMng.dataPath]/eodMngStatus`
File generated by end of day manager `eodMng` - used only internally to restore eodMng status in case of process restart.

Status format:
```txt
 status next_eod_date last_update_time last_sync_host
```
- `next_eod_date` - date of next end of day expected by eodMng
- `last_update_time` - time of the last update of the status (file is updated at regular time intervals)
- `last_sync_host` - host with which data was synchronized during last end of day, ‘none’ if no synchronization occurred – for example in case of a primary host)
- `status` - one of possible statuses

Status file example:
```txt
 idle 2014.04.25 2014.04.25D10:40:00.000000000 none
```
 
### Further reading

- [eodMng/hdbHk](#eodmnghdbhk-component)
- [eodMng/hdbSync](#eodmnghdbsync-component)
- [Testing the end-of-day procedure](../../doc/Testing-the-end-of-day-procedure.md)
- [`rdb` component](../rdb)
- [`hdb` component](../hdb)
- [`qsl/store` library](../../libraries/qsl/store.q)


-------------------------------------------------------------------------------
## **`eodMng/hdbHk` component**
`eodMng/hdbHk` - `hdb` housekeeping component - performing housekeeping in the `hdb` directory.
Component is located in the `ec/components/eodMng`.

### Functionality
- plug-in based process that performs housekeeping operation on the `hdb` directory 
- performing predefined tasks such as deletion, compression, conflation, etc. enabled through plugins
- providing functionality (through dedicated API) to write custom plugins
- actions are executed after end-of-day process, but before `hdb` synchronization between sites
- `hdbHk` in production system is usually triggered from `eodMng`

### Configuration
Each housekeeping task is a named action defined in housekeeping process (`core.hdbHk`). Each such
task is executed according to defined task queue and table assignment in `dataflow.cfg`. Plugin is
executed on specific date in the past (please see `dayInPast` parameter).

#### system.cfg example
In order to activate defined housekeeping job, `eodMng` needs to be configured properly in
`system.cfg` configuration file (example configuration entry below):

```cfg
[group:core]
  [[core.eodMng]]
    ...
    cfg.hkProcessName = core.hdbHk
```

#### dataflow.cfg example
Table `quote` is defined in housekeeping process in `dataflow.cfg` file (there might be more housekeeping jobs defined per table). 

```cfg
[table:quote]
  [[core.hdbHk]]
    hdbHousekeeping = ((action(mrvs),dayInPast(30)), (action(delete),dayInPast(120)))
```
where:
- `action` – housekeeping plugin to run (e.g. `mrvs`)
- `dayInPast` – specifies the date in the past (`EOD` date minus `dayInPast`) 

Given setup will execute:
- plugin `mrvs` on partition with date `EOD_DATE-30`
- plugin `delete` on partition with date `EOD_DATE-120`

### Startup
`hdbHk` script is invoked from `eodMng` and terminates after completing the task.
Action parameters are passed via command line parameters:
- `-hdb` - path to source hdb
- `-hdbConn` - name of hdb process to be reloaded after housekeeping procedure
- `-date` (optional) - date for which housekeeping will be performed, if not specified then current date is used
- `-status` (optional) - path to file which housekeeping status is written (required for `eodMgn` communication)
- `-noexit` - by omitting this option, the process will terminate automatically

Housekeeping script can be also started directly via `yak` command and cli parameters (using `–a`), e.g.:
```bash
>yak start batch.core_hdbHk -a "-hdb ${EC_SYS_PATH}/data/core.hdb -hdbConn core.hdb -date 2013.01.01 -status ${EC_SYS_PATH}/data/core.eodMng/hkStatus"
```
Direct `hdbHk` startup can be useful for e.g. testing purposes.

### Plugins
Following example will illustrate most recent values (`mrvs`) plugin integration: `mrvs` code is predefined in `core.hdbHk`, 
custom plugins can be loaded via `libs` field in `system.cfg`. Predefined version has the following code:

```q
.hdbHk.plug.action[`mrvs]:{[date;tableHnd;args]
  columns:cols[tableHnd];
  lasts:columns except `sym;
  result:columns xcols 0!?[tableHnd; () ; (enlist `sym)!enlist `sym ; ()];
  tableHnd set result;
  @[tableHnd;`sym;`p#];
  };
```

### Implementation overview

#### Workflow
1. Load configuration file with list of tasks
2. Tasks from the file are loaded into `.hdbHk.cfg.taskList` table
3. Tasks are executed based on the order in the configuration file / `.hdbHk.cfg.taskList` table

> **Notes:**
> 1. Please remember to order the tasks correctly, for example conflation before compression
> 2. Each plugin call is logged and wrapped in protected evaluation
> 3. Before modification each table partition is backed up in `cfg.bckDir` directory

#### Task list
Housekeeping script (`hdbHk.q`) is part of the `eodMng` that manages hdb housekeeping and can be extended through plugins. 
Tasks to be performed by this script are in the `.hdbHk.cfg.taskList` table:

plugin     | table           | day_in_past | param1 | param2 | . . .  | param6
-----------|-----------------|-------------|--------|--------|--------|-------
`compress` | tab1,tab2,tab3  | 30          | arg_1  | arg_2  |        |
`delete`   | tab1,tab2       | 50          |        |        |        |

where:

- `plugin` - name of the plugin (symbol - all plugins exist in `.eodsnc.hk.plugins` namespace)
- `table` - list of tables on which plugins will be operating (``enlist ` `` for all tables)
- `day_in_past` - distance (in days) between *current date*, and date of partition that will be modified by plugin (1 for previous day, 2 for two days ago etc.)
- `param[1-6]` - additional parameters passed to plugin (up to 6 parameters)

For the given table, `hdbHk.q` would execute following function calls:

```q
q).eodsnc.hk.plugins.compress[date;`tab1;arg1;arg2;arg3];
q).eodsnc.hk.plugins.compress[date;`tab2;arg1;arg2;arg3];
q).eodsnc.hk.plugins.compress[date;`tab3;arg1;arg2;arg3];
q).eodsnc.hk.plugins.delete[date;`tab1;arg`;arg2;arg3];
q).eodsnc.hk.plugins.delete[date;`tab2;arg`;arg2;arg3];
```

#### `hdbHk` status file
`[eodMng.dataPath]/eodMngStatus`
File generated by housekeeping (`hdbHk.q`) - used to inform eodMng of housekeeping status/
Status format:
```txt
 status timestamp
```
- `timestamp` – timestamp of the status
- `status` - one of possible statuses:
  - `begin` - housekeeping in progress
  - `success` - housekeeping process finished successfully

Status file example:
```txt
 begin 2013.02.17T16:38:44.812
```

### Further reading

- [general housekeeping](../hk)
- [eodMng/eodMng](#eodmngeodmng-component)
- [eodMng/hdbSync](#eodmnghdbsync-component)
- [Testing the end-of-day procedure](../../doc/Testing-the-end-of-day-procedure.md)
- [`hdb` component](../hdb)
- [`qsl/store` library](../../libraries/qsl/store.q)


-------------------------------------------------------------------------------
## **`eodMng/hdbSync` component**
`eodMng/hdbSync` - `hdb` synchronization component - performing synchronization on the `hdb` directory between two systems.
Component is located in the `ec/components/eodMng`.

### Functionality
- Synchronize multiple databases between multiple hosts. 

### Configuration

#### system.cfg example
Minimal configuration for synchronization require `eodMng` configuration in `system.cfg` file. For example:
```cfg
  [[core.eodMng]]          
    type = q:eodMng/eodMng 
    # ...
    # Configuration that is vital for eodMng processes communication and synchronization
    cfg.eodMngList = ((eodMng(core.eodMng), hdb(core.hdb), rdb(core.rdb)), (eodMng(prod2.eodMng),hdb(prod2.hdb),rdb(prod2.rdb)))
    # Synchronization process to run (as defined in system.cfg) configuration file
    cfg.syncProcessName = core.hdbSync

  # Configuration of connection to eodMng process on 2nd production
  [[prod2.eodMng]]
    type = c:eodMng    # Note - c: prefix defines 'connection' in contrast to 'q process' 
    port = 1234
    host = prod2.internal.eu                         

  # Configuration of hdb process on 2nd production.
  [[prod2.hdb]]
     type = c:hdb                       
     port = 12345                       
     host = prod2.internal.eu             # Note - `host` field required for data synchronization
     EC_DATA_PATH = /kdb/data/core.hdb    # Note - `EC_DATA_PATH` field required for data synchronization
```

#### `rsync` configuration
`hdbSync` is relaying on `rsync` system tool. In order to use it effectively operating system needs to be configured properly. 
Such configurations are out of scope of this document, but please refer to on-line manual pages available on your OS (`rsync(1`), `ssh(1)`, `ssh-copy-id(1)`).

### Startup
`hdbSync` script is invoked from `eodMng` and terminates after completing the task.
Action parameters are passed via ordered list of command line parameters `source dest date symBackupLocation [statusLocation]`
- `source` – location of source database
- `dest` – location of destination database (can be specified in host:directory notation for remote hosts)
- `date` – date to synchronize
- `symBackupLocation` – directory where original destination sym file will be stored for backup purposes.
- `statusLocation` – optional; path to file to which status information will be written

Synchronization script can be also started directly via `yak` command and cli parameters (using `–a`), e.g.:
```bash
> yak console core.hdbSync -a "/hdb /mirror/hdb 2001.04.23 /data/mirror/backup"
```
Direct `hdbSync` startup can be useful for e.g. testing purposes.

### Implementation overview

#### `hdbSync` status file
File generated by synchronization (`hdbSync.q`) - used to inform eodMng of synchronization status.
Status format:
```txt
 status timestamp
```
- `timestamp` – timestamp of the status
- `status` - one of possible statuses:
  - `begin` - synchronization started - sym file backup
  - `sync_partition` - sym backup completed, synchronizing current partition
  - `sync_all` - sym backup completed, synchronizing current partition   
  - `success` - synchronization successful

Status file example:
```txt
 sync_partition 2013.02.17T16:38:44.812
```

### Further reading

- [eodMng/eodMng](#eodmngeodmng-component)
- [eodMng/hdbHk](#eodmnghdbhk-component)
- [Testing the end-of-day procedure](../../doc/Testing-the-end-of-day-procedure.md)
- [`hdb` component](../hdb)
