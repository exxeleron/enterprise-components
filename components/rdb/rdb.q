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

/A/ DEVnet: Rafal Sytek, Bartosz Kaliszuk, Joanna Jarmulska
/V/ 3.0
/T/ q rdb.q 

/S/ Real time database component:
/-/ Responsible for:
/-/ - handling functionality of real time database
/-/ - configuration of subscription and End-Of-Day process
/-/ - performing auto re-subscription and auto re-connection mechanism to Tickerplant
/-/ - automatic journal replaying at startup
/-/
/-/ Subscription tables:
/-/ To add new tables for subscription, add them to dataflow.cfg configuration file.
/-/
/-/ End-Of-Day tables:
/-/ To add new tables for End-Of-Day processing, add them to dataflow.cfg configuration file.
/-/ Note that for End-Of-Day procedure there is need to setup only logical name of the hdb. Path to hdb location is taken automatically from the system.cfg (field: dataPath) for given hdb name
/-/
/-/ Plugins:
/-/ List of plugins to setup:
/-/ - dictionary of functions invoked before eod execution
/-/ (start code)
/-/ .rdb.plug.beforeEod[name of the plugin:SYMBOL][date:DATE]
/-/ .rdb.plug.beforeEod[`createOhlc]:{[date] `ohlc set select open:price, high:price, low:price, close:price by sym from trade}
/-/ (end)
/-/ - dictionary of functions invoked after eod execution
/-/ (start code)
/-/ .rdb.plug.afterEod[name of the plugin:SYMBOL][date:DATE]
/-/ .rdb.plug.afterEod[`createMrvs]:{[date] `mrvs insert select by sym from trade}
/-/ (end)
/------------------------------------------------------------------------------/
/                               lib and etc                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`rdb];

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/handle"];
.sl.lib["qsl/sub"];
.sl.lib["qsl/store"];

/------------------------------------------------------------------------------/
/G/ Dictionary with plugins executed just before the eod procedure.
/E/ .rdb.plug.beforeEod[`createOhlc]:{[date] `ohlc set select open:price, high:price, low:price, close:price by sym from trade}
.rdb.plug.beforeEod:()!();

/G/ Dictionary with plugins executed just after the eod procedure.
/E/ .rdb.plug.afterEod[`createMrvs]:{[date] `mrvs insert select by sym from trade}
.rdb.plug.afterEod:()!();

/------------------------------------------------------------------------------/
/                              interface functions                             /
/------------------------------------------------------------------------------/
/F/ End-Of-Day (eod) callback from subscribed tickHF server (e.g.: tickHF).
/-/  .u.end[] can be used to manually trigger eod procedure.
/P/ date:DATE - eod date (in most cases current date)
/R/ no return value
/E/ .u.end[.z.d]
.u.end:{[date]
  if[date<.rdb.date;
    .log.info[`rdb] "Eod proccess was called already. Further eod activities won't be performed";
    :();
    ];
  .rdb.date+:1;
  .rdb.p.eodAct[`beforeEod;;date] each key .rdb.plug.beforeEod;
  .store.run[date];
  .rdb.p.eodAct[`afterEod;;date] each key .rdb.plug.afterEod;
  };

/------------------------------------------------------------------------------/
/F/ Executes eod plugins.
/P/ act:SYMBOL - action, can be before, after eod
/P/ tab:SYMBOL - table name
/P/ date:DATE  - current date
/R/ no return value
/E/ .rdb.p.eodAct[`beforeEod;`ohlc;2012.01.01]
.rdb.p.eodAct:{[act;tab;date]
  funcName:` sv`.rdb.plug,act,tab;
  .event.at[`rdb;funcName;date;();`info`info`error;"Perform ",string[act] ," for table ",string tab];
  };

/------------------------------------------------------------------------------/
/F/ Initializes the rdb component.
/R/ no return value
/E/ .rdb.p.init[]
.rdb.p.init:{[]
  /G/ Current date, based on .sl.eodSyncedDate[] on init, updated using date passed via .u.end[].
  /-/  Used in .u.end[] to avoid exeuction of the eod twice for the same day.
  .rdb.date:.sl.eodSyncedDate[];

  //end of day
  eodTabs:select table:sectionVal, hdbPath:eodPath, hdbName:hdbConn, memoryClear:eodClear, store:eodPerform from .rdb.cfg.eodTabs;
  .event.dot[`rdb;`.store.init;(eodTabs;.rdb.cfg.reloadHdb;.rdb.cfg.fillMissingTabsHdb;.rdb.cfg.dataPath);();`debug`info`error;"initializing store library"];

  //connections
  hdb2conn:exec distinct hdbConn from .rdb.cfg.eodTabs where not hdbConn~'`;
  if[count hdb2conn;
    .hnd.hopen[hdb2conn;.rdb.cfg.timeout;`lazy];
    ];
  };

/==============================================================================/
/F/ Main function for the rdb component.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main `
.sl.main:{[flags]
  /G/ Table with eod configuration per table, loaded from dataflow.cfg.
  /-/  -- sectionVal:SYMBOL  - table name
  /-/  -- hdbConn:SYMBOL     - hdb process name
  /-/  -- eodClear:BOOLEAN   - true if the table should be cleared after eod
  /-/  -- eodPerform:BOOLEAN - true if the table should stored in hdb during eod
  /-/  -- eodPath:SYMBOL     - full path to the hdb directory
  .rdb.cfg.eodTabs:             .cr.getCfgPivot[`THIS;`table`sysTable;`hdbConn`eodClear`eodPerform];
  hdbConns:(exec distinct hdbConn from .rdb.cfg.eodTabs) except `;
  .rdb.cfg.eodTabs:.rdb.cfg.eodTabs lj ([hdbConn:hdbConns] eodPath:.cr.getCfgField[;`group;`dataPath]each hdbConns);
  /G/ Flag for filling missing tables in hdb after eod, loaded from system.cfg.
  .rdb.cfg.fillMissingTabsHdb: .cr.getCfgField[`THIS;`group;`cfg.fillMissingTabsHdb];
  /G/ Connections opening timeout, loaded from system.cfg.
  .rdb.cfg.timeout:            .cr.getCfgField[`THIS;`group;`cfg.timeout];
  /G/ Flag for reloading hdb after eod, loaded from system.cfg.
  .rdb.cfg.reloadHdb:          .cr.getCfgField[`THIS;`group;`cfg.reloadHdb];
  /G/ Rdb datapath, loaded from system.cfg.
  .rdb.cfg.dataPath:           .cr.getCfgField[`THIS;`group;`dataPath];

  .sl.libCmd[];
  .rdb.p.init[];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`rdb;`.sl.main;`];

/------------------------------------------------------------------------------/
\
