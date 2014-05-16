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

/S/ Most recent values (mrvs) stream plugin component:
/S/ Responsible for:
/S/ - capturing and storing most recent values
/S/ Notes:
/S/ - mrvs is subscribing for selected tables to the tickHF server
/S/ - data model of each subscribed table is modified, all subscribed tables are keyed by sym column and suffix "Mrvs" added to table names
/S/ - mrvs tables keep exactly one (most recent) record per symbol that came for each table
/S/ - update frequency is throttled by <.plug.ts> providing lower cpu usage
/S/ - mrvs state can be dumped every N minutes
/S/ - mrvs tables are updated on ts callback
/S/ - data is cached in original table names and deleted on ts callback

.sl.lib["qsl/store"];

//----------------------------------------------------------------------------//
/F/ initialization callback, invoked during component startup, before subscription
/F/ - initialization of end of day 
.stream.plug.init:{[]
  .mrvs.cfg.tables:            .cr.getCfgPivot[`THIS;`table`sysTable;`hdbConn`eodClear`eodPerform];
  hdbConns:(exec distinct hdbConn from .mrvs.cfg.tables) except `;
  .mrvs.cfg.tables:.mrvs.cfg.tables lj ([hdbConn:hdbConns] eodPath:.cr.getCfgField[;`group;`dataPath]each hdbConns);
  .mrvs.cfg.mrvsDumpInterval:  .cr.getCfgField[`THIS;`group;`cfg.mrvsDumpInterval];
  .mrvs.cfg.fillMissingTabsHdb:.cr.getCfgField[`THIS;`group;`cfg.fillMissingTabsHdb];
  .mrvs.cfg.reloadHdb:         .cr.getCfgField[`THIS;`group;`cfg.reloadHdb];
  .mrvs.cfg.dataPath:          .cr.getCfgField[`THIS;`group;`dataPath];
  .mrvs.lastDumpTs:00:00:00.000;
  
  .mrvs.cfg.src2dst:exec sectionVal!?[outputTab=`;sectionVal;outputTab] from .cr.getCfgPivot[`THIS;`table`sysTable;enlist`outputTab];

  //end of day initialization
  eodTabs:select table:sectionVal, hdbPath:eodPath, hdbName:hdbConn, memoryClear:eodClear, store:eodPerform from .mrvs.cfg.tables;
  .store.init[eodTabs;.mrvs.cfg.reloadHdb;.mrvs.cfg.fillMissingTabsHdb;.mrvs.cfg.dataPath];
  };

//----------------------------------------------------------------------------//
/F/ subscription callback
// - initialization of .mrvs.file dict - names of dump files
// - initialization of data model
.stream.plug.sub:{[serverSrc;schema;savepointData]
  .mrvs.lastDumpTs:00:00:00.000;
  if[not savepointData~(::);
    //initialize mrvs using savepointData
    (set) ./: savepointData where savepointData[;0] in schema[;0];
    ];
  };

//----------------------------------------------------------------------------//
/F/ mrvs tables are updated here; mrvs dump will be used for mrvs initialization on the server restart
.stream.plug.ts:{[tm]
  {[t]
    .[.mrvs.cfg.src2dst[t];();,;select by sym from .cache t]; 
    delete from .stream.cacheNames t;
    } each key .stream.cacheNames;
  if[(`time$tm) >.mrvs.lastDumpTs + .mrvs.cfg.mrvsDumpInterval;
    .log.debug[`mrvs] "savepoint: store current mrvs state";
    .mrvs.lastDumpTs:(`time$tm);
    //dump current state
    .stream.savepoint[value[.mrvs.cfg.src2dst](;)'value'[value[.mrvs.cfg.src2dst]]];
    ];
  };

//----------------------------------------------------------------------------//
/F/ end of day
// - reset of dump file
// - cleanup of internal buffers
.stream.plug.eod:{[day]
  .store.run[day];
  .log.info[`mrvs] "eod:cleanup memory";
  {[t]delete from .stream.cacheNames[t]; delete from .mrvs.cfg.src2dst[t]} each key .stream.cacheNames;
  };

//----------------------------------------------------------------------------//
.stream.initMode[`cache];

//----------------------------------------------------------------------------//