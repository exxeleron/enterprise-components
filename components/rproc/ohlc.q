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
/V/ 3.1

/S/ ohlc - open-high-low-close plugin for rproc component
/-/ keeps ohlc in the memory and publishes updates to ohlc to the subscribers
/-/ Full description in components/rproc/README.md

//----------------------------------------------------------------------------//
/F/ Initializes ohlc global table, the data model based on [table:ohlc] definition from dataflow.cfg.
/-/ Model loaded via `.rp.cfg.model`.
/P/ srv:LIST SYMBOL - not used
/R/ no return value
/E/  .rp.plug.init[`core.tickHF]
.rp.plug.init:{[srv];
  ohlc::`sym xcol .rp.cfg.model[`ohlc];
  };

//----------------------------------------------------------------------------//
/F/ Updates the global table ohlc and publishes changed records using .u.pub function.
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
/R/ no return value
/E/ .rp.plug.upd[`trade;tradeData]
.rp.plug.upd:{[tab;data]
  ohlc::select first open, max high,min low,last close,sum volume by sym from(0!ohlc),select sym,open:price,high:price,low:price,close:price,volume:size from data;
  syms:exec distinct sym from data;
  //publish only those records that did change
  .u.pub[`ohlc;0!select from ohlc where sym in syms];
  };

//----------------------------------------------------------------------------//
