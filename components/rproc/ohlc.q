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
/V/ 3.1

/S/ ohlc - open-high-low-close plugin for rproc component
/S/ keeps ohlc in the memory and publishes updates to ohlc to the subscribers
/S/ Full description in components/rproc/README.md

//----------------------------------------------------------------------------//
/F/ initialization of the `derived data model` based on the `source data model` 
/F/ located in `.rp.cfg.model` dictionary.
/F/ `.rp.cfg.srcTabs` contains a list of the tables which are subscribed.
/P/ srv:LIST SYMBOL - not used
.rp.plug.init:{[srv];
  ohlc::`sym xcol .rp.cfg.model[`ohlc];
  };
//----------------------------------------------------------------------------//
/F/ update the global table ohlc and publish changed records using .u.pub function
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
.rp.plug.upd:{[tab;data]
  ohlc::select first open, max high,min low,last close,sum volume by sym from(0!ohlc),select sym,open:price,high:price,low:price,close:price,volume:size from data;
  syms:exec distinct sym from data;
  //publish only those records that did change
  .u.pub[`ohlc;0!select from ohlc where sym in syms];
  };
//----------------------------------------------------------------------------//
