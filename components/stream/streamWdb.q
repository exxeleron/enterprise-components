/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/L/
/L/ Licensed under the Apache License, Version 2.0 (the "License");
/L/ you may not use this file except in compliance with the License.
/L/ You may obtain a copy of the License at
/L/
/L/   http://www.apache.org/licenses/LICENSE-2.0
/L/
/L/ Unless required by applicable law or agreed to in writing, software
/L/ distributed under the License is distributed on an "AS IS" BASIS,
/L/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/L/ See the License for the specific language governing permissions and
/L/ limitations under the License.

/A/ DEVnet: Pawel Hudak
/V/ 3.0

/S/ streamWdb (write rdb) stream plugin component:
/S/ streamWdb is meant to be low-memory alternative for rdb component; the difference when comparing to rdb is that in
/S/ streamWdb the data is partially kept in memory and partially splayed on disk.

/S/ Data flow description:
/S/ 1.0 Incoming data is placed in .cache namespace (standard stream component functionality)
/S/ 2.0 Data is dumped on disk in intervals specified via cfg.dataDumpInterval
/S/ 2.1 Data from .cache namespace is appended to today's splayed on-disk tables
/S/ 2.2 Splayed on-disk tables are reloaded into memory (into global namespace)
/S/ 2.3 Stream savepoint is written for the fallback procedure
/S/ 2.4 Data is deleted from .cache namepsace
/S/ 3.0 New incoming data is placed again in .cache namespace

/S/ Advantage of streamWdb:
/S/ There is only one advantage of streamWdb instead of rdb
/S/ - it is using less memory => therefore it should be used if there is not enough memory in the system to keep daily-worth of data in memory

/S/ Disadvantages of streamWdb:
/S/ There are several disadvantages of using streamWdb comparing to rdb
/S/  - data is split into on-disk and most recent in-memory:
/S/    *Consequence:* if query must take all data including records that arrived within last minutes 
/S/    it must be executed separately on on-disk data and in-memory data, the results should be merged afterwards
/S/  - as the data is periodically flushed from memory to disk:
/S/    *Consequence:* the process is busy at time of flushing thus not aviable for queries at that time
/S/  - on-disk splayed data is not sorted before eod (due to time required to perform this task):
/S/    *Consequence:* queries to on-disk data are noticeable slower than on in-memory data
/S/  - at end of day data must be sorted on disk:
/S/    *Consequence:* eod procedure is slightly longer than in case of rdb

.sl.lib["qsl/store"];
.sl.lib["qsl/os"];

//----------------------------------------------------------------------------//
/F/ Initialization callback invoked during process startup, before subscription
/F/ - reading configuration
/F/ - initialization of eod settings
/F/ - initialization and load of on-disk splayed tables
.stream.plug.init:{[]
  .wdb.cfg.tables:            .cr.getCfgPivot[`THIS;`table`sysTable;`hdbConn`performSort];
  hdbConns:(exec distinct hdbConn from .wdb.cfg.tables) except `;
  .wdb.cfg.tables:.wdb.cfg.tables lj ([hdbConn:hdbConns] eodPath:.cr.getCfgField[;`group;`dataPath]each hdbConns);
  
  .wdb.cfg.dataDumpInterval:  `long$.cr.getCfgField[`THIS;`group;`cfg.dataDumpInterval] * 60000000000; //convert to nanoseconds
  .wdb.cfg.fillMissingTabsHdb:.cr.getCfgField[`THIS;`group;`cfg.fillMissingTabsHdb];
  .wdb.cfg.reloadHdb:         .cr.getCfgField[`THIS;`group;`cfg.reloadHdb];
  .wdb.cfg.data:              .cr.getCfgField[`THIS;`group;`dataPath];
  .wdb.cfg.dataPath:          .cr.getCfgField[`THIS;`group;`dataPath];

  .wdb.lastDumpTs:0D00:00:00.000000;

  //end of day initialization
  if[1<>count paths:exec distinct eodPath from .wdb.cfg.tables;
    .log.error[`wdb]"only one hdb destination supported at the moment. Path ",string[paths 0], " will be used for all tables!"
    ];
  .wdb.cfg.dstHdb:paths 0;
  if[1<>count conns:exec distinct hdbConn from .wdb.cfg.tables;
    .log.error[`wdb]"only one hdb destination supported at the moment. Connection ",string[conns 0], " will be used for all tables!"
    ];
  .wdb.cfg.dstHdbConn:conns 0;
  .wdb.cfg.dstHdbConn:exec first hdbConn from .wdb.cfg.tables;
  system .os.slash "cd ",1_string[.wdb.cfg.data],"/tmpdb/";

  //end of day initialization
  eodTabs:select table:tab, hdbPath:eodPath, hdbName:hdbConn, memoryClear:0b, store:1b from (select from .stream.cfg.srcTab where subType=`tickLF)lj `tab xcol .wdb.cfg.tables;
  .store.init[eodTabs;.wdb.cfg.reloadHdb;.wdb.cfg.fillMissingTabsHdb;.wdb.cfg.dataPath];

  .store.notifyStoreBefore[.stream.date];

  .wdb.p.initWdb .sl.eodSyncedDate[];
  };


//----------------------------------------------------------------------------//
/F/ subscription callback, no action in case of streamWdb
/P/ serverSrc:SYMBOL - name of the data source server
/P/ schema:LIST(NAME;TABLE) - list containing table names and the data model for them.
/P/ savepointData:ANY - savepoint data stored using .stream.savepoint[].stream.savepoint
.stream.plug.sub:{[serverSrc;schema;savepointData]
  .wdb.lastDumpTs:0D00:00:00.000000;
  if[not savepointData~(::);
    //initialize using savepointData
    ];
  };

//----------------------------------------------------------------------------//
/F/ timer callback; after cfg.dataDumpInterval passed following actions are performed
/F/ - data is stored to splayed on-disk tables
/F/ - splayed on-disk tables are loaded into memory (mmap)
/F/ - savepoint is written
/P/ tm:TIMESTAMP - current timestamp
.stream.plug.ts:{[tm]
  if[tm >.wdb.lastDumpTs + .wdb.cfg.dataDumpInterval;
    .log.debug[`wdb] "savepoint: flushing data to disk";
    .wdb.lastDumpTs:"n"$tm;

    //dump current state
    .wdb.p.store each exec tab from .stream.cfg.srcTab where subType=`tickHF;
    .event.at[`wdb;`.wdb.p.reloadLocalSplayedTabs;`;`;`info`info`error;"reload local splayed tables"];
    .stream.savepoint[.wdb.lastDumpTs];
    ];
  };

//----------------------------------------------------------------------------//
/F/ end of day callback
/F/ - store all splayed tables in the destination hdb
/F/ - trigger reload of local splayed tables
/F/ - execute garbage collection
/P/ day:DATE - day that has just ended
//day:.z.d
.stream.plug.eod:{[day]
  .event.at[`wdb;`.wdb.p.eodStore;day;`;`info`info`error;"store all splayed tables in the destination hdb"];
  .event.at[`wdb;`.wdb.p.reloadLocalSplayedTabs;`;`;`info`info`error;"reload local splayed tables"];
  .event.at[`wdb;`.Q.gc;();`;`info`info`error;"garbage collection"];
  };

//----------------------------------------------------------------------------//
//                         helper functions                                   //
//----------------------------------------------------------------------------//
//day:.z.d
.wdb.p.initWdb:{[day]
  .wdb.p.initWdbTab[day]each exec tab from .stream.cfg.srcTab where subType=`tickHF;
  .event.at[`wdb;`.wdb.p.reloadLocalSplayedTabs;`;`;`info`info`error;"reload local splayed tables"];
  };

//----------------------------------------------------------------------------//
//table:`trade
.wdb.p.reloadLocalSplayedTabs:{[]
  system"l .";
  if[not date~enlist[.z.d];
    .log.warn[`wdb] "Local partitioned db(",system["cd"],") should contain only partition for today(",string[.z.d],"). It contains ", .Q.s1[date],".";
    ];
  };

//----------------------------------------------------------------------------//
//table:`trade
.wdb.p.initWdbTab:{[day;table]
  path:` sv `:.,(`$string day),table,`;
  if[()~key path;
    .[path;();:;.Q.en[.wdb.cfg.dstHdb] value .stream.cacheNames table]; 
    ];
  };

//----------------------------------------------------------------------------//
//table:`trade
.wdb.p.store:{[table]
  .[` sv `:.,(`$string .stream.date),table,`;();,;.Q.en[.wdb.cfg.dstHdb] value .stream.cacheNames table]; 
  delete from .stream.cacheNames table;
  };

//----------------------------------------------------------------------------//
.wdb.p.eodStore:{[day]
  .store.notifyStoreBegin[day];
  status1:.wdb.p.eod[day];
  status2:.store.storeAll[day;.store.tabs];
  $[(`error in status1)or(`error in status2);.store.notifyStoreRecovery[day];.store.notifyStoreSuccess[day]];
  .store.notifyStoreBefore[day+1];
  };

//----------------------------------------------------------------------------//
.wdb.p.eod:{[day]
  status:(::);
  {[t]delete from .stream.cacheNames[t]} each exec tab from .stream.cfg.srcTab where subType=`tickHF;
  //disksort new partition
  status:status,{[day;x].event.dot[`wdb;`.wdb.p.sortTab;(day;x);`error;`info`info`error;"Sorting wdb partition for table ", string x]}[day] each exec tab from .stream.cfg.srcTab where subType=`tickHF, tab in exec sectionVal from .wdb.cfg.tables where performSort;
  //switch tmp hdb to new date
  status:status,.event.at[`wdb;`.wdb.p.initWdb;day+1;`error;`info`info`error;"Creating new wdb partition dir"];
  .wdb.lastDumpTs:00:00:00.000000;
  //move the completed day to the real hdb
  args:(.wdb.cfg.dstHdb;day),/:exec tab from .stream.cfg.srcTab where subType=`tickHF;
  status:status,.event.dot[`wdb;`.wdb.p.mv;;`error;`info`info`error;"Moving data for day ",string[day]] each args;
  .os.rmdir string day;
  if[.wdb.cfg.fillMissingTabsHdb;
    status:status,.event.at[`wdb;`.store.fillMissingTabs;.wdb.cfg.dstHdb;`error;`info`info`error;"Fill missing tabs in hdb: ",string[.wdb.cfg.dstHdb]];
    ];
  if[.wdb.cfg.reloadHdb;
    .event.at[`wdb;`.store.reloadHdb;.wdb.cfg.dstHdbConn;`error;`info`info`error;"Reload hdb: ",string[.wdb.cfg.dstHdbConn]];
    ];
  status
  };

//----------------------------------------------------------------------------//
.wdb.p.disksort:{[t;c;a] 
  if[not`s~attr(t:hsym t)c;
    if[count t;
      ii:iasc iasc flip c!t c,:();
      if[not$[(0,-1+count ii)~(first;last)@\:ii;@[{`s#x;1b};ii;0b];0b];
        {v:get y;if[not$[all(fv:first v)~/:256#v;all fv~/:v;0b];v[x]:v;y set v];}[ii]each` sv't,'get` sv t,`.d]
      ];
    @[t;first c;a]];t
  };

//----------------------------------------------------------------------------//
.wdb.p.sortTab:{[day;table]
  / sort on disk by sym and set `p#
  .wdb.p.disksort[` sv `:.,(`$string day),table,`;`sym;`p#];
  };

//----------------------------------------------------------------------------//
//dst:.wdb.cfg.dstHdb;tab:`trade;day:.z.d
.wdb.p.mv:{[dst;day;tab]
  dstTab:(1_string[dst]),"/",string[day],"/",string[tab],"/";
  dstMissing:()~key hsym`$dstTab;
  if[dstMissing; //create empty dir
    (tmp:hsym `$dstTab,".tmp") set `tmp;
    hdel tmp;
    ];
  dstCnt:$[dstMissing;0;count select from hsym `$dstTab];
  if[0<>dstCnt; 'dstTab, " contains already ",string[dstCnt], " rows of data"];
  .os.move[string[day],"/",string[tab],"/*";dstTab];
  .os.move[string[day],"/",string[tab],"/.d";dstTab];
  };

//----------------------------------------------------------------------------//
.stream.initMode[`cache];
