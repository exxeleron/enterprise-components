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

/A/ DEVnet: Pawel Hudak
/V/ 3.0

/S/ Distribution subscription library:
/-/ - subscribe to in.dist for new updates
/-/ - initialize tables in memory in the configured namespace
/-/ - replay the data from journals
/-/ - results go into configured namespace
/-/ - only configured columns are kept in memory
/-/ - default callbacks 

/-/ Configuration is described in qsl/<dataflow.qsd> file, see "sub*" entries.

/-/ Initialization of the subscription:
/-/ If option <subAutoSubscribe> is set to TRUE, the library will initiate connection to dist server and subscription for the data.
/-/ Alternative option is prepared for users that would like to modify some parameters/actions before the journal replay
/-/ - configuration of subscription - e.g. different set of tables/sectors
/-/ - callback definition - e.g. to keep only subset of rows depending on custom logic
/-/ After modifications <.sub.init[.sub.cfg.subCfg]> should be invoked.

/A/ DEVnet: Pawel Hudak
/V/ 3.0

/------------------------------------------------------------------------------/
/                      dist subscription                                       /
/------------------------------------------------------------------------------/
/F/ Subscribes to dist-compatible server.
/P/ server:SYMBOL - logical name of the server that was initialized by .hnd.hopen
/R/ no return value
/E/ .sub.dist.subscribe `core.dist
.sub.dist.subscribe:{[server]
  .sub.info:.hnd.h[server](`.dist.subBatch;select tab, subType:`SECTOR, subActions:`ALL, subList from .sub.tabs); 
  .sub.srcCols: exec first cols each model by tab from .sub.info;
  select .d.init'[tab;model] from .sub.info;
  .sub.dist.replayTab each flip .sub.info`jrnDir`jrn`jrnI;
  };

/------------------------------------------------------------------------------/
/F/ Replays the data for one dist directory.
/P/ subDetail:TRIPLE - triple (directory with journals; last journal that should be replayed; number of messages that should be replayed from last journal)
/R/ no return value
/E/ .sub.dist.replayTab (`:journals/; 
.sub.dist.replayTab:{[subDetail]
  .log.debug[`sub] "Garbage collection";
  .pe.atLog[`sub;`.Q.gc;();`;`error];
  .event.dot[`sub;`.sub.dist.replayDirData;subDetail;();`info`info`error;"replaying the data from journals from dist ",.Q.s1[subDetail]];
  };

/------------------------------------------------------------------------------/
/F/ Replays all dist journals from one directory.
/P/ jrnDir:SYMBOL - directory with journals
/P/ jrn:SYMBOL    - name of the currently active journal
/P/ jrnI:INT      - number of entries that should be replayed from the current journal
/R/ no return value
/E/ .sub.dist.replayData[(100;`:jrn)]
/-/   - replay 100 first entries from `:jrn journal
.sub.dist.replayDirData:{[jrnDir;jrn;jrnI]
  .log.info[`sub] "Replaying journals from dir ",string[jrnDir], ". Last jrn will be :",string[jrn], " with ", string[jrnI], " messages";
  jrns:asc key jrnDir;
  fullReplay:` sv/: jrnDir,/:jrns til jrns?last` vs jrn;
  -11!/: fullReplay;
  -11! (jrnI;jrn);
  };

/------------------------------------------------------------------------------/
/                      dist default realtime callbacks                         /
/------------------------------------------------------------------------------/
/G/ Default realtime callbacks for dist.
.sub.dist.default:()!();

/------------------------------------------------------------------------------/
/F/ .d.init action default implementation - initialization of the table in memory.
/P/ tab:SYMBOL  - table name
/P/ model:TABLE - empty table - data model
.sub.dist.default[`.d.init]:{[tab;model] 
  s:.sub.tabs[tab]; 
  s[`name] set ?[model;s[`whr];s[`grp];s[`cnd]]
  };

//----------------------------------------------------------------------------//
/F/ .d.upd action default implementation - insertion of the data to global table in memory.
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ data:LIST - list containing columns with the update
.sub.dist.default[`.d.upd]:{[tab;sec;data] 
  s:.sub.tabs[tab]; 
  s[`name] insert ?[flip .sub.srcCols[tab]!data;s[`whr];s[`grp];s[`cnd]]
  };

//----------------------------------------------------------------------------//
/F/ .d.del action default implementation - deletion of the data from global table in memory.
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ args:PAIR - pair with column name and list of values
/E/tab:`Account;args:(`bill_phone;enlist string `DHCCP`KOMFA`NCDMH`MUMXH)
.sub.dist.default[`.d.del]:{[tab;sector;args] 
  ![tab;enlist (in;args[0];args[1]);0b;`symbol$()]
  };

//----------------------------------------------------------------------------//
/F/ .d.ups action default implementation - upsert of the data from global table in memory, data grouped and inserted by first column.
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ args:LIST - list containing columns with the update
.sub.dist.default[`.d.ups]:{[tab;sector;args] 
  name:.sub.tabs[tab;`name];
  name set 0!(1!value name) upsert 1!flip .sub.srcCols[tab]!args
  }; 

//----------------------------------------------------------------------------//
/F/ .d.eod action default implementation - simply cleaning tables from memory.
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ date:DATE - eod date
.sub.dist.default[`.d.eod]:{[tab;sec;date] 
  delete from .sub.tabs[tab;`name] 
  };

//----------------------------------------------------------------------------//
/F/ .d.bundle action default implementation - executes list of actions.
/P/ actions:LIST - list of actions to be executed
.sub.dist.default[`.d.bundle]:{[actions] 
  value each actions
  };

/------------------------------------------------------------------------------/
/                      dist default journal callbacks                          /
/------------------------------------------------------------------------------/
/F/ .j.upd action default implementation - insertion of the data to global table in memory.
/P/ tab:SYMBOL   - table name
/P/ sec:SYMBOL   - sector
/P/ data:LIST    - list containing columns with the update
/P/ ts:TIMESTAMP - timestamp of the original action
.sub.dist.default[`.j.upd]:{[tab;sec;data;ts] 
  .d.upd[tab;sec;data]
  }; 

//----------------------------------------------------------------------------//
/F/ .j.del action default implementation - deletion of the data from global table in memory.
/P/ tab:SYMBOL   - table name
/P/ sec:SYMBOL   - sector
/P/ args:PAIR    - pair with column name and list of values
/P/ ts:TIMESTAMP - timestamp of the original action
/E/tab:`Account;args:(`bill_phone;enlist string `DHCCP`KOMFA`NCDMH`MUMXH)
.sub.dist.default[`.j.del]:{[tab;sec;args;ts] 
  .d.del[tab;sec;args]
  }; 

//----------------------------------------------------------------------------//
/F/ .j.ups action default implementation - upsert of the data from global table in memory, data grouped and inserted by first column.
/P/ tab:SYMBOL   - table name
/P/ sec:SYMBOL   - sector
/P/ args:LIST    - list containing columns with the update
/P/ ts:TIMESTAMP - timestamp of the original action
.sub.dist.default[`.j.ups]:{[tab;sec;args;ts] 
  .d.ups[tab;sec;args]
  };

//----------------------------------------------------------------------------//
/F/ .j.eod action default implementation - simply cleaning tables from memory.
/P/ tab:SYMBOL   - table name
/P/ sec:SYMBOL   - sector
/P/ date:DATE    - eod date
/P/ ts:TIMESTAMP - timestamp of the original action
.sub.dist.default[`.j.eod]:{[tab;sec;date;ts] 
  .d.eod[tab;sec;date]
  }; 

//----------------------------------------------------------------------------//
