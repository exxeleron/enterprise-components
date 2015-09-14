## **`hdbWriter` component**
`hdbWriter` - writes historical data directly into the hdb.
Component is located in the `ec/components/hdbWriter`.

### Functionality
- writing data directly to the hdb process
- support for writing to multiple different partitions
- support for data appending

### Configuration
Note: configure port and component name according to your conventions (core.hdbWriter)

#### system.cfg example
```cfg
  [[core.hdbWriter]]          
    command = "q hdbWriter.q"     
    type = q:hdbWriter/hdbWriter     
    port = ${basePort} + 13     
    # dstHdb should point to the destination hdb which will be amended via the hdbWriter
    # only one dstHdb can be specified
    cfg.dstHdb = core.hdb
```

#### system.cfg example
```cfg
  [table:myTable]
    [[core.hdbWriter]]          
```

### Startup
start hdbWriter process
```bash
> yak start core.hdbWriter
```

### Simple usage example
```q
q)/ execute on core.hdbWriter process 
q)
q)/ 1. insert the data
q) .hdbw.insert[`trade;tradeChunk1];
q) .hdbw.insert[`trade;tradeChunk2];
q) .hdbw.insert[`quote;quoteChunk2];
q)
q)/ 2. organize the data
q) .hdbw.organize[`ALL;`ALL];
q)
q)/ 3. finalize loading process
q) .hdbw.finalize[`ALL;`ALL];
```

### Detailed usage description

#### 1. data insertion
Insert the data - as many chunks as you have, tradeChunk is expected to be:
- a q table (QTable in qJava, see src/test/java/com/exxeleron/qjava/QExpressions.java for sample usage)
- or a list of columns

```q
q)/ execute on core.hdbWriter process 
q) .hdbw.insert[`trade;tradeChunk1];
q) .hdbw.insert[`trade;tradeChunk2];
q) .hdbw.insert[`quote;quoteChunk2];
```

#### 2. data organization
organize the data (this is mainly sorting)
 
```q
q)/ execute on core.hdbWriter process 
q) .hdbw.organize[`ALL;`ALL];
```

#### 3. manual data validation [optional]
manually validate the data on the hdbWriter process, 
inserted data is loaded into hdbWriter process in the global namespace
 
```q
q)/ execute on core.hdbWriter process 
q) .tabs.status[`];
tab   | format     | rowsCnt | err |  columns    
------+------------+---------+-----+---------------------------------------------
quote | PARTITIONED | 3570    |     | `date `sym `time `bid `bidSize `ask `askSize
trade | PARTITIONED | 720     |     | `date `sym `time `price `size

q) select count i by date from quote
date       | x
-----------+------
2014.05.08 | 3570

q) select count i by date from trade
date       | x
-----------+-----
2014.05.08 | 720
```

#### 4. finalization
 - archive old partitions from dstHdb
 - move to the dstHdb
 - reload dstHdb process
 
```q
q)/ execute on core.hdbWriter process 
q) .hdbw.finalize[`ALL;`ALL];
```

#### cleanup
 decide on the archive, delete if not required anymore
 
 see {hdbWriter datapath}/archive/

### Implementation details

 The main principles behind the hdbWriter design:
 1. safety of the existing hdb data.
 2. consistency of the hdb after the data load.

#### solving typical pitfalls
 What are the typical pitfalls while updating the hdb and how is hdbWriter hanlding them:
 1. different data model of the input data and hdb data
    - solution: covered by the model validation during `.hdbw.insert[]`
 2. process interupted in the middle of writing, hdb data left in an inconsistent state
    - solution: data is prepared/written in a tmpHdb, in worsk case tmpHdb will get corrupted, but the main hdb is safe
 3. running out of disk space
    - solution: data is prepared/written in a tmpHdb, in worsk case tmpHdb will get corrupted, but the main hdb is safe
 4. other writing process
    - at the moment responsibility for not writing from different processes at the same time is on the user's side.
 5. the same data is entered twice accidently
    - at the moment responsibility for entering the data only once is on the user's side.

#### appending to the existing partition
on `.hdbw.insert`:
  - initial partition is copied from the dstHdb to tmpHdb
  - data is appended to tmpHdb

on `.hdbw.finalize`:
  - old partition from `dstHdb` is moved to the archive
  - amended partition from `tmpHdb` is moved to the `dstHdb`

 important! - `hdbWriter` is never removing any records, it dones not check for duplicates - it is a responsibility of the user.
 
#### tmpHdb

 `hdbWriter` keeps only one tmpHdb

#### archive

 archive directory contains backup copies of the original destination hdb partitions that were modified during data loading process.

 hdbWriter does not delete any data - has to be done by the user or by the hk component

 !important! - hdbWriter does not delete any data by default
    - it just moves previous versions of partitions to the archive, thus keep in mind
    that it can use lots of disk space!!

#### memory usage
`hdbWriter` is optimizaed for minimal memory usage.

#### disk usage
`hdbWriter` might be using a lot of disk space in case of appending to the exisitng partitions.
It is performing copy of the table partition data before appending to it.
In case of large `hdb` databases, it is recommended to insert all the data for one day at once, and to perform `.hdbw.organize` and `.hdbw.finalize` and cleanup of the `archive` directory before starting the insertion of another day's data.

#### paralell writing
important! - there should be only one hdbWriter that is inserting to one table partition at a time.

### Further reading
- [`hdb` component](../hdb)
