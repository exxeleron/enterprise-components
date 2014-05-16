-------------------------------------------------------------------------------
2.1 Lesson02 - Adding quote table
  
  Lesson02 shows how to add new table basing on the table template. Lesson02 features:
  - Lesson01 components
  - New template marketData is created (see etc/dataflow.cfg)
  - Table trade is now based on marketData template (see etc/dataflow.cfg)
  - New table quote based on marketData template is added (see etc/dataflow.cfg)
  
  Hint:
  It helps to diff *.cfg files from this lesson with files from previous lesson - that way
  any changes / extensions will be clearly visible.

-------------------------------------------------------------------------------
2.2 Lesson02 installation

  Follow steps from readme.txt -Changing DemoSystem Lesson-. 
  Use Lesson02/etc configuration set.

-------------------------------------------------------------------------------
2.3 Lesson02 system inspection 

2.3.1 Check rdb tables - it should contain two tables - trade and quote

  core.rdb) tables[]
    quote
    trade 
 
2.3.2 Check subscription status - it should contain two rows
  (execute several times to see if the values are changing)
  
  core.rdb) .sub.status[]
    tab   | name  | src       | subProtocol     | srcConn | rowsCnt
    ------+-------+-----------+-----------------+---------+-------- 
    quote | quote | core.tick | PROTOCOL_TICKHF | open    | 150
    trade | trade | core.tick | PROTOCOL_TICKHF | open    | 30

2.3.3 Check content of trade and quote tables (data will differ as it's randomly generated)
  
  core.rdb)  -3#trade
    time         | sym   | price             | size 
    -------------+-------+-------------------+-----
    09:06:38.114 | WFDMY | 65.32275422941893 | 65
    09:06:38.114 | UGQIR | 79.05246829614043 | 35
    09:06:38.114 | UBJNL | 80.97451596986502 | 71
  
  core.rdb)  -3#quote
    time         | sym   | bid               | bidSize | ask                | askSize
    -------------+-------+-------------------+---------+--------------------+--------
    08:22:01.546 | SUBNW | 28.54233463294804 | 39      | 59.31096689309925  | 75
    08:22:01.546 | PFSLJ | 60.82742747385055 | 84      | 12.640044651925564 | 94
    08:22:01.546 | FOMRS | 96.59238473977894 | 85      | 79.28916201926768  | 55

-------------------------------------------------------------------------------
2.4 Lesson02 accomplishments

- marketData template allows easy configuration of number of tables that are following the same flow 
- template fields can be overwritten - see frequency in quote table

-------------------------------------------------------------------------------
