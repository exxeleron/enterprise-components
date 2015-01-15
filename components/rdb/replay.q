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

/A/ DEVnet: Joanna Jarmulska
/V/ 3.0

/S/ Replay tool:
/S/ Responsible for:
/S/ - restoring historical data from journal files through batch process
/S/ - replaying data from tickHF and tickLF journals according to the dataflow configuration for given rdb process and date
/S/ - executing before end-of-day plugins that are defined for given rdb
/S/ - storing replayed data in hdb and reloading hdb

/T/ Replay process should be added to the system.cfg
/T/ (start code)
/T/   [[batch.admin_replay]]
/T/       u_file = NULL
/T/       u_opt = NULL
/T/       type = q:rdb/replays
/T/       port = 0
/T/       command = "q replay.q"
/T/ (end)
/T/ Afterwards, in case of end-of-day failure it can be started manually with with command line parameters
/T/ date - date for which data should be recover
/T/ rdb  - name of the rdb process for which configuration and plugins should be used for data recovery
/T/ *yak start batch.admin_replay -a "-date 2012.08.07 -rdb core.rdb"*

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`replay];
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/sub"];
.sl.lib["qsl/store"];

/------------------------------------------------------------------------------/
//.replay.cfg.date:.z.d-1;
//.replay.cfg.rdb:`core.rdb;
// cfg:.replay.cfg
.replay.p.run:{[cfg]
  rdb:cfg[`rdb];
  date:cfg[`date];
  .log.info[`replay]"Start data replay for date ",string[date], " and rdb ", string rdb;
  // get src servers, get tables
  .replay.cfg.tables:.cr.getCfgPivot[rdb;`table`sysTable;`subSrc`hdbConn`eodClear`eodPerform];
  .replay.cfg.tables:update eodPath:.cr.getCfgField[;`group;`dataPath]'[hdbConn] from .replay.cfg.tables;
  .replay.cfg.fillMissingTabsHdb: .cr.getCfgField[rdb;`group;`cfg.fillMissingTabsHdb];
  .replay.cfg.reloadHdb:          .cr.getCfgField[rdb;`group;`cfg.reloadHdb];
  .replay.cfg.opt:                .cr.getCfgField[rdb;`group;`libs];
  .replay.cfg.dataPath:           .cr.getCfgField[`THIS;`group;`dataPath];

  repTabs:exec subSrc!sectionVal from select sectionVal by subSrc from .replay.cfg.tables where subSrc<>`; 
  processTypes:key[repTabs]!.cr.getCfgField[;`group;`type] each key repTabs;
  if[any w:0b in/: processTypes in `$("q:tickLF/tickLF";"q:tickHF/tickHF");
    .log.warn[`replay]"Tables from process/processType will not be replayed: ", .Q.s1[flip (where w;processTypes[where w];repTabs[where w])];
    /exclude from repTabs and processTypes
    repTabs:(where w) _ repTabs;
    processTypes:(where w) _ processTypes;
    ];
  jrns:()!();
  if[count processLF:where processTypes in `$("q:tickLF/tickLF");
    jrns[processLF]:.replay.p.findJournaLF[date;;]'[processLF;repTabs[processLF]];
    ];
  if[count processHF:where processTypes in `$("q:tickHF/tickHF");
    jrns[processHF]:.replay.p.findJournaHF[date;;]'[processHF;repTabs[processHF]];
    ];
  // replay journals except ()
  jrnsOk:jrns processModel:where 0<count'[jrns];
  modelsAll:.cr.getModel each processModel;
  .replay.p.restoreData'[jrnsOk;modelsAll];
  .replay.p.initEodParams[];
  // load custom lib
  .rdb.plug.beforeEod:()!();
  .rdb.plug.afterEod:()!();
  if[not .replay.cfg.opt~enlist `;
    .sl.lib each .replay.cfg.opt;
    ];
  // run eod         
  .replay.p.eodAct[`beforeEod;;date] each key .rdb.plug.beforeEod;
  .store.run[date];
  .log.info[`replay]"Completed";
  };

