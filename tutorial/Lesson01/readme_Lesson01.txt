------------------------------------------------------------------------------------------------------------------------
1.1 Lesson01 - Initial system

  Lesson01 consist of three components responsible for generation, distribution and capturing trade table:
  - core.gen    - mock data generator for trade table
  - core.tickHF - distributes trades updates across the system
  - core.rdb    - real time database capturing incoming updates to trade table

------------------------------------------------------------------------------------------------------------------------
1.2 Lesson01 installation

 Follow steps from readme.txt -DemoSystem installation-. 
 Use Lesson01/etc configuration set.
------------------------------------------------------------------------------------------------------------------------
1.3 Lesson01 system inspection 

1.3.1 Check system state

  DemoSystem> yak info \*
    uid                pid   port  status      started             stopped            
    ----------------------------------------------------------------------------------
    core.gen           11281 17009 RUNNING     2014.05.08 07:40:03                    
    core.rdb           11293 17011 RUNNING     2014.05.08 07:40:04                    
    core.tick          11287 17010 RUNNING     2014.05.08 07:40:03
    
  If all three processes are running, than the system is working properly. Otherwise, please refer to troubleshooting.txt. Next steps will
  navigate you trough the system;

1.3.2 Check if data and log directories were created

  DemoSystem> ls -l 
    bin
    data
    etc -> bin/ec/samples/DemoSystem/Lesson01/etc/
    log
    readme.txt
    troubleshooting.txt
    
1.3.3 Check if all processes have their subdirectories in DemoSystem/log/

  DemoSystem> ls -l log
    core.gen
    core.rdb
    core.tick
    yak

1.3.4 Check if log file for core.rdb is available

  DemoSystem> yak log core.rdb
    INFO  2014.05.08 07:40:04.203 sl    - KDB+ ver: 3.1 rel: 2014.03.27 OS: l32 PID: 11293
    INFO  2014.05.08 07:40:04.204 sl    - no license found
    INFO  2014.05.08 07:40:04.204 sl    - user: userName host: userHost port: 17011
    INFO  2014.05.08 07:40:04.204 sl    - dir: DemoSystem/bin/ec/components/rdb file: rdb.q
  
1.3.5 Check if all processes have their subdirectories in DemoSystem/data/

  DemoSystem> ls -l data
    core.gen
    core.rdb
    core.tick
    shared
    yak
 
1.3.6 Check if data/core.tick/ contains growing journal file

  core.tick> ls -la
    -rw-rw-r-- 1 userName userName 40178 May  8 09:47 core.tick2014.05.08
  core.tick> ls -la
    -rw-rw-r-- 1 userName userName 40796 May  8 09:47 core.tick2014.05.08

1.3.7 Check rdb tables - it should contain one table - trade

  core.rdb) tables[]
    trade
 
1.3.8 Check subscription status - it should contain one row with trade table
  
  core.rdb) .sub.status[]
    tab   | name  | src       | subProtocol     | srcConn | rowsCnt
    ------+-------+-----------+-----------------+---------+--------
    trade | trade | core.tick | PROTOCOL_TICKHF | open    | 3560
  
  Hint:
  Executing this function few times shows increase in rowsCnt which indicates incoming data.

1.3.9 Check content of trade table (data will differ as it's randomly generated)
 
  core.rdb)  -3#trade
    time         | sym   | price              | size
    -------------+-------+--------------------+-----
    08:10:44.306 | LUJOW | 2.833303320221603  | 
    08:10:44.306 | YAKJH | 53.228960861451924 | 38
    08:10:44.306 | EIRSE | 15.618060110136867 | 66
 
------------------------------------------------------------------------------------------------------------------------
1.4 Lesson01 results

- deployed working system 
- q processes running in the background, controlled by yak - the process manager
- basic workflow for generating and capturing market data table - trade

------------------------------------------------------------------------------------------------------------------------
