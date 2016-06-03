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

/S/ Store library:
/-/ library for data storage in the hdb (<hdb.q>)
/-/ Functionality:
/-/ - data storage as splayed and partition table
/-/ - callback for reloading and filling missing tables in hdb (<hdb.q>)
/-/ - end of day support and integration with eodMng (<eodMng.q>) component

/------------------------------------------------------------------------------/
/                               lib and etc                                    /
/------------------------------------------------------------------------------/
.sl.init[`store];

/------------------------------------------------------------------------------/
/                              interface functions                             /
/------------------------------------------------------------------------------/
/F/ Initializes store library. Function should be invoked once, before any calls of the .store.run[].
/P/ config:TABLE               - that contains:
/-/  -- table:SYMBOL             - table name
/-/  -- hdbPath:SYMBOL           - path to the hdb; path to hdb location is taken automatically from system.cfg (field: dataPath) for given hdb name
/-/  -- hdbName:SYMBOL           - connection to reload hdb
/-/  -- memoryClear:BOOLEAN      - flag for clearing data after data storing is performed
/-/  -- store:BOOLEAN            - flag for performing data storing
/-/  -- attrCol:SYMBOL           - column which should have attribute p applied (optional column in the configuration table, if missing will be filled with `sym)
/P/ reloadHdb:BOOLEAN          - flag for reloading hdb after storing
/P/ fillMissingTabsHdb:BOOLEAN - flag for filling missing tables in hdb after storing is completed 
/P/ dataPath:PATH              - path to the directory that can be used for storing status of the store procedure
/R/ no return value
/E/ .store.init[([]table:enlist `quote;hdbPath:`:hdb;hdbName:`core.hdb;memoryClear:1b;store:1b); 1b; 1b; `:data/]
/-/     - initializes store library for one table - quote with the following configuration:
/-/       -- quote will be stored in `:hdb directory
/-/       -- `core.hdb process will be reloaded after store is completed
/-/       -- quote table content will be deleted in memory once the store procedure is completed.
.store.init:{[config;reloadHdb;fillMissingTabsHdb;dataPath]
  /G/ Path to the file used for communication with eodMng.
  .store.comFile:` sv dataPath,`eodStatus;    
  .store.notifyStoreBefore[.sl.eodSyncedDate[]];
  hdbNames:distinct exec hdbName from config where not hdbName~'`;
  /G/ Table with settings connected with postprocessing steps executed once the store procedure is completed.
  /-/  -- reloadHdb:BOOLEAN          - true if hdb should be reloaded
  /-/  -- fillMissingTabsHdb:BOOLEAN - true if fillMissingTabs shoult be executed on hdb after store is completed
  /-/  -- hdbConns:LIST SYMBOL       - list of hdb processes that should receive reload signal once the store is completed.
  .store.settings:flip  `reloadHdb`fillMissingTabsHdb`hdbConns!enlist each (reloadHdb;fillMissingTabsHdb;hdbNames);
  if[not `attrCol in cols config;
    config:update attrCol:`sym from config;
    ];
  /G/ Table with settings connected with tables processed by the store library.
  /-/  -- table:SYMBOL        - table name
  /-/  -- hdbPath:SYMBOL      - full path to the hdb directory
  /-/  -- memoryClear:BOOLEAN - true if garbage collector should be executed after the store is completed
  /-/  -- store:BOOLEAN       - true if actual data write should be performed
  /-/  -- attrCol:SYMBOL      - name of the column that should get `p attribute
  .store.tabs:config;
  };

/------------------------------------------------------------------------------/
/F/ Writes tables to PARTITIONED hdb for the given day. Triggers notification callbacks, main top-level store function.
/-/ Requires one initial call of .store.init[].
/-/ Perform actions based on the configuration set via .store.init[], those might include:
/-/  - data storing and cleaning
/-/  - invoke callbacks for reloading 
/-/  - filling missing tables in partitions
/P/ date:DATE - eod date (in most cases current date) 
/R/ no return value
/E/ .store.run[2015.01.01]
/-/     - executes storing configured tables to partition 2015.01.01
/-/     - triggers .store.notifyStoreBegin, .store.notifyStoreRecovery, .store.notifyStoreSuccess and .store.notifyStoreBefore callbacks
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
/F/ Performs storing procedure for tables specified in the config param, without trigger of notification callbacks.
/P/ date:DATE - eod date (in most cases current date) 
/P/ config:TABLE - (equivalent to <.store.tabs> and to <.store.init> parameter):
/-/  -- table:SYMBOL - table name
/-/  -- hdbPath:SYMBOL - path to the hdb; path to hdb location is taken automatically from system.cfg (field: dataPath) for given hdb name
/-/  -- hdbName:SYMBOL - connection to reload hdb
/-/  -- memoryClear:BOOLEAN - flag for clearing data after data storing is performed
/-/  -- store:BOOLEAN - flag for performing data storing
/-/  -- attrCol:SYMBOL - column which should have attribute p applied (optional column in the configuration table, if missing will be filled with `sym).
/R/ :LIST[SYMBOL] - list of statuses of each stored table (`error in case of given table failure)
/E/ .store.storeAll[2015.01.01;config]
/-/     - executes storing configured tables to partition 2015.01.01 with given configuration
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
/F/ Store and clear tables.
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
/F/ Splay tables using .Q.dpft.
.store.p.splay:{[date;table;eodPath;attrCol]
  .log.info[`store] "Storing table: ", string[table], ", attrCol:",.Q.s1[attrCol]," #count:",string count value table; 
  /G/ Temporary global variable used to persist in-memory table keys.
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
/F/ Clear global tables.
/E/ table:`trade
.store.p.clear:{[table;attrCol]
  delete from table;
  if[98h=type value table;
    @[table;attrCol;`g#];
    ];
    .Q.gc[]; 
  };

/------------------------------------------------------------------------------/
/F/ Reload hdb server asynchronously (trigger ".hdb.reload[]"). 
/P/ hdb:SYMBOL - name of the hdb process that should be reloaded
/R/ no return value
/E/ .store.reloadHdb[`core.hdb]
/-/     - trigger asynchronously reload of the content on the hdb directory on hdb process `core.hdb
.store.reloadHdb:{[hdb]
  .hnd.ah[hdb]".hdb.reload[]";
  };

/------------------------------------------------------------------------------/
/F/ Fill missing tables in partitioned hdb directory. (see http://code.kx.com/wiki/DotQ/DotQDotchk)
/P/ hdb:SYMBOL - path to the hdb that should be modified
/R/ no return value
/E/ .store.fillMissingTabs[`:hdb]
/-/     - fills missing tables in the `:hdb directory
.store.fillMissingTabs:{[hdb]
  .Q.chk[hdb];
  };
  
/------------------------------------------------------------------------------/
/                        file communication interface                          /
/------------------------------------------------------------------------------/

.store.p.notifyFile:{[msg;date]
  .pe.at[(`$(string .store.comFile),(string date)) 0: ;enlist msg," ",string date;{}]
  };

/F/ Default .store.notifyStoreBefore callback - configuration initialized correctly, notify that waiting for store procedure startup.
/-/ Callback used for communication with the eodMng, see .store.comFile file.
/P/ date:DATE - eod date
/R/ no return value
/E/ .store.notifyStoreBefore 2010.01.01
.store.notifyStoreBefore:{[date].store.p.notifyFile["eodBefore";date];};

/F/ Default .store.notifyStoreBegin callback - notify that the store procedure started.
/-/ Callback used for communication with the eodMng, see .store.comFile file.
/P/ date:DATE - eod date
/R/ no return value
/E/ .store.notifyStoreBegin 2010.01.01
.store.notifyStoreBegin:{[date].store.p.notifyFile["eodDuring";date];};

/F/ Default .store.notifyStoreSuccess callback - notify that the store was successful.
/-/ Callback used for communication with the eodMng, see .store.comFile file.
/P/ date:DATE - eod date
/R/ no return value
/E/ .store.notifyStoreSuccess 2010.01.01
.store.notifyStoreSuccess:{[date].store.p.notifyFile["eodSuccess";date];};

/F/ Default .store.notifyStoreFail callback - notify that the store failed.
/-/ Callback used for communication with the eodMng, see .store.comFile file.
/-/ *note:* unused at the moment - may be useful in the future
/P/ date:DATE - eod date
/R/ no return value
/E/ .store.notifyStoreFail 2010.01.01
.store.notifyStoreFail:{[date].store.p.notifyFile["eodFail";date];};

/F/ Default .store.notifyStoreRecovery callback - notify recovery state.
/-/ Callback used for communication with the eodMng, see .store.comFile file.
/P/ date:DATE - eod date
/R/ no return value
/E/ .store.notifyStoreRecovery 2010.01.01
.store.notifyStoreRecovery:{[date].store.p.notifyFile["eodRecovery";date];};
