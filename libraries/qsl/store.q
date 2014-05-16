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

/A/ DEVnet:  Bartosz Dolecki
/V/ 3.0

/S/ Store library:
/S/ Library for data storage in the hdb (<hdb.q>)

/S/ Provides:
/S/ - data storage as splayed and partition table
/S/ - callback for reloading and filling missing tables in hdb (<hdb.q>)
/S/ - end of day support and integration with eodMng (<eodMng.q>) component

/------------------------------------------------------------------------------/
/                               lib and etc                                    /
/------------------------------------------------------------------------------/
.sl.init[`store];

/------------------------------------------------------------------------------/
/                              interface functions                             /
/------------------------------------------------------------------------------/
/F/ initialization of store library
/P/ config:TABLE - that contains:
/P/  -- table:SYMBOL - table name
/P/  -- hdbPath:SYMBOL - path to the hdb; path to hdb location is taken automatically from system.cfg (field: dataPath) for given hdb name
/P/  -- hdbName:SYMBOL - connection to reload hdb
/P/  -- memoryClear:BOOLEAN - flag for clearing data after data storing is performed
/P/  -- store:BOOLEAN - flag for performing data storing
/P/  -- attrCol:SYMBOL - column which should have attribute p applied (optional column in the configuration table, if missing will be filled with `sym)
/P/ reloadHdb:BOOLEAN - flag for reloading hdb after storing
/P/ fillMissingTabsHdb:BOOLEAN - flag for filling missing tables in hdb after storing is completed 
/P/ dataPath:PATH - path to the directory that can be used for storing status of the store procedure
/E/ .store.init[flip (`table`hdbPath`hdbName`memoryClear`store!(enlist `quote;enlist `:hdb;enlist `kdb.hdb;enlist 1b; enlist 1b));1b;1b;`:data/]
//config:p 0;reloadHdb:p 1;fillMissingTabsHdb:p 2
.store.init:{[config;reloadHdb;fillMissingTabsHdb;dataPath]
  .store.comFile:` sv dataPath,`eodStatus;    /G/ file to communicate with eodMng 
  .store.notifyStoreBefore[.sl.eodSyncedDate[]];
  hdbNames:distinct exec hdbName from config where not hdbName~'`;
  .store.settings:flip  `reloadHdb`fillMissingTabsHdb`hdbConns!enlist each (reloadHdb;fillMissingTabsHdb;hdbNames);
  if[not `attrCol in cols config;
    config:update attrCol:`sym from config;
    ];
  .store.tabs:config;
  .log.info[`store;"store initialization completed"];
  };

