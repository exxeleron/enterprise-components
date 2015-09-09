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

/A/ DEVnet: Joanna Jarmulska, Pawel Hudak
/V/ 3.0

/S/ hdbWriter - writing data to the hdb.
/S/ see detailed description in the hdbWriter/README.md file

/------------------------------------------------------------------------------/
/                                 libraries                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";

.sl.init[`hdbWriter];
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/store"];
.sl.lib["qsl/os"];
.sl.lib["qsl/tabs"];

//----------------------------------------------------------------------------//
//                              initialization                                //
//----------------------------------------------------------------------------//
/S/ Initialzation of the hdbWriter, invoked in the .sl.main[]
/S/ - open connection to dstHdb
/S/ - initialize and load tmpHdb
.hdbw.init:{[]
  .hnd.hopen[.hdbw.cfg.dstHdb;100i;`lazy];

  //load hdbw tmp-hdb
  .os.mkdir[.hdbw.cfg.tmpHdbPath];
  system"l ",1_string .hdbw.cfg.tmpHdbPath;
  };

//----------------------------------------------------------------------------//
//                         insert to tmpHdb                                   //
//----------------------------------------------------------------------------//
/F/ Uploading the data to the tmpHdb.
/F/ - data is stored to splayed on-disk tables in tmpHdb
/F/ - splayed on-disk tables are loaded into memory (mmap)
/P/ tabName:SYMBOL - table name
/P/ data:TABLE - table with the data model matching to the data model of table, it should also contain date column
/P/      alternatively list of columns
.hdbw.insert:{[tabName;data]
  .log.info[`hdbw]"Inserting ",string[count data]," rows for table ", string[tabName];
  if[not -11h=type tabName;
    '"invalid tabName type (",.Q.s1[type tabName],"), should be SYMBOL type (-11h)";
    ];
  if[not tabName in .hdbw.cfg.cfgModel[`tab];
    '"unknown tabName ",.Q.s1[tabName],", should be one of ", .Q.s1[.hdbw.cfg.cfgModel[`tab]];
    ];
  if[not type[data] in 0 98h;
    '"invalid data type (",.Q.s1[type data],"), should be TABLE type (98h) or LIST (0h)";
    ];
  expMeta:.hdbw.cfg.expMeta[tabName];
  data:.tabs.validate[expMeta;data];

  // for performance reasons once for the entire data set
  .log.info[`hdbw]"Enumerating records using dstHdb sym location:", .Q.s1[.hdbw.cfg.dstHdbPath];
  data:.Q.en[.hdbw.cfg.dstHdbPath;data];  

  .hdbw.p.store[tabName;data;] each exec distinct date from data;

  .hdbw.p.reloadTmpHdb[];
  };

//----------------------------------------------------------------------------//
/S/ On-disk insert data for one tab/day to the tmpHdb
/P/ tabName:SYMBOL - table name
/P/ data:TABLE - data in the table format that should be written to tmpHdb
/P/ day:SYMBOL - partition name
//tabName:`trade;day:2014.01.01;.hdbw.cfg.tmpHdbPath:`:.
.hdbw.p.store:{[tabName;data;day]
  // generate the write path
  writePath:.Q.par[.hdbw.cfg.tmpHdbPath;day;`$string[tabName],"/"];

  .hdbw.p.initPartition[writePath;tabName;day];

  // sub-select the data to write
  dataPart:delete date from select from data where date=day;

  .log.info[`hdbw] "Inserting to:`",string[writePath], " for day:",string[day], ", table:`",string[tabName], " #rows:", string[count dataPart];
   
  // splay the table - use an error trap
  .pe.dotLog[`hdbw;`.q.upsert;(writePath;dataPart);`er;`error];
  };

/------------------------------------------------------------------------------/
/F/ Initialization of the partition in the tmpHdb
/F/ Performs copy from the dstHdb if required
/P/ writePath:SYMBOL - full path of the table partition in the tmpHdb
/P/ tabName:SYMBOL - table name
/P/ day:SYMBOL - partition name
.hdbw.p.initPartition:{[writePath;tabName;day]
  //if writePath does not exist or is empty => initiate it
  if[0 = count key writePath;
    .os.mkdir[writePath];
    //always initialize with empty entry to be consistent with possible prior initialization by .Q.chk[]
    .[writePath;();:;.Q.en[.hdbw.cfg.dstHdbPath] .hdbw.cfg.model tabName]; 
    ];   

  // if writePath table is contais 0 rows
  if[0 = count select from writePath;
    dstPath:.Q.par[.hdbw.cfg.dstHdbPath;day;`$string[tabName],"/"];
    // if dstPath contains anything (assuming data, if not empty model) => copy it
    if[count key dstPath;
      .os.cpdir[dstPath;writePath];
      ];
    ];
  };

