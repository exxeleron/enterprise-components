End-of-day (`eod`) procedure can be tested from the different points in the system. Picture below
presents setup with `tickHF`, `rdb`, and `eodMng` components.

Entry points (numbered from 1 – 6 in the table below) correspond to interface functions available on
each process (`tickHF`, `rdb`, `eodMng`).

One should keep in mind that calling end-of-day manually will cause "chain reaction" on components
after this function call. For example, calling third function `.u.end` (3) will automatically
trigger calls (4), (5) and (6).

```
+------+-------------------------+---------------------------------+--------------------------------------------------------------------+
| Call | Function                | Effects on the component        | Notes                                                              |
| No   | (component / filename)  | (component / filename)          |                                                                    |
+------+-------------------------+---------------------------------+--------------------------------------------------------------------+
| 1    | .u.endofday[]           | - date changed to the next date | - tickHF is preserving received data to the journal file. Current  |
|      | (tickHF/tickHF.q)       | - journal file name changed (to |   journal name is kept in .u.L variable.                           |
|      |                         |   new date)                     | - current date is kept in .u.d.                                    |
|      |                         |                                 | - these variables are described in TickHF->tickHF.q                |
|------|-------------------------|---------------------------------|--------------------------------------------------------------------|
| 2    | .u.end[date]            | N/A                             | - this function broadcasts end-of-day to all subscribers that are  |
|      | (tickHF/u.q)            |                                 |   present in .u.w (TickHF/tickHF.q)                                |
|------|-------------------------|---------------------------------|--------------------------------------------------------------------|
| 3    | .u.end[date]            | - date changed to the next date | - eod callback is sent to all subscribers (function .u.end should  |
|      | (rdb/rdb.q)             | - depends on the before- and    |   be also defined on subscribers)                                  |
|      |                         |   after-eod plugins defined     | - current date is stored in .rdb.date variable. After date         |
|      |                         |   (e.g. modify existing data    |   rollover .u.end won’t be executed again (if triggered manually); | 
|      |                         |   in rdb)                       |   To call it once again, rollback date with a call on rdb process: |
|      |                         |                                 |       q) .rdb.date-:1                                              |
|      |                         |                                 | - all eod plugins should be defined in separate custom libraries   |
|      |                         |                                 |   loaded using ‘–lib‘ command line option in system.cfg (for       | 
|      |                         |                                 |   example: rdb.q –lib customLib/eodPlugin.q)                       |
|------|-------------------------|---------------------------------|--------------------------------------------------------------------|
| 4    | .store.run[date]        | - status changed in eodStatus   | - eodMng detects status change; after that housekeeping and        |
|      | (rdb/store.q)           |   file                          |   synchronization are called automatically                         |
|      |                         |   (data/rdb/eodStatusYYYY.mm.dd)| - to restore status in the eodMng: stop eodMng, delete all status  |
|      |                         |   with current date to one of   |   files in data/eodMng/ and start eodMng again                     |
|      |                         |   the eod states  and new one   | - tables from the rdb processes will be stored on disk in          |
|      |                         |   created for the next date     |   ascending size order (tables with smaller row count will be      |       
|      |                         | - tables cleared from the memory|   stored before tables with large row count); this behavior        |
|      |                         |   of the rdb process according  |   ensures optimal memory usage during writing data to disk         |
|      |                         |   to the configuration in       |                                                                    |
|      |                         |   dataflow.cfg                  |                                                                    |
|      |                         | - new partition created in hdb; |                                                                    |
|      |                         |   if partition already existed  |                                                                    |
|      |                         |   then data will be overwritten |                                                                    |
|------|-------------------------|---------------------------------|--------------------------------------------------------------------|
| 5    | .hdbHk.performHk[...]   | - backup created with partition | - this function is invoked in batch scripts during startup of the  | 
|      | (hdbHk/hdbHk.q)         |   that will be modified by      |   process; description how to test it is presented below           |
|      |                         |   housekeeping script           | - location of backup directory is described in hdbHk.qsd.          |
|------|-------------------------|---------------------------------| - location of backup directory with sym files is given from        |
| 6    | .hdbHk.performSync[...] | - backup created by hdb’s sym   |   command line parameters                                          |
|      | (hdbSync/hdbSync.q)     |   file                          |                                                                    |
|      |                         | - partitions synchronized       |                                                                    |
|      |                         |   between two hosts             |                                                                    |
+------+-------------------------+---------------------------------+--------------------------------------------------------------------+
```

> **Note:**
> 
> Descriptions of the above interface functions can be found in Enterprise Components 3.0 Developers'
> Documentation (TickHF->tickHF.q, Rdb->rdb.q, EodMng->eodMng.q)

Full `eod` is triggered from `tickHF` component. In daily procedure `tickHF` is checking if the day
changed and at midnight `.u.endofday` (1) is called. Depending on `system.cfg` configuration, `eod`
can be triggered in local or UTC time (UTC is the default value; configuration variable
`timestampMode` specifies which value to use).

```cfg
timestampMode = LOCAL
[group:core]
  [[core.tickHF]]
    type = q:tickHF/tickHF 
    port = ${basePort} + 10
    command = "q tickHF.q"
  
  [[core.rdb]]
    type = q:rdb/rdb
    port = ${basePort} + 20
    command = "q rdb.q"
```

Next, `.u.end` (2) function is invoked and end-of-day message is broadcasted to all
subscribers. Each subscriber (e.g. `rdb`) has to define `.u.end` (3) function. Before performing
`.store.run` (4), `store.q` library requires initialization of `eod` configuration parameters in
`dataflow.cfg` (see example below):

```cfg
[table:quote]
  [[core.rdb]]
    serverSrc = core.tickHF
    # end-of-day specific parameters start HERE
    # hdb path is taken from system.cfg for given hdbConn
    hdbConn = core.hdb
    eodClear = 1
    eodPerform = 1
```

> **Note:**
> 
> `store.q` is initialized by the `.store.init` function (Enterprise Components 3.0 Developers'
> Documentation (Qsl->store.q)) invoked during startup of the `rdb` process.
