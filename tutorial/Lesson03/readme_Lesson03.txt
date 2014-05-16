-------------------------------------------------------------------------------
3.1 Lesson03 - Data historization
  Lesson03 shows how to historize the data in hdb. Lesson03 features:
  - Lesson02 components
  - Adding new component core.hdb (see etc/system.cfg)
  - Tables based on marketDataTemplate are now historized in core.hdb (see etc/dataflow.cfg)
  
  Hint:
  It helps to diff *.cfg files from this lesson with files from previous lesson - that way
  any changes / extensions will be clearly visible.

-------------------------------------------------------------------------------
3.2 Lesson03 installation

  Follow steps from readme.txt -Changing DemoSystem Lesson-. 
  Use Lesson03/etc configuration set.

-------------------------------------------------------------------------------
3.3 Lesson03 system inspection 

3.3.1 Check subscription status - it should contain two rows
  (remember the number of rows in these tables, will be required in point 3.3.3)
  
  core.rdb) .sub.status[]
    tab   | name  | src       | subProtocol     | srcConn | rowsCnt
    ------+-------+-----------+-----------------+---------+-------- 
    quote | quote | core.tick | PROTOCOL_TICKHF | open    | 3280
    trade | trade | core.tick | PROTOCOL_TICKHF | open    | 660

3.3.2 Manually trigger artificial eod (end of day) action.

  Note: 
  Data that was accumulated until now in the core.rdb will be written to core.hdb with yesterdays date.
  
  core.tick) .u.end[.z.d]
    ::  
  
3.3.3 Check subscription status again (compare rows counts from 3.3.1)

  core.rdb) .sub.status[]
    tab   | name  | src       | subProtocol     | srcConn | rowsCnt
    ------+-------+-----------+-----------------+---------+-------- 
    quote | quote | core.tick | PROTOCOL_TICKHF | open    | 250
    trade | trade | core.tick | PROTOCOL_TICKHF | open    | 50

3.3.4 Check hdb tables after eod

  core.hdb) tables[]
    quote
    trade

3.3.5 Check hdb tables status

  core.hdb) .hdb.status[] 
    tab   | format     | rowsCnt | err |  columns    
    ------+------------+---------+-----+---------------------------------------------
    quote | PARITIONED | 3570    |     | `date `sym `time `bid `bidSize `ask `askSize
    trade | PARITIONED | 720     |     | `date `sym `time `price `size
  
3.3.6 Check hdb tables after eod

  core.hdb) select count i by date from quote
    date       | x
    -----------+------
    2014.05.08 | 3570

  core.hdb) select count i by date from trade
    date       | x
    -----------+-----
    2014.05.08 | 720

3.3.7 Check content of core.hdb subdirectory

  DemoSystem> ls -l log/core.hdb/
    core.hdb_2014.05.08T09.13.57.env
    core.hdb_2014.05.08T09.13.57.err
    core.hdb.2014.05.08T09.13.57.log
    core.hdb_2014.05.08T09.13.57.out
    current.log -> core.hdb.2014.05.08T09.13.57.log
    init.log -> core.hdb.2014.05.08T09.13.57.log

3.3.8 Check if DemoSystem/data/core.hdb contains hdb data
  
  DemoSystem> ls -l data/core.hdb/
    2014.05.08
    sym
 
-------------------------------------------------------------------------------
3.4 Lesson03 accomplishments

- new component core.hdb running on port 17012 is added
- all tables built on top of marketData template are now historized in core.hdb

-------------------------------------------------------------------------------