//----------------------------------------------------------------------------//
//                            organize tmpHdb                                 //
//----------------------------------------------------------------------------//
/F/ Organize the data in tmpHdb - sort and validate the data.
/F/ Must be performed before pushing the data to dstHdb (.hdbw.finalize[]).
/P/ tabls:LIST SYMBOL - list of tables, or `ALL to take all tables that were inserted so far
/P/ partitions:LIST SYMBOL - list of partitions, or `ALL to take all partitions that were inserted so far
//.hdbw.organize[`ALL;`ALL]
.hdbw.organize:{[tabs;partitions]
  toMove:.hdbw.p.list[tabs;partitions];
  //disksort new partitions
  {[part].event.dot[`hdbw;`.hdbw.p.sortTab;(part`date;part`tab);`error;`info`info`error;"Sorting tmpHdb partition for day=",string[part`date],", table=", string[part`tab]]} each toMove;
  };

//----------------------------------------------------------------------------//
/F/ Create listing of partition/table
/P/ tabls:LIST SYMBOL - list of tables, or `ALL to take all tables that were inserted so far
/P/ partitions:LIST SYMBOL - list of partitions, or `ALL to take all partitions that were inserted so far
/R/ TABLE - listing of all partition/table pairs
.hdbw.p.list:{[tabs;partitions]
  if[tabs~`ALL;tabs:tables[]];
  if[0=count tabs;:([]date:`symbol$();tab:`symbol$(); cnt:`long$())];
  tabs:.hdbw.cfg.cfgModel[`tab] inter tabs;

  if[partitions~`ALL;partitions:date];
  partitions:partitions inter date;
  list:raze {[days;tab] 0!select tab, cnt:count i by date from tab where date in days}[partitions] each tabs;
  list
  };

//----------------------------------------------------------------------------//
/F/ Sort one table partition on disk
/P/ day:SYMBOL - partition name
/P/ tabName:TABLE - table name
.hdbw.p.sortTab:{[day;tabName]
  / sort on disk by sym and set `p#
  dstPath:.Q.par[.hdbw.cfg.tmpHdbPath;day;`$string[tabName],"/"];
  .hdbw.p.disksort[dstPath;.hdbw.cfg.hdbSortingCols[tabName];`p#];
  };

//----------------------------------------------------------------------------//
/F/ Sort one table partition on disk
/P/ t:SYMBOL - Full path to the table on disk
/P/ c:SYMBOL - column which should be used for sorting
/P/ a:FUNCTION - attribute which should be applied on the sorted column
.hdbw.p.disksort:{[t;c;a] 
  if[not`s~attr(t:hsym t)c;
    if[count t;
      ii:iasc iasc flip c!t c,:();
      if[not$[(0,-1+count ii)~(first;last)@\:ii;@[{`s#x;1b};ii;0b];0b];
        {v:get y;if[not$[all(fv:first v)~/:256#v;all fv~/:v;0b];v[x]:v;y set v];}[ii]each` sv't,'get` sv t,`.d]
      ];
    @[t;first c;a]];t
  };

//----------------------------------------------------------------------------//
//                            finalize                                        //
//----------------------------------------------------------------------------//
/F/ Deploy the data in the dstHdb. Note that .hdbw.organize[] must be used 
/F/ before the finalization.
/F/ - validate each (table/partition)
/F/ - archive - move dstHdb/partition/table to archive/{timestmap}/partition/table
/F/ - move tmpHdb/partition/table to dstHdb/partition/table
/F/ - fill missing days in dstHdb
/F/ - reload dstHdb process
/P/ tabls:LIST SYMBOL - list of tables, or `ALL to take all tables that were inserted so far
/P/ partitions:LIST SYMBOL - list of partitions, or `ALL to take all partitions that were inserted so far
.hdbw.finalize:{[tabs;partitions]
  toMove:.hdbw.p.list[tabs;partitions];

  if[not all exec .hdbw.p.checkAttr'[date;tab] from toMove;
    '"not all tmpHdb partitions are sorted, make sure to call .hdbw.organize[] before using .hdbw.finalize[]"
    ];

  currentArchivePath:`$string[.hdbw.cfg.archivePath],(ssr[;":";"."]string[.z.p]),"/";
  .os.mkdir currentArchivePath;

  //move the completed day to the real hdb
  .hdbw.p.deployOne[currentArchivePath] each toMove;

  .hnd.h[.hdbw.cfg.dstHdb]".hdb.fillMissingTabs[]";
  .hnd.h[.hdbw.cfg.dstHdb]".hdb.reload[]";

  //refresh state of the tmpHdb in memory
  .hdbw.p.cleanupTmpHdb[];
  };

//----------------------------------------------------------------------------//
/F/ Push one partition/table from tmpHdb to dstHdb
/P/ currentArchivePath:SYMBOL - archive directory path
/P/ item:DICT - info about partition
.hdbw.p.deployOne:{[currentArchivePath;item]
  srcPath:.Q.par[.hdbw.cfg.tmpHdbPath;item`date;item`tab];
  srcDirPath:.Q.par[.hdbw.cfg.tmpHdbPath;item`date;`];

  archivePath:.Q.par[currentArchivePath;item`date;item`tab];
  archiveDirPath:.Q.par[currentArchivePath;item`date;`];

  dstPath:.Q.par[.hdbw.cfg.dstHdbPath;item`date;item`tab];
  dstDirPath:.Q.par[.hdbw.cfg.dstHdbPath;item`date;`];

  if[not ()~key dstPath; //if there is actually anything to backup
    .log.info[`hdbw] "Archiving ", string[dstPath], " in ", string[archivePath];
    .os.mkdir[archiveDirPath];
    .os.move[dstPath;archivePath];
    ];
  .log.info[`hdbw] "Deploying ", string[srcPath], " in ", string[dstPath];
  .os.mkdir[dstDirPath];
  .os.move[srcPath;dstPath];
  //if partition is empty or all tables in it are empty - remove entire partition
  if[all 0={count select from x} each ` sv/: srcDirPath,/:key srcDirPath;
    .os.rmdir srcDirPath;
    ];
  };

