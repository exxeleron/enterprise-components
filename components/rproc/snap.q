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

/S/ snap server - minute snapshot plugin for rproc component
/-/ keeps 1-minute snapshots in the memory
/-/ Full description in components/rproc/README.md

//----------------------------------------------------------------------------//
/F/ Initializes data model for snapshots - keyed by minute/sym.
/P/ srv:LIST SYMBOL - not used
/R/ no return value
/E/  .rp.plug.init[`core.tickHF]
.rp.plug.init:{[srv];
  :{[tab] tab set update`g#sym from select by time.minute, sym from .rp.cfg.model[tab]}each .rp.cfg.srcTabs;
  };

//----------------------------------------------------------------------------//
/F/ Upserts new data by minute/sym.
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
/R/ no return value
/E/ .rp.plug.upd[`trade;tradeData]
.rp.plug.upd:{[tab;data]
  tab upsert select by time.minute, sym from data
  };

//----------------------------------------------------------------------------//
/F/ Clears the in-memory tables at the end of day. Process is designed to keep only one day.
/P/ day:DATE - day that just have ended
/R/ no return value
/E/ .rp.plug.end[.z.d]
.rp.plug.end:{[day]
  {update`g#sym from delete from x}each .rp.cfg.srcTabs;
  };

//----------------------------------------------------------------------------//
