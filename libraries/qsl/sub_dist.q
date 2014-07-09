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

/S/ Distribution subscription library:
/S/ - subscribe to in.dist for new updates
/S/ - initialize tables in memory in the configured namespace
/S/ - replay the data from journals
/S/ - results go into configured namespace
/S/ - only configured columns are kept in memory
/S/ - default callbacks 

/S/ Configuration is described in qsl/<dataflow.qsd> file, see "sub*" entries.

/S/ Initialization of the subscription:
/S/ If option <subAutoSubscribe> is set to TRUE, the library will initiate connection to dist server and subscription for the data.
/S/ Alternative option is prepared for users that would like to modify some parameters/actions before the journal replay
/S/ - configuration of subscription - e.g. different set of tables/sectors
/S/ - callback definition - e.g. to keep only subset of rows depending on custom logic
/S/ After modifications <.sub.init[.sub.cfg.subCfg]> should be invoked.

/A/ DEVnet: Pawel Hudak
/V/ 3.0

/------------------------------------------------------------------------------/
/                      dist subscription                                       /
/------------------------------------------------------------------------------/
/F/ Subscription to using tickLF interface
/P/ server - logical name of the server that was initialized by .hnd.hopen
/P/ tabs - list of table to be subscribed
/P/ uni - list of universe to subscribe
/E/ tabs:enlist `universe
/E/ server:`in.dist
/E/ uni:enlist `
.sub.dist.subscribe:{[server]
  .sub.info:.hnd.h[server](`.dist.subBatch;select tab, subType:`SECTOR, subActions:`ALL, subList from .sub.tabs); 
  .sub.srcCols: exec first cols each model by tab from .sub.info;
  select .d.init'[tab;model] from .sub.info;
  .sub.dist.replayTab each flip .sub.info`jrnDir`jrn`jrnI;
  };

/------------------------------------------------------------------------------/
/F/ Replay the data for one dist directory
/P/ subDetail - triple (directory with journals; last journal that should be replayed; number of messages that should be replayed from last journal)
.sub.dist.replayTab:{[subDetail]
  .event.at[`sub;`.Q.gc;();`;`info`info`error;"garbage collection"];
  .event.dot[`sub;`.sub.dist.replayDirData;subDetail;();`info`info`error;"replaying the data from journals from dist ",.Q.s1[subDetail]];
  };

/------------------------------------------------------------------------------/
/F/ Replay all dist journals from one directory.
/P/ jrnDir:SYMBOL - directory with journals
/P/ jrn:SYMBOL - name of the currently active journal
/P/ jrnI:INT - number of entries that should be replayed from the current journal
/E/ .sub.dist.replayData[(1;`:jrn)]
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
/G/ default realtime callbacks for dist
.sub.dist.default:()!();

/------------------------------------------------------------------------------/
/F/ Initialization of the table in memory
/P/ tab:SYMBOL - table name
/P/ model:TABLE - empty table - data model
.sub.dist.default[`.d.init]:{[tab;model] 
  s:.sub.tabs[tab]; 
  s[`name] set ?[model;s[`whr];s[`grp];s[`cnd]]
  };

//----------------------------------------------------------------------------//
/F/upd action
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ data:LIST - list containing columns with the update
.sub.dist.default[`.d.upd]:{[tab;sec;data] 
  s:.sub.tabs[tab]; 
  s[`name] insert ?[flip .sub.srcCols[tab]!data;s[`whr];s[`grp];s[`cnd]]
  };

//----------------------------------------------------------------------------//
/F/delete action
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ args:PAIR - pair with column name and list of values
/E/tab:`Account;args:(`bill_phone;enlist string `DHCCP`KOMFA`NCDMH`MUMXH)
.sub.dist.default[`.d.del]:{[tab;sector;args] 
  ![tab;enlist (in;args[0];args[1]);0b;`symbol$()]
  };

//----------------------------------------------------------------------------//
/F/upsert action, data grouped and inserted by first column
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ args:LIST - list containing columns with the update
.sub.dist.default[`.d.ups]:{[tab;sector;args] 
  name:.sub.tabs[tab;`name];
  name set 0!(1!value name) upsert 1!flip .sub.srcCols[tab]!args
  }; 

//----------------------------------------------------------------------------//
/F/eod action, by default simply cleaning tables from memory
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ date:DATE - eod date
.sub.dist.default[`.d.eod]:{[tab;sec;date] 
  delete from .sub.tabs[tab;`name] 
  };

//----------------------------------------------------------------------------//
/F/evaluates list of actions
/P/ actions:LIST - list of actions to be executed
.sub.dist.default[`.d.bundle]:{[actions] 
  value each actions
  };

/------------------------------------------------------------------------------/
/                      dist default journal callbacks                          /
/------------------------------------------------------------------------------/
/F/upd action
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ data:LIST - list containing columns with the update
/P/ ts:TIMESTAMP - timestamp of the original action
.sub.dist.default[`.j.upd]:{[tab;sec;data;ts] 
  .d.upd[tab;sec;data]
  }; 

//----------------------------------------------------------------------------//
/F/delete action
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ args:PAIR - pair with column name and list of values
/P/ ts:TIMESTAMP - timestamp of the original action
/E/tab:`Account;args:(`bill_phone;enlist string `DHCCP`KOMFA`NCDMH`MUMXH)
.sub.dist.default[`.j.del]:{[tab;sec;args;ts] 
  .d.del[tab;sec;args]
  }; 

//----------------------------------------------------------------------------//
/F/upsert action, data grouped and inserted by first column
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ args:LIST - list containing columns with the update
/P/ ts:TIMESTAMP - timestamp of the original action
.sub.dist.default[`.j.ups]:{[tab;sec;args;ts] 
  .d.ups[tab;sec;args]
  };

//----------------------------------------------------------------------------//
/F/eod action, by default simply cleaning tables from memory
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector
/P/ date:DATE - eod date
/P/ ts:TIMESTAMP - timestamp of the original action
.sub.dist.default[`.j.eod]:{[tab;sec;date;ts] 
  .d.eod[tab;sec;date]
  }; 

//----------------------------------------------------------------------------//