//----------------------------------------------------------------------------//
/F/ Check whether table in tmpHdb contains `p attribute
/P/ date:DATE - date which should be checked
/P/ tab:TABLE - table name
.hdbw.p.checkAttr:{[date;tab] 
  `p in exec a from meta select from .Q.par[.hdbw.cfg.tmpHdbPath;date;tab]
  };

//----------------------------------------------------------------------------//
/F/ Cleanup mmap of tmpHdb directory (as some of the mmaped files/direcotires
/F/ does not exist on disk anymore).
/F/ Reload the tmpHdb
.hdbw.p.cleanupTmpHdb:{[] 
  {value"delete ",string[x]," from `."} each tables[];
  system"l .";
  };

//----------------------------------------------------------------------------//
//                         initialization                                     //
//----------------------------------------------------------------------------//
/F/ Fill missing days and reload the tmpHdb.
.hdbw.p.reloadTmpHdb:{[]
  .log.info[`hdbw]"Reloading tmpHdb: ", system"cd";
  .Q.chk[`:.];
  system"l .";
  };

//----------------------------------------------------------------------------//
/F/ Starting point of the hdbWriter.
.sl.main:{[]
  .hdbw.cfg.dstHdb:.cr.getCfgField[`THIS;`group;`cfg.dstHdb];
  .hdbw.cfg.dstHdbPath:.cr.getCfgField[.hdbw.cfg.dstHdb;`group;`dataPath];
  .hdbw.cfg.tmpHdbPath:.cr.getCfgField[`THIS;`group;`cfg.tmpHdbPath];
  .hdbw.cfg.archivePath:.cr.getCfgField[`THIS;`group;`cfg.archivePath];
  .hdbw.cfg.model:(!) . flip .cr.getModel[`THIS];  //TODO FUTURE: consolidate with cfgModel
  .hdbw.cfg.cfgModel:select tab:sectionVal, model:finalValue from .cr.getCfgTab[`THIS;`table;`model];
  .hdbw.cfg.expMeta:exec tab!{(enlist[`date]!enlist["d"]), exec col1!.tabs.cfg.typeMap col2 from x} each model from .hdbw.cfg.cfgModel;
  .hdbw.cfg.hdbSortingCols:exec sectionVal!hdbSortingCols from .cr.getCfgPivot[`THIS;`table;`hdbSortingCols];
  .sl.libCmd[];
  .hdbw.init[];
  };

//----------------------------------------------------------------------------//
.sl.run[`hdbw;`.sl.main;`];
/
\a
raze {meta x} each value each tables[]
meta deltas
sym:`symbol$()
.hdbw.organize[`ALL;`ALL]
.tabs.status[]
.hdbw.finalize[`instrumentStateChange;`ALL]
meta instrumentStateChange
meta select from deltas
deltas
select from instrumentStateChange