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

/S/ Aggregation ticker plant stream plugin component:
/S/ Responsible for:
/S/ - aggregating incoming data updates into larger buckets and publishing them to the subscribers
/S/
/S/ Notes:
/S/ - incoming data is cached in buffer tables (tabs in <.cache namespace>)
/S/ - aggregated data is published in tickHF (<tickHF.q>) protocol and journalled on <.stream.plug.ts> callback
/S/ - published table names are defined using outputTab field in dataflow.cfg
/S/ - by default tables are published using source name, for example aggregated trade records are published as trade table

/T/ q stream.q -lib streamAggr.q

/------------------------------------------------------------------------------/
/F/ Information about subscription protocols supported by the streamAggr component.
/F/ This definition overwrites default implementation from qsl/sl library.
/F/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server - `PROTOCOL_TICKHF
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKHF};

//----------------------------------------------------------------------------//
/F/ initialization callback invoked during component startup, before subscription
// - initialization of aggr tables publishing
.stream.plug.init:{[]
  .aggr.cfg.src2dst:exec sectionVal!?[outputTab=`;sectionVal;outputTab] from .cr.getCfgPivot[`THIS;`table`sysTable;enlist`outputTab];
  //initialize publishing using source model and configured output table names, those names should not be used for anything else
  .aggr.cfg.model:.stream.cfg.model;
  .aggr.cfg.model[;0]:.aggr.cfg.src2dst .aggr.cfg.model[;0];
  .stream.initPub[.aggr.cfg.model];  
  };

//----------------------------------------------------------------------------//
/F/ subscription callback, invoked just after subscription but before journal replay
/P/ serverSrc - source server
/P/ schema    - subscription data schema
/P/ spData - savepoint data - not used here
.stream.plug.sub:{[serverSrc;schema;spData]
  //no special action required for aggregated data
  };

//----------------------------------------------------------------------------//
/F/ timer callback, will be used 
// - aggregated data publishing and journaling
// - buffers clearing 
// - savepoint call as data was published and should not be processed again
//t:`trade
.stream.plug.ts:{[t]
  //simply publish data from .cache buffers
  {[t].pe.dotLog[`aggr;`.stream.pub;(.aggr.cfg.src2dst t; .cache t);`;`warn];delete from .stream.cacheNames t} each .stream.cfg.model[;0];
  //no data required as savepoint
  .stream.savepoint[0N];
  };

//----------------------------------------------------------------------------//
/F/ end of day trigger
/F/ - flushing the buffers
/F/ - switching journal file
/P/ date - ending date
.stream.plug.eod:{[date]
  };

//----------------------------------------------------------------------------//
.stream.initMode[`cache];
