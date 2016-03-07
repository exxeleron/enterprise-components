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

/S/ mrvs server - most recent values plugin for rproc component
/-/ keeps mrvs in the memory, can initialize from the hdb
/-/ Full description in components/rproc/README.md

//----------------------------------------------------------------------------//
/F/ Initializes mrvs global tables. If hdb srv was configured - uses data from hdb, otherwise empty model.
/P/ srv:LIST SYMBOL - used for initialization from hdb
/R/ no return value
/E/ .rp.plug.init[`core.tickHF]
.rp.plug.init:{[srv];
  //init from hdb
  if[srv~();
    :{[hdb;tab]tab set update`u#sym from .hnd.h[hdb](.mrvs.hdb.lastBySym;tab;.z.d-1)}[srv]each .rp.cfg.srcTabs;
    ];
  //init without hdb - empty tables
  :{[tab] tab set update`u#sym from select by sym from .rp.cfg.model[tab]}each .rp.cfg.srcTabs;
  };

//----------------------------------------------------------------------------//
/F/ Retrievs the mrvs for specified day from hdb server (to be executed on hdb server).
/-/ Helper function used during .rp.plug.init[].
/P/ tab:SYMBOL - table name
/P/ day:DATE   - date in hdb which should be used for query
/R/ :TABLE - mrvs table
/-/  -- sym:SYMBOL - instrument
/-/  -- [cols]:ANY - last values from each column in the tab data model
/E/ .mrvs.hdb.lastBySym[`trade;.z.d]
.mrvs.hdb.lastBySym:{[tab;day]
  select by sym from tab where date=day
  };

//----------------------------------------------------------------------------//
/F/ Upserts mrvs data to proper table. Only last value per symbol is preserved.
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
/R/ no return value
/E/ .rp.plug.upd[`trade;tradeData]
.rp.plug.upd:upsert;

//----------------------------------------------------------------------------//
