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

/A/ DEVnet: Joanna Wdowiak
/V/ 3.1

/S/ snap server - x minute snapshot plugin for rproc component
/S/ keeps X-minute snapshots in the memory
/S/ for each table different snapshot interval can be configured
/S/ Full description in components/rproc/README.md

//----------------------------------------------------------------------------//
/F/ initialize data model for snapshots - keyed by x minute/sym
/F/ load snapshot interval for each table
/P/ srv:LIST SYMBOL - not used
.rp.plug.init:{[srv];
  .rp.cfg.snapMinuteInterval:exec sectionVal!finalValue from .cr.getCfgTab[`THIS;`table`sysTable;`snapMinuteInterval]; 
  :{[tab] tab set update`g#sym from select by  .rp.cfg.snapMinuteInterval[tab] xbar time.minute, sym from .rp.cfg.model[tab]}each .rp.cfg.srcTabs;
  };

//----------------------------------------------------------------------------//
/F/ upsert by minute/sym
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
.rp.plug.upd:{[tab;data]
  tab upsert select by .rp.cfg.snapMinuteInterval[tab] xbar time.minute, sym from data
  };

//----------------------------------------------------------------------------//
/F/ Clear the in-memory tables at the end of day. 
/F/ Process is designed to keep only one day.
/P/ day:DATE - day that just have ended
.rp.plug.end:{[day]
  {update`g#sym from delete from x}each .rp.cfg.srcTabs;
  };
//----------------------------------------------------------------------------//
