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

/S/ Aggregation ticker plant stream plugin component:
/-/ Responsible for:
/-/ - aggregating incoming data updates into larger buckets and publishing them to the subscribers
/-/
/-/ Notes:
/-/ - incoming data is cached in buffer tables (tabs in <.cache namespace>)
/-/ - aggregated data is published in tickHF (<tickHF.q>) protocol and journalled on <.stream.plug.ts> callback
/-/ - published table names are defined using outputTab field in dataflow.cfg
/-/ - by default tables are published using source name, for example aggregated trade records are published as trade table
/-/
/-/ q stream.q -lib streamAggr.q

/------------------------------------------------------------------------------/
/F/ Returns information about subscription protocols supported by the streamAggr component.
/-/ This definition overwrites default implementation from qsl/sl library.
/-/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server - `PROTOCOL_TICKHF
/E/  .sl.getSubProtocols[]
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKHF};

//----------------------------------------------------------------------------//
/F/ Initialization callback invoked during component startup, before subscription.
/-/ - initialization of aggr tables publishing
/R/ no return value
/E/  .stream.plug.init[]
.stream.plug.init:{[]
  /G/ Dictionary with source table to output table mapping, loade from outputTab field from dataflow.cfg.
  .aggr.cfg.src2dst:exec sectionVal!?[outputTab=`;sectionVal;outputTab] from .cr.getCfgPivot[`THIS;`table`sysTable;enlist`outputTab];
  /G/ Publishing data model, the same as source data model, loaded from .stream.cfg.model.
  .aggr.cfg.model:.stream.cfg.model;
  .aggr.cfg.model[;0]:.aggr.cfg.src2dst .aggr.cfg.model[;0];
  .stream.initPub[.aggr.cfg.model];  
  };

//----------------------------------------------------------------------------//
/F/ Subscription callback, invoked just after subscription but before journal replay, no action required.
/P/ serverSrc:SYMBOL - source server
/P/ schema:LIST      - subscription data schema
/P/ spData:ANY       - savepoint data - empty in this plugin
/R/ no return value
/E/  .stream.plug.sub[`core.tickHF;((`trade;tradeModel);(`quote;quoteModel));0N]
.stream.plug.sub:{[serverSrc;schema;spData]
  //no special action required for aggregated data
  };

//----------------------------------------------------------------------------//
/F/ Timer callback, used for aggregated data publishing.
/-/  - aggregated data publishing and journaling
/-/  - buffers clearing 
/-/  - savepoint call as data was published and should not be processed again
/P/ t:TIME - timer time
/R/ no return value
/E/ .stream.plug.ts .z.t
.stream.plug.ts:{[t]
  //simply publish data from .cache buffers
  {[t].pe.dotLog[`aggr;`.stream.pub;(.aggr.cfg.src2dst t; .cache t);`;`warn];delete from .stream.cacheNames t} each .stream.cfg.model[;0];
  //no data required as savepoint
  .stream.savepoint[0N];
  };

//----------------------------------------------------------------------------//
/F/ End of day callback, no action required.
/-/ - flushing the buffers
/-/ - switching journal file
/P/ date:DATE - ending date
/R/ no return value
/E/  .stream.plug.eod .z.d
.stream.plug.eod:{[date]
  //no special action required for aggregated data
  };

//----------------------------------------------------------------------------//
.stream.initMode[`cache];