/------------------------------------------------------------------------------/
/ eod
/------------------------------------------------------------------------------/
.replay.p.initEodParams:{[]
  eodTabs:select table:sectionVal, hdbPath:eodPath, hdbName:hdbConn, memoryClear:eodClear, store:eodPerform from .replay.cfg.tables;
  .store.init[eodTabs;.replay.cfg.reloadHdb;.replay.cfg.fillMissingTabsHdb;.replay.cfg.dataPath];
  hdb2conn:exec distinct hdbConn from .replay.cfg.tables where not hdbConn~'`;
  if[count hdb2conn;
    .hnd.hopen[hdb2conn;100i;`lazy];
    ];
  };

/------------------------------------------------------------------------------/
.replay.p.eodAct:{[act;tab;date]
  funcName:` sv`.rdb.plug,act,tab;
  .event.at[`replay;funcName;date;();`info`info`error;"Perform ",string[act] ," for table ",string tab];
  };

/------------------------------------------------------------------------------/
/ restore data from journal
/------------------------------------------------------------------------------/
//jrns:jrnsOk 0
//models:modelsAll 0
.replay.p.restoreData:{[jrns;models]
  .log.info[`replay]"Set data model for tables ",.Q.s1[tabs:models[;0]];
  (set) ./:models;
  @[;`sym;`g#] each tabs;
  .replay.tabs:tabs;
  {[x] .event.at[`replay;`.replay.p.replay;x;();`info`info`error;"Replay data from journal ",string[x]]} each jrns;
  };

/------------------------------------------------------------------------------/
.replay.p.replay:{[jrn]
  -11!jrn;
  .Q.gc[];
  };

/------------------------------------------------------------------------------/
//date:.z.d
//process:`t.tickLF
//tabs:repTabs[process]
.replay.p.findJournaLF:{[date;process;tabs]
  jrnDir:.cr.getCfgField[process;`group;`dataPath];
  jrns:files@'where each (files:key each ` sv/: jrnDir,/: tabs) like' "*.",/:string tabs;
  jrnsFound:.replay.p.matchJrnWithDate[;;date]'[jrns;tabs];
  posFound:where not jrnsFound=`;
  jrns2rep:` sv/:jrnDir,/:tabs[posFound],'jrnsFound[posFound];
  .log.debug[`replay ]"Journals for process was found:",.Q.s1[(process;jrns2rep)];
  :jrns2rep;
  };

/------------------------------------------------------------------------------/
//process:`ofp.tickHF
//tabs:repTabs[process]
.replay.p.findJournaHF:{[date;process;tabs]
  jrnDir:.cr.getCfgField[process;`group;`dataPath];
  jrnsFound:files where (files:key jrnDir)  like string[process],string[date];
  if[not count jrnsFound;
    .log.warn[`replay]"Journal that matches date ", string[date] ," and process ",string[process], " couldn't be found";
    :();
    ];
  jrns2rep:` sv/:jrnDir,/:jrnsFound;
  .log.debug[`replay ]"Journals for process was found:",.Q.s1[(process;jrns2rep)];
  :jrns2rep;
  };

/------------------------------------------------------------------------------/
//date:.z.d
//jrns:jrns 0
//table:tabs 0    
//jrns:jrns 2
//table:tabs 2    
.replay.p.matchJrnWithDate:{[jrns;table;date]
  position:("D"$10#/:string jrns) bin date;
  if[-1~position; 
    .log.warn[`replay]"Journal that matches date ", string[date] ," and table ",string[table], " couldn't be found";
    :`;
    ];
  :jrns[position];
  };

/------------------------------------------------------------------------------/  
/F/ function for executing callbacks from tickHF journal; data from journal is processed as inserts
jUpd:{[t;d]
  if[t in .replay.tabs;
    t insert d;
    ];
  };


/==============================================================================/
.sl.main:{[flags]
  .cr.loadCfg[`ALL];
  .replay.cfg.params:.Q.opt[.z.x];
  .replay.cfg.date:"D"$first .replay.cfg.params`date;
  .replay.cfg.rdb:`$first .replay.cfg.params`rdb;
  usageExample: "Usage example: yak start batch.replay -a \"-date 2012.01.01 -rdb core.rdb\"";
  if[not `date in key  .replay.cfg.params;
    '"Missing -date parameter. ", usageExample;
    ];
  if[not `rdb in key  .replay.cfg.params;
    '"Missing -rdb parameter. ", usageExample;
    ];
  
  .sl.libCmd[];
  .sub.initCallbacks[`PROTOCOL_TICKLF];
  .replay.p.run[.replay.cfg];
  };

/------------------------------------------------------------------------------/

//initialization

.sl.run[`replay;`.sl.main;`];



/------------------------------------------------------------------------------/

\
tables[]!count'[value each tables[]]

.Q.gc[]

