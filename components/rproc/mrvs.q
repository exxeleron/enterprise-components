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

/S/ mrvs server - most recent values plugin for rproc component
/S/ keeps mrvs in the memory, can initialize from the hdb
/S/ Full description in components/rproc/README.md

//----------------------------------------------------------------------------//
/F/ If hdb srv was configured - initialize from hdb, otherwise init with empty data model
/P/ srv:LIST SYMBOL - used for initialization from hdb
.rp.plug.init:{[srv];
  //init from hdb
  if[srv~();
    :{[hdb;tab]tab set update`u#sym from .hnd.h[hdb](.mrvs.hdb.lastBySym;tab;.z.d-1)}[srv]each .rp.cfg.srcTabs;
    ];
  //init without hdb - empty tables
  :{[tab] tab set update`u#sym from select by sym from .rp.cfg.model[tab]}each .rp.cfg.srcTabs;
  };

//----------------------------------------------------------------------------//
/F/ Helper function to be executed on hdb server - retrieving the mrvs for specified day
/P/ tabs:LIST SYMBOL - list of table names
/P/ day:DATE - date in hdb which should be used for query
.mrvs.hdb.lastBySym:{[tabs;day]
  select by sym from tab where date=day
  };
//----------------------------------------------------------------------------//
/F/ simply upsert the data to proper table
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
.rp.plug.upd:upsert;
//----------------------------------------------------------------------------//
