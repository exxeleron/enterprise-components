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

/S/ rproc - realtime processing component
/S/ Full description in components/rproc/README.md

//----------------------------------------------------------------------------//
//                  default empty plugin implementation                       //
//----------------------------------------------------------------------------//
/F/ Default empty implementation of the init plugin.
/F/ It is invoked during component initialization. 
/F/ The role of this callback is to initialize the data model and optionally 
/F/ insert start-up content for each `derived table` in the `rproc` component.
/F/ It is invoked `after` opening of the connection to the `cfg.serverAux` servers.
/P/ srv:LIST SYMBOL - list of auxiliary servers (see cfg.serverAux
/R/ no expectations for the result - not used
.rp.plug.init:{[srv]};

/F/ Default empty implementation of the upd plugin.
/F/ It is invoked on each data receive from `tickHF` process. 
/F/ The role of this callback is to calculate `derived data` 
/F/ based on the `source data update`. This callback is the essential element 
/F/ of the implementation as it actually defines the logic for data processing.
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
/R/ no expectations for the result - not used
.rp.plug.upd:{[tab;data]};

/F/ Default empty implementation of the end plugin.
/F/ Plug-in `.rp.plug.end[day]` is invoked on at end of day (triggered by the `tickHF`). 
/F/ May be used for day wrap-up actions, e.g. memory clearing.
/P/ day:DATE - day that just have ended
/R/ no expectations for the result - not used
.rp.plug.end:{[day]};

//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`rproc];
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/sub"];
.sl.lib["qsl/u"];
//----------------------------------------------------------------------------//
/F/ initialize rproc component - invoked at the end of this file
/F/ - load tickLF default callbacks
/F/ - load custom libraries
/F/ - open connection to the servers from cfg.serverAux
/F/ - invoke .rp.plug.init[] plugin function
/F/ - initialize publishing library qsl/u
.rp.init:{[]
  .sub.initCallbacks[`PROTOCOL_TICKLF];
  .sl.libCmd[];
  //read configuration
  .rp.cfg.serverAux:.cr.getCfgField[`THIS;`group;`cfg.serverAux];
  .rp.cfg.timeout:.cr.getCfgField[`THIS;`group;`cfg.timeout];
  model:.cr.getModel[`THIS];
  if[model~();'"rproc process must be subscribed to at least one table"];
  .rp.cfg.model:(!) . flip model;
  .rp.cfg.srcTabs:exec sectionVal from .cr.getCfgTab[`THIS;`table;`subSrc] where not null finalValue;
  //open the serverAux conn immediately
  .hnd.hopen[.rp.cfg.serverAux;.rp.cfg.timeout;`eager];
  .event.at[`rproc;`.rp.plug.init;.rp.cfg.serverAux;`;`info`info`error;"executing plugin initialization - .rp.plug.init[]"];
  //initialize publishing
  .u.init[];
  };

//----------------------------------------------------------------------------//
//                           tickHF subscription                              //
//----------------------------------------------------------------------------//
/F/ empty tickHF sub callback
/P/ server:SYMBOL - src server
/P/ schema:LIST - data model of subscribed tables
sub:{[server;schema] };

//----------------------------------------------------------------------------//
/F/the callback for the real time updates
/F/ - invoking .rp.plug.upd[] plugin function
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
upd:{[tab;data] .rp.plug.upd[tab;data]};

//----------------------------------------------------------------------------//
/F/ the data from the journal used only for initialization of in memory state
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
jUpd:{[tab;data] 
  if[tab in key .rp.cfg.model;
    upd[tab;flip (cols .rp.cfg.model[tab])!data];
    ];
  };

//----------------------------------------------------------------------------//
/F/ eod callback from tickHF
/P/ day:DATE - day that just have ended
.u.end:{[day]
  .rp.plug.end[day]
  };

//----------------------------------------------------------------------------//
//                            4. run app                                      //
//----------------------------------------------------------------------------//
.sl.run[`rproc; `.rp.init; `];
//----------------------------------------------------------------------------//
