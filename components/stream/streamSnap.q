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
/D/ 2012.05.10

/S/ Snapshoting stream plugin component:
/S/ Responsible for:
/S/ - snapshots creation on subscribed tables
/S/ Notes:
/S/ - generates snapshots on N minute basis
/S/ - data is published in tickHF (<tickHF.q>) protocol, component can be used as data source instead of tickHF
/S/ - table updates are throttled by <.stream.plug.ts> callback
/S/ - source data model modified: all subscribed tables keyed by (sym) and (minute:time casted to x minute) columns, suffix "Snap" added to table names
/S/ - data cached in original table names; processed and cleared on <.stream.plug.ts> callback

/S/ Data source assumptions:
/S/ - ticks within one table are time-sorted

/------------------------------------------------------------------------------/
/F/ Information about subscription protocols supported by the streamSnap component.
/F/ This definition overwrites default implementation from qsl/sl library.
/F/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server - `PROTOCOL_TICKHF
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKHF};

//----------------------------------------------------------------------------//
/F/ initialization callback, invoked during process startup, before subscription
/F/ - initialization of snapshots
.stream.plug.init:{[]
  //get configuration
  .snap.cfg.snapMinuteBase:.cr.getCfgField[`THIS;`group;`cfg.snapMinuteBase];
  .snap.cfg.snapTimeoutInMs:   .cr.getCfgField[`THIS;`group;`cfg.snapTimeoutInMs];
  if[0=count tabs:.cr.getCfgPivot[`THIS;`table`sysTable;enlist`outputTab];
    .log.error[`snap]"outputTabs not defined"];
  .snap.cfg.src2dst:exec sectionVal!?[outputTab=`;sectionVal;outputTab] from tabs;
  .snap.cfg.table2src:exec srcTickHF!sectionVal from 0!select sectionVal by srcTickHF from .cr.getCfgPivot[`THIS;`table`sysTable;`srcTickHF] where srcTickHF<>`;

  if[1<count distinct key .snap.cfg.table2src;
    .log.error[`snap] "Snap server supports only one data source. Two were specified: ", .Q.s1[distinct key .snap.cfg.table2src];
    exit 1;
    ];

  //initialize publishing using source model and configured output table names, those names should not be used for anything else
  .snap.cfg.model:.stream.cfg.model;
  .snap.cfg.model[;0]:.snap.cfg.src2dst .snap.cfg.model[;0];

  //initialize local vars
  .snap.lastSnapTs:(!). flip flip ( key[.snap.cfg.table2src];00:00:00.000);

  //initialize publishing
  .stream.initPub[.snap.cfg.model];
  };

//----------------------------------------------------------------------------//
/F/ subscription callback, invoked just after subscription but before journal replay
// - initialization of snapshot tables
// - initialization of snapshot publishing
/P/ serverSrc - source server
/P/ schema    - subscription data schema
/P/ savepointData - savepoint data - not used here
.stream.plug.sub:{[serverSrc;schema;savepointData]
  //  (`serverSrc`schema`savepointData) set' (serverSrc;schema;savepointData);

  //use savepoint if it is valid
  if[not savepointData~(::);
    //initialize buffers and lastSnapTs using savepointData
    .snap.lastSnapTs:savepointData 0;
    `.cache set savepointData 1;
    ];
  };

//----------------------------------------------------------------------------//
/F/ timer callback, will be used 
// - generation of snapshots from the buffer tables
// - snapshots publishing and journalling
// - buffers clearing 
// - savepoint call as data was published and should not be processed again; (::) if no savepointData
.stream.plug.ts:{[t]  
  allTabsTs:key[.snap.cfg.table2src]!min each {00:00:00.000 | last x[`time]}each/: .cache each value .snap.cfg.table2src;
  snapMs:.snap.cfg.snapMinuteBase*00:01:00.000;
  canSnapUntil:.snap.lastSnapTs+(missingSnaps:ceiling (allTabsTs-.snap.lastSnapTs)%snapMs)*snapMs;
  if[count notMissing:where missingSnaps>0; //or(t>canSnapUntil+.snap.cfg.snapTimeoutInMs);
    .log.debug[`snap] "generating snapshots untill ",(" "sv string[notMissing])," " ," "sv string[canSnapUntil[notMissing]];
    {[ts;tab] .snap.p.snapOneTab[ts;] each tab}'[canSnapUntil[notMissing];.snap.cfg.table2src[notMissing]]; //iterating over all source tables
    .snap.lastSnapTs:canSnapUntil;
    .stream.savepoint[(.snap.lastSnapTs;.cache)];
    ];
  };

//helper function for creation snanspots
.snap.p.snapOneTab:{[nextSnap;tab]
  data:cols[.cache[tab]] xcols 0!select by sym, time:`time$.snap.cfg.snapMinuteBase xbar time.minute from .cache[tab] where time<=nextSnap;
  .pe.dotLog[`aggr;`.stream.pub;(.snap.cfg.src2dst[tab]; data);`;`warn];  //data publishing and journaling
  delete from .stream.cacheNames[tab] where time<=nextSnap;
  .log.debug[`snap] "snapshots generated untill ", string[nextSnap], ": ",string[.snap.cfg.src2dst[tab]], "(#", string[count data],") .cache.",string[tab],"(#",string[count .cache[tab]],")" ;
  };

//----------------------------------------------------------------------------//
/F/ end of day trigger
// - flushing the buffers
// - switching journal file
.stream.plug.eod:{[day]
  .log.debug[`snap] "generating last snapshot for the day ", string[day];
  .snap.p.snapOneTab[24:00:00.000]each raze value .snap.cfg.table2src; //iterating over all source tables
  .snap.lastSnapTs:(!). flip flip ( raze value[.snap.cfg.table2src];00:00:00.000);
  .stream.savepoint[(::)]; //clear savepoint
  };

//----------------------------------------------------------------------------//
.stream.initMode[`cache];
/