/------------------------------------------------------------------------------/
/F/ Perform storing procedure; main top level function
/F/ - data storing and cleaning
/F/ - invoke callbacks for reloading and filling missing tables in partitions
/F/ - .store.run should be proceeded by the <.store.init> with proper data storing settings
/P/ date:DATE - eod date (in most cases current date) 
.store.run:{[date]
  .log.info[`store] "[Start] Store data for date ", string date;
  .store.notifyStoreBegin[date];
  status:.store.storeAll[date;.store.tabs];
  .log.info[`store] "[Storing data completed]";
  $[`error in status;.store.notifyStoreRecovery[date];.store.notifyStoreSuccess[date]];
  .store.notifyStoreBefore[date+1];
  };
  
/------------------------------------------------------------------------------/
/                              additional functions                            /
/------------------------------------------------------------------------------/
/F/ Perform storing procedure for all tables specified in eodTabs parameter
/P/ date:DATE - eod date (in most cases current date) 
/P/ config:TABLE - (equivalent to <.store.tabs> and to <.store.init> parameter):
/P/  -- table:SYMBOL - table name
/P/  -- hdbPath:SYMBOL - path to the hdb; path to hdb location is taken automatically from system.cfg (field: dataPath) for given hdb name
/P/  -- hdbName:SYMBOL - connection to reload hdb
/P/  -- memoryClear:BOOLEAN - flag for clearing data after data storing is performed
/P/  -- store:BOOLEAN - flag for performing data storing
/P/  -- attrCol:SYMBOL - column which should have attribute p applied (optional column in the configuration table, if missing will be filled with `sym).
.store.storeAll:{[date;config]
  tabexclude:config[`table] where not config[`table] in tables[];
  if[count tabexclude;
    .log.warn[`store] "Tables ",.Q.s1[tabexclude], " are not defined, therefore they will be excluded from storing process";
    ];
  config:select from config where not table in tabexclude;
  
  .log.debug[`store] "Sorting tables by row count. Smaller tables will be stored first.";
  config:delete cnt from `cnt xasc update cnt:count'[value'[table]] from config;


  gAttrTables:tabs where {`g<>meta[x 0][x 1][`a]}each tabs:flip config`table`attrCol;

  .log.debug[`store] "Applying `g attribute for pairs (table;col): ", .Q.s1[gAttrTables];
  {if[98h=type value x 0;@[x 0;x 1;`g#]]} each gAttrTables;
  eodPerform:select from config where store or memoryClear;
  .log.info[`store] "Perform storing and clearing tables: ", .Q.s1[eodPerform`table];
  status:(::);
  status:status,.store.p.store[date;] each eodPerform;
  eodPaths:exec distinct hdbPath from eodPerform where store;
  if[first .store.settings`fillMissingTabsHdb;
    status:status,:{[x].event.at[`store;`.store.fillMissingTabs;x;`error;`info`info`error;"Fill missing tabs in hdb: ",string[x]]} each eodPaths;
    ];
    if[first .store.settings`reloadHdb;
      {[x].event.at[`store;`.store.reloadHdb;x;`error;`info`info`error;"Reload hdb: ",string[x]]} each first .store.settings`hdbConns;
      ];
    
  status
  };

/------------------------------------------------------------------------------/
/F/ store and clear tables
// eodTab:first eodPerform
.store.p.store:{[date;eodTab]
  table:eodTab`table;
  if[eodTab`store;
    status:.event.dot[`store;`.store.p.splay;(date;table;eodTab`hdbPath;eodTab`attrCol);`error;`info`info`error;"splaying table ",string[table]," in hdb ",string[eodTab`hdbPath]," ,date ",string[date]];
      ];
  if[eodTab`memoryClear; 
    .event.dot[`store;`.store.p.clear;(table;eodTab`attrCol);`error;`info`info`error;"clear table ",string[table]];
    ];
  status
  };

/------------------------------------------------------------------------------/
/F/ splay tables using .Q.dpft
.store.p.splay:{[date;table;eodPath;attrCol]
  .log.info[`store] "Storing table: ", string[table], ", attrCol:",.Q.s1[attrCol]," #count:",string count value table; 
  .store.tmp.eodKeys:();
  if[99h=type value table;
    .store.tmp.eodKeys:cols key value table;
    table set 0!value table; //removing keys before dpft procedure
    ];
  .Q.dpft[eodPath;date;attrCol;table];
  if[count .store.tmp.eodKeys;
    table set count[.store.tmp.eodKeys]!value table;  //restoring keys after dpft procedure
    ];
  };

/------------------------------------------------------------------------------/
/F/ clear global tables
/E/ table:`trade
.store.p.clear:{[table;attrCol]
  delete from table;
  if[98h=type value table;
    @[table;attrCol;`g#];
    ];
    .Q.gc[]; 
  };

/------------------------------------------------------------------------------/
/F/ Reload hdb server asynchronously
/P/ hdb:SYMBOL - name of the hdb process that should be reloaded
.store.reloadHdb:{[hdb]
  .hnd.ah[hdb]".hdb.reload[]";
  };

/------------------------------------------------------------------------------/
/F/ Fill missing tables in partitioned hdb directory
/P/ hdb:SYMBOL - path to the hdb that should be modified
.store.fillMissingTabs:{[hdb]
  .Q.chk[hdb];
  };
  
/------------------------------------------------------------------------------/
/                        file communication interface                          /
/------------------------------------------------------------------------------/

.store.p.notifyFile:{[msg;date]
  .pe.at[(`$(string .store.comFile),(string date)) 0: ;enlist msg," ",string date;{}]
  };

/F/ Configuration initialized correctly; notify that waiting for store procedure startup
/P/ date:DATE - eod date
.store.notifyStoreBefore:{[date].store.p.notifyFile["eodBefore";date];}

/F/ Notify that the store procedure started
/P/ date:DATE - eod date
.store.notifyStoreBegin:{[date].store.p.notifyFile["eodDuring";date];}

/F/ Notify that the store was successful
/P/ date:DATE - eod date
.store.notifyStoreSuccess:{[date].store.p.notifyFile["eodSuccess";date];}

/F/ Notify that the store failed;
/F/ *note:* unused at the moment - may be useful in the future
/P/ date:DATE - eod date
.store.notifyStoreFail:{[date].store.p.notifyFile["eodFail";date];}

/F/ Notify recovery state
/P/ date:DATE - eod date
.store.notifyStoreRecovery:{[date].store.p.notifyFile["eodRecovery";date];}
