/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/-/
/-/ Licensed under the Apache License, Version 2.0 (the "License");
/-/ you may not use this file except in compliance with the License.
/-/ You may obtain a copy of the License at
/-/
/-/   http://www.apache.org/licenses/LICENSE-2.0
/-/
/-/ Unless required by applicable law or agreed to in writing, software
/-/ distributed under the License is distributed on an "AS IS" BASIS,
/-/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/-/ See the License for the specific language governing permissions and
/-/ limitations under the License.

/A/ DEVnet:  Bartosz Dolecki
/V/ 3.0

/S/ Hdb housekeeping tool:
/-/ Responsible for:
/-/ - performing predefined tasks such as deletion, compression, conflation, etc. enabled through plugins
/-/ - providing functionality (through dedicated API) to write custom plugins
/-/ 
/-/ Input parameters for the script:
/-/ hdbHk.q is invoked from eodMng.q process and receives following input parameters
/-/ - hdb - path to hdb
/-/ - hdbConn - name of hdb process to be reloaded after housekeeping procedure
/-/ - date (optional) - date for which housekeeping will be performed, current date is used if none is specified
/-/ - status (optional) - path to the file where housekeeping status is stored (required for eodMng communication)
/-/ 
/-/ *Sample command using yak*
/-/ (start code)
/-/ yak start batch.core_hdbHk -a "-hdb HDB/DATA/PATH -hdbConn core.hdb -date 2012.01.01 -status EOD_MNG/DATA/PATH/hkStatus"
/-/ (end)
/-/ 
/-/ Workflow:
/-/ 1. - Configuration file is loaded with list of tasks
/-/ 2. - Tasks from the file are loaded into .hdbHk.cfg.taskLis table
/-/ 3. - Tasks are executed based on the order in the configuration file / .hdbHk.cfg.taskList table
/-/ 
/-/ *Notes*
/-/ - Please remember to order the tasks correctly, for example conflation before compression
/-/ - Each plugin call is logged and wrapped in protected evaluation
/-/ 
/-/ Overview:
/-/ Housekeeping script (hdbHk.q) is part of the eodMng and is used to manage hdb housekeeping which can be extended through plugins. Tasks to be performed by this script are in the .hdbHk.cfg.taskList table
/-/ (start code)
/-/ .hdbHk.cfg.taskList:
/-/ | plugin   | table           | day_in_past | param1 | param2 | . . .  | param6 |
/-/ |----------|-----------------|-------------|--------|--------|--------|--------|
/-/ | compress | tab1,tab2,tab3  | 30          | arg_1  | arg_2  |        |        |
/-/ | delete   | tab1,tab2       | 50          |        |        |        |        |
/-/ (end)
/-/ where
/-/ plugin - name of the plugin (symbol - all plugins exists in .eodsnc.hk.plugins namespace)
/-/ table - list of tables on which plugins will be operating (enlist ` for all tables)
/-/ day_in_past - distance (in days) between *current date*, and date of partition that will be modified by plugin (1 for previous day, 2 for two days ago etc.)
/-/ param[1-6] - additional parameters passed to plugin (up to 6 parameters)
/-/ 
/-/ For the given table, hdbHk.q would execute following function calls, where date is 30 (for compress) and 50 (for delete) days before current date
/-/ (start code)
/-/ .eodsnc.hk.plugins.compress[date;`tab1;(arg1;arg2;arg3)];
/-/ .eodsnc.hk.plugins.compress[date;`tab2;(arg1;arg2;arg3)];
/-/ .eodsnc.hk.plugins.compress[date;`tab3;(arg1;arg2;arg3)];
/-/ .eodsnc.hk.plugins.delete[date;`tab1;()];
/-/ .eodsnc.hk.plugins.delete[date;`tab2;()];
/-/ (end)
/-/ 
/-/ *Note*
/-/ Each plugin has its two first parameters fixed
/-/ 1. - current partition date 
/-/ 2. - table on which it should operate (plugin is called for each table separately) 
/-/ 
/-/ Table backup:
/-/ As a backup, each table is saved in its original state in <.cfg.bckDir> before any housekeeping procedures are applied. Backup from each day is stored in a separate directory ‘hdbConn/date’ where
/-/ hdbConn - hdb name to be processed
/-/ date - date of housekeeping execution (current date)
/-/ 
/-/ Layout of the directory is the same as for hdb, for example for following parameters
/-/ hdbConn - kdb.hdb
/-/ date - 2012.07.12
/-/ tasklist1 - conflation for table1,table2 ; day_in past = 2;
/-/ tasklist2 - compression for table2; table3; day_in_past = 3;
/-/ structure of the the cfg.bckDir would be
/-/ (start code)
/-/ ../kdb.hdb2012.07.12                    - directory for backup from 2012.07.12
/-/ ../kdb.hdb2012.07.12/2012.07.09         - directory for compression (day_in_past = 3)
/-/ ../kdb.hdb2012.07.12/2012.07.09/table2  - backup of table2 
/-/ ../kdb.hdb2012.07.12/2012.07.09/table3  - backup of table3
/-/ ../kdb.hdb2012.07.12/2012.07.10         - directory for conflation (day_in_past = 2)
/-/ ../kdb.hdb2012.07.12/2012.07.10/table1  - backup of table1
/-/ ../kdb.hdb2012.07.12/2012.07.10/table2  - backup of table2 
/-/ (end)
/-/ 
/-/ *Notes*
/-/ - Only original (unmodified by plugins) table partitions are backed up - if a table was conflated and then compressed only one backup (of the original partition) was performed before any plugins were applied
/-/ - In case of issues, damaged partitions can be restored from the backup
/-/ - Backups are deleted after N days defined in .cfg.bckDays variable in configuration file (by default set to 7 days)
/-/ 
/-/ Custom plugins:
/-/ Functionality of the hdbHk.q can be extended through custom plugins with following generic signature
/-/ (start code)
/-/ .hdbHk.plug.action[name of the plugin][date;tableHnd;args]
/-/ (end)
/-/ where
/-/ date - date of the partition on which it operates
/-/ tableHnd - file handle (symbol) for table partition
/-/ args - dictionary of parameters required by the plugin
/-/ 
/-/ When writing new plugins one should use only tableHnd to operate on partition table.
/-/ For example, following plugin to calculate most recent values could be added to the hdbHk.q
/-/ (start code)
/-/ .hdbHk.plug.action[`mrvs]:{[date;tableHnd;args]
/-/ columns:cols[tableHnd];
/-/ lasts:columns except `sym;
/-/ result:columns xcols 0!?[tableHnd; () ; (enlist `sym)!enlist `sym ; ()];
/-/ tableHnd set result;
/-/ @[tableHnd;`sym;`p#];
/-/ };
/-/ (end)

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";

/------------------------------------------------------------------------------/
.sl.init[`hdbHk];

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/handle"];
.sl.lib["qsl/os"];

/------------------------------------------------------------------------------/
/G/ Table with list of housekeeping tasks.
/-/  -- plugin:SYMBOL         - symbol with plugin name (ie. `compress for '.eodsync.hk.plugins.compress')
/-/  -- table:SYMBOL          - table name on which plugin should operate, (enlist `) for all tables
/-/  -- dayInPast:INT         - number of days separating current partition from partition on which 
/-/                           plugin should operate (eg. 5 would mean that plugin will work on partitions created 5 days ago)
/-/  -- performBackup:BOOLEAN - true if backup should be performed
/-/  -- param[1-6]:SYMBOL     - additional params for the plugin (ie. compression parameters for compression plugin)
.hdbHk.cfg.taskList:([] action:`$() ; table:(enlist ::); dayInPast:`int$(); performBackup:0#0b; param1:`$(); param2:`$(); param3:`$(); param4:`$(); param5:`$(); param6:`$());

/------------------------------------------------------------------------------/
/G/ Directory with initial definition of housekeeping plugins.
.hdbHk.plug.action:()!();

/------------------------------------------------------------------------------/
/F/ Returns full path to the given hdb date directory.
/P/ dt:DATE - day
/R/ :SYMBOL - full path
/E/ .hdbHk.getDateHnd 2011.01.01
.hdbHk.getDateHnd:{[dt]
  :$[0=count .hdbHk.cfg.hdbPars;
    ` sv (.hdbHk.cfg.hdbPath;`$string[dt]);
    [
      idx:dt mod count .hdbHk.cfg.hdbPars;
      ` sv (hsym `$.hdbHk.cfg.hdbPars[idx];`$string[dt])
      ]
    ];
  };

/------------------------------------------------------------------------------/
.hdbHk.p.handleSet:([] handles:`$());

/------------------------------------------------------------------------------/
/F/ Executes plugins from .hdbHk.cfg.taskList in given order.
/-/  Main function of the script, writes the state of housekeeping to statusFile.
/P/ date:DATE - date for which housekeeping should be performed
/R/ no return value
/E/ .hdbHk.performHk[.z.d]
.hdbHk.performHk:{[date]
  .hdbHk.p.saveStatus[`begin];
  update table:((),/:table) from `.hdbHk.cfg.taskList;
  parts:$[0=count .hdbHk.cfg.hdbPars;
    key[.hdbHk.cfg.hdbPath];
    raze key each hsym each `$.hdbHk.cfg.hdbPars
    ];
  parts:parts except `sym;

  if[0<count parts;
    part:first parts;
    tabHnd:.hdbHk.getDateHnd[parse string[part]];
    tabs:key tabHnd;
    update table:{[tabs;x]$[x~(enlist `ALL);tabs;x]}[tabs] each table from `.hdbHk.cfg.taskList;
    ];
  
  .hdbHk.p.deleteOldBackups[date;.hdbHk.cfg.bckDir];    
  .hdbHk.cfg.bckDir:` sv (.hdbHk.cfg.bckDir;`$string[.hdbHk.cfg.hdbConn],string[date]);
  
  (.hdbHk.p.pluginAct[date] .) each {(4#x), enlist (4_x) where not null each 4_x} each flip value flip .hdbHk.cfg.taskList;
  
  // verify & reload hdb
  .hnd.hopen[.hdbHk.cfg.hdbConn;1000i;`eager];
  .log.info[`hdbHk] "Filling missing tables in hdb path ",string[.hdbHk.cfg.hdbPath];
  .pe.at[.Q.chk;.hdbHk.cfg.hdbPath;
    {[x;h].log.warn[`hdbHk] "Fill missing tables in hdb path ",string[h], " failed with: ",x }[;.hdbHk.cfg.hdbPath]];
  
  .log.info[`hdbHk] "Reloading hdb ",string[.hdbHk.cfg.hdbConn];
  .pe.at[.hnd.ah[.hdbHk.cfg.hdbConn]; ".hdb.reload[]";
    {[x].log.warn[`hdbHk] "Reload hdb ",string[.hdbHk.cfg.hdbConn], " failed with: ",x }];
  .hdbHk.p.saveStatus[`success];
  };

/------------------------------------------------------------------------------/
/F/ Saves status to file.
/P/ status:SYMBOL - status to write
.hdbHk.p.saveStatus:{[status]
  if[not `~.hdbHk.cfg.statusFile;
    .pe.at[.hdbHk.cfg.statusFile 0: ;enlist (string status)," ",(string .sl.zz[]);
      {[x;s].log.warn[`hdbHk] "Save status file",string[s], " failed with: ",x }[;.hdbHk.cfg.statusFile]];
    ];
  };

/------------------------------------------------------------------------------/
/F/ Clears old backups.
.hdbHk.p.deleteOldBackups:{[date;bckdir]
  toCut:count string[.hdbHk.cfg.hdbConn];
  bckDates:"D"$toCut _/:string key bckdir;
  toDelete:bckDates where bckDates>0; // delete non dates
  toDelete:toDelete where toDelete < date-.hdbHk.cfg.bckDays;
  {[date;bckdir].event.dot[`hdbHk;`.hdbHk.p.deleteOneDir;(date;bckdir);();
    `info`info`error;"Deleting old backup from ",string[bckdir] ," and date ",string[date]]}[;bckdir]each toDelete;
  };

/------------------------------------------------------------------------------/
.hdbHk.p.deleteOneDir:{[date;bckdir]
  .os.rmdir 1_string ` sv bckdir,`$string[.hdbHk.cfg.hdbConn],string[date] ;
  };

/------------------------------------------------------------------------------/
/                         hdb housekeeping plugins                             /
/------------------------------------------------------------------------------/
/F/ Hdb hk plugin for compressing splayed partitions preserving (splayed) file structure. 
/-/ Compression is supported by q and transparent for hdb.
/-/ More details compression available in http://code.kx.com/wiki/Cookbook/FileCompression
/P/ date:DATE       - the partition on which it operates (date)
/P/ tableHnd:SYMBOL - file handle for table partition
/P/ args:DICTIONARY - with keys:
/-/  -- logicalBlockSize:INT - always in power of 2 and between 12 and 20
/-/  -- compressionAlgorithm:INT - one of the following: 0 - none, 1 - kdb+ ipc, 2 - gzip
/-/  -- compressionLevel:INT - always between 0 and 9 (valid only for gzip, use 0 for other algorithms)
/R/ no return value
/E/ .hdbHk.plug.action[`compress][2012.01.01; `:/systemRoot/data/hdb/2012.01.01/trade/; `logicalBlockSize`compressionAlgorithm`compressionLevel!`17`2`6]
/-/   - action compresses :/systemRoot/data/hdb/2012.01.01/trade/ using given compression parameters.
.hdbHk.plug.action[`compress]:{[date;tableHnd;args]
  args:`logicalBlockSize`compressionAlgorithm`compressionLevel!"I"$string args;
  if[not args[`logicalBlockSize] within (12;20); '"Given logicalBlockSize is",string[args[`logicalBlockSize]], ". logicalBlockSize - is a power of 2 between 12 and 20"];
  if[not args[`compressionAlgorithm] in (0;1;2); '"Given compressionAlgorithm is",string[args[`compressionAlgorithm]], ". compressionAlgorithm - is one of the following, 0 (none), 1 (kdb+ ipc), 2 (gzip)"];
  if[not args[`compressionLevel] within (0;9); '"Given compressionLevel is",string[args[`compressionLevel]], ". compressionLevel - is between 0 and 9 (valid only for gzip, use 0 for other algorithms)"];
  tmpDir:.hdbHk.cfg.dataPath;
  tmpPath:` sv (tmpDir;`$string[date];`);
  columns:cols[tableHnd];
  {[tableHnd;tmpPath;lbs;ca;cl;x] 
     src:` sv (tableHnd;x);
     dest:` sv (tmpPath;x);
     .log.info[`compress] "compressing ",string[src]," to ",string[dest];
      -19!(src;dest;lbs;ca;cl)
  }[tableHnd;tmpPath;args`logicalBlockSize;args`compressionAlgorithm;args`compressionLevel;] each columns;

  colFiles:{[tmpDir;date;subDir] ` sv (tmpDir;`$string[date];subDir)}[tmpDir;date;] each key tmpPath;

  .log.info[`compress] "moving compressed files to ",string[tableHnd];
  .os.move[;1_string[tableHnd]] each 1 _/: string[colFiles];

  .log.info[`compress] "removing temp dir ",string[tmpPath];
  .os.rmdir 1_string tmpPath;
  };

/------------------------------------------------------------------------------/
/F/ Hdb hk plugin for deleting table in given partition. If partition is empty it will be deleted as well.
/P/ date:DATE       - the partition on which it operates date
/P/ tableHnd:SYMBOL - file handle for table partition
/P/ args:DICTIONARY - not used in `mrvs plugin, leave empty - ()!()
/R/ no return value
/E/ .hdbHk.plug.action[`delete][2012.01.01;`:/systemRoot/data/hdb/2012.01.01/trade/;()!()]
/-/   - action deletes :/systemRoot/data/hdb/2012.01.01/trade/ from the database
.hdbHk.plug.action[`delete]:{[date;tableHnd;args]
  tableHnd set 0#value tableHnd;
  };

/------------------------------------------------------------------------------/
/F/ Hdb hk plugin for conflating given table partition.
/P/ date:DATE       - the partition on which it operates date
/P/ tableHnd:SYMBOL - file handle for table partition
/P/ args:DICTIONARY - with column:
/P/  -- conflationInterval:INT - time in milliseconds for data conflation
/R/ no return value
/E/ .hdbHk.plug.action[`conflate][2012.01.01;`:/systemRoot/data/hdb/2012.01.01/trade/;(enlist `conflationInterval)!enlist `60000]
.hdbHk.plug.action[`conflate]:{[date;tableHnd;args]
  args:(enlist `conflationInterval)!"J"$string args;
  if[not args[`conflationInterval]>0; '"Given conflationInterval is",string[args[`conflationInterval]], ". conflationInterval should be grater then 0"];
  
  columns:cols[tableHnd];
  lasts: columns except `sym`time;
  result:update time:`time$time from columns xcols 0!?[tableHnd;();`sym`time!(`sym;(xbar;args[`conflationInterval];`time.second));lasts!((last),/:lasts)];
  tableHnd set result;
  @[tableHnd;`sym;`p#];
  };

/------------------------------------------------------------------------------/
/F/ plugin for removing all values except for the last value for each symbol
/P/ date:DATE       - the partition on which it operates date
/P/ tableHnd:SYMBOL - file handle for table partition
/P/ args:DICTIONARY - not used in `mrvs plugin, leave empty - ()!()
/R/ no return value
/E/ .hdbHk.plug.action[`mrvs][2012.01.01;`:/systemRoot/data/hdb/2012.01.01/trade/;()!()]
.hdbHk.plug.action[`mrvs]:{[date;tableHnd;args]
  columns:cols[tableHnd];
  lasts:columns except `sym;
  result:columns xcols 0!?[tableHnd; () ; (enlist `sym)!enlist `sym ; ()];
  tableHnd set result;
  @[tableHnd;`sym;`p#];
  };

/------------------------------------------------------------------------------/
/F/ Executes hk plugin.
/P/ date:DATE        - partition date
/P/ plugin:SYMBOL    - plugin name
/P/ tabs:LIST SYMBOL - tables names
/P/ when:INT         - n-th day in the past        
/P/ doBck:BOOLEAN    - do backup before hk action
/P/ args:DICT        - plugin parameters
/R/ no return value
/E/ .hdbHk.p.pluginAct[2012.01.01;`conflate;enlist `trade;7;1b;(enlist `conflationInterval)!enlist `60000]
/E/ .hdbHk.p.pluginAct[2012.01.01;`compress;enlist `trade;7;1b;`logicalBlockSize`compressionAlgorithm`compressionLevel!`17`2`6]
.hdbHk.p.pluginAct:{[date;plugin;tabs;when;doBck;args]
  hnd:.hdbHk.getDateHnd[date-when];
  if[()~ key hnd;  // partition does not exist
    .log.warn[`hdbHk] "Partition ", string[hnd], " does not exist";
    :();
    ];
  
  funcName:` sv`.hdbHk.plug.action,plugin;

  {[funcName;date;tab;when;doBck;args]
    tabHnd:` sv (.hdbHk.getDateHnd[date-when];tab);

    if[doBck and (not tabHnd in .hdbHk.p.handleSet); // if not in handleSet -> create backup
      `.hdbHk.p.handleSet insert tabHnd;
      .pe.dot[.hdbHk.p.backup;(date-when;tab);{[x;date;tab;when] .log.error[`hdbHk] "Performing backup of table ",string[tab]," for date ",string[date-when]," failed with: ",x}[;date;tab;when]];
      ];
    
    .event.dot[`hdbHk;funcName;(date-when;tabHnd;args);();`info`info`error;"Perform plugin ",string[funcName] ," for table ",string[tab]," date : ",string[date-when]]
    }[funcName;date;;when;doBck;args] each tabs;
  };

/------------------------------------------------------------------------------/
/F/ Creates backup of table partition in path specified by .hdbHk.cfg.bckDir.
/P/ date:DATE  - date of partition
/P/ tab:SYMBOL - nameof table 
.hdbHk.p.backup:{[date;tab] 
  tabHnd:` sv (.hdbHk.getDateHnd[date];tab);
  dst:1_string[.hdbHk.cfg.bckDir],"/",string[date];
  .log.info[`hdbHk]"Backup ",string[tabHnd], " to ", dst;
  //system "mkdir -p \"",dst,"\"";
  .os.mkdir dst;
  // system "cp -rf \"", 1_string[tabHnd],"\" \"",dst,"\"";
  .os.cpdir[1_string[tabHnd];dst]; 
  };

/------------------------------------------------------------------------------/
.hdbHk.p.raport:{[]
  raport:(`timestamp;`hdb;`tasks)!(.sl.zz[];.hdbHk.cfg.hdbPath;(select action,table,date:.sl.eodSyncedDate[]-dayInPast from .hdbHk.cfg.taskList));
  };

/------------------------------------------------------------------------------/
.hdbHk.p.getPartsHdb:{[hdbPath]
  path:` sv (hdbPath;`par.txt);
  :$[count key path;
    read0 path;
    ()];
  };

/==============================================================================/
/F/ Component initialization entry point.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]
  cmdParams:.Q.opt[.z.x];
  .hdbHk.cfg.hdbPath:hsym `$first cmdParams`hdb;
  .hdbHk.cfg.hdbPars:.hdbHk.p.getPartsHdb[.hdbHk.cfg.hdbPath];
  .hdbHk.cfg.hdbConn:`$first cmdParams`hdbConn;
  .hdbHk.cfg.statusFile:$[`status in key cmdParams;hsym `$first cmdParams`status;`];
  .hdbHk.cfg.date:$[`date in key cmdParams;"D"$first cmdParams`date;.sl.eodSyncedDate[]];
  .hdbHk.cfg.bckDir:        .cr.getCfgField[`THIS;`group;`cfg.bckDir];
  .hdbHk.cfg.bckDays:       .cr.getCfgField[`THIS;`group;`cfg.bckDays];
  .hdbHk.cfg.raportDir:     .cr.getCfgField[`THIS;`group;`cfg.raportDir];
  .hdbHk.cfg.dataPath:      .cr.getCfgField[`THIS;`group;`dataPath];

  backups:.cr.getCfgTab[`THIS;`table`sysTable;enlist `performBackup];
  t0:.cr.getCfgTab[`THIS;`table`sysTable;enlist `hdbHousekeeping];
  t1:ungroup select from  t0 where  0<> count each finalValue;
  if[not count t1;.hdbHk.p.saveStatus[`success]; .log.info[`hdbHk]"There are no actions to be performed by the ",string[.sl.componentId], ". Process will exit now.";:()];
  t2:(select table:sectionVal from t1) ,' t1[`finalValue];
  t3:t2 lj 1!select table:sectionVal, performBackup:finalValue from backups;
  t4:cols[.hdbHk.cfg.taskList] xcols t3;
  `.hdbHk.cfg.taskList insert t4;

  .sl.libCmd[];
  .hdbHk.performHk[.hdbHk.cfg.date];
  };

/------------------------------------------------------------------------------/
if[not all `hdb`hdbConn in key .Q.opt[.z.x];
  .log.error[`hdbHk]"Missing input parameters. Obligatory parmaters are: hdb and hdbConn";
  .log.info[`hdbHk]"Usage example: yak start batch.core_hdbHk -a \"-hdb HDB/DATA/PATH -hdbConn core.hdb [-date 2012.01.01] [-status EOD_MNG/DATA/PATH/hkStatus]\"";
  exit 0;
  ];


/------------------------------------------------------------------------------/
.sl.run[`hdbHk;`.sl.main;`];

if[not `noexit in `$.z.x;exit 0];


/------------------------------------------------------------------------------/
/
