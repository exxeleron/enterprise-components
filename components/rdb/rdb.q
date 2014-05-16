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

/A/ DEVnet: Rafal Sytek, Bartosz Kaliszuk, Joanna Jarmulska
/V/ 3.0
/T/ q rdb.q 

/S/ Real time database component:
/S/ Responsible for:
/S/ - handling functionality of real time database
/S/ - configuration of subscription and End-Of-Day process
/S/ - performing auto re-subscription and auto re-connection mechanism to Tickerplant
/S/ - automatic journal replaying at startup

/S/ Subscription tables:
/S/ To add new tables for subscription, add them to dataflow.cfg configuration file.

/S/ End-Of-Day tables:
/S/ To add new tables for End-Of-Day processing, add them to dataflow.cfg configuration file.
/S/ Note that for End-Of-Day procedure there is need to setup only logical name of the hdb. Path to hdb location is taken automatically from the system.cfg (field: dataPath) for given hdb name

/S/ Plugins:
/S/ List of plugins to setup:
/S/ - dictionary of functions invoked before eod execution
/S/ (start code)
/S/ .rdb.plug.beforeEod[name of the plugin:SYMBOL][date:DATE]
/S/ .rdb.plug.beforeEod[`createOhlc]:{[date] `ohlc set select open:price, high:price, low:price, close:price by sym from trade}
/S/ (end)
/S/ - dictionary of functions invoked after eod execution
/S/ (start code)
/S/ .rdb.plug.afterEod[name of the plugin:SYMBOL][date:DATE]
/S/ .rdb.plug.afterEod[`createMrvs]:{[date] `mrvs insert select by sym from trade}
/S/ (end)
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
/G/ before eod plugins
/E/ .rdb.plug.beforeEod[`createOhlc]:{[date] `ohlc set select open:price, high:price, low:price, close:price by sym from trade}
.rdb.plug.beforeEod:()!();
/G/ after eod plugins
/E/ .rdb.plug.afterEod[`createMrvs]:{[date] `mrvs insert select by sym from trade}
.rdb.plug.afterEod:()!();
/------------------------------------------------------------------------------/
/                              interface functions                             /
/------------------------------------------------------------------------------/
/F/ End-Of-Day (eod) callback from subscribed tickHF server (e.g.: tickHF)
/P/ date:DATE - eod date (in most cases current date)
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
/F/ perform eod plugins
/P/ act - action, can be before, after eod
/P/ tab - table name
/P/ date - current date
/E/ act:`beforeEod
/E/ tab:`ohlc
.rdb.p.eodAct:{[act;tab;date]
  funcName:` sv`.rdb.plug,act,tab;
  .event.at[`rdb;funcName;date;();`info`info`error;"Perform ",string[act] ," for table ",string tab];
  };

/------------------------------------------------------------------------------/
/F/ initializes the rdb component
/E/ .rdb.p.init[]
.rdb.p.init:{[]
  .rdb.date:.sl.eodSyncedDate[];

  //end of day
  eodTabs:select table:sectionVal, hdbPath:eodPath, hdbName:hdbConn, memoryClear:eodClear, store:eodPerform from .rdb.cfg.eodTabs;
  .store.init[eodTabs;.rdb.cfg.reloadHdb;.rdb.cfg.fillMissingTabsHdb;.rdb.cfg.dataPath];

  //connections
  hdb2conn:exec distinct hdbConn from .rdb.cfg.eodTabs where not hdbConn~'`;
  if[count hdb2conn;
    .hnd.hopen[hdb2conn;.rdb.cfg.timeout;`lazy];
    ];
  };

/==============================================================================/
.sl.main:{[flags]
  .rdb.cfg.eodTabs:             .cr.getCfgPivot[`THIS;`table`sysTable;`hdbConn`eodClear`eodPerform];
  hdbConns:(exec distinct hdbConn from .rdb.cfg.eodTabs) except `;
  .rdb.cfg.eodTabs:.rdb.cfg.eodTabs lj ([hdbConn:hdbConns] eodPath:.cr.getCfgField[;`group;`dataPath]each hdbConns);
  .rdb.cfg.fillMissingTabsHdb: .cr.getCfgField[`THIS;`group;`cfg.fillMissingTabsHdb];
  .rdb.cfg.timeout:            .cr.getCfgField[`THIS;`group;`cfg.timeout];
  .rdb.cfg.reloadHdb:          .cr.getCfgField[`THIS;`group;`cfg.reloadHdb];
  .rdb.cfg.dataPath:           .cr.getCfgField[`THIS;`group;`dataPath];

  .sl.libCmd[];
  .rdb.p.init[];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`rdb;`.sl.main;`];

/------------------------------------------------------------------------------/
\
