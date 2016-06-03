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

/S/ rproc - realtime processing component
/-/ Full description in components/rproc/README.md

//----------------------------------------------------------------------------//
//                  default empty plugin implementation                       //
//----------------------------------------------------------------------------//
/F/ Init plugin, used for initialization of rproc plugin global variables. Invoked at rproc startup.
/-/ The role of this callback is to initialize the data model and optionally 
/-/ insert start-up content for each `derived table` in the `rproc` component.
/-/ It is invoked `after` opening of the connection to the `cfg.serverAux` servers.
/-/ Default implementation of the init plugin is an empty function.
/P/ srv:LIST SYMBOL - list of auxiliary servers (see cfg.serverAux)
/R/ no return value
/E/  .rp.plug.init[.rp.cfg.serverAux]
.rp.plug.init:{[srv]};

//----------------------------------------------------------------------------//
/F/ Update plugin, used for processing incomming data, invoked during journal replay and during real-time updates from tickHF.
/-/ The role of this callback is to calculate `derived data` based on the `source data update`. 
/-/ This callback is the essential element of the implementation as it actually defines the logic for data processing.
/-/ Default empty implementation of the upd plugin.
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
/R/ no return value
/E/  .rp.plug.upd[`trade;tradeData]
.rp.plug.upd:{[tab;data]};

//----------------------------------------------------------------------------//
/F/ Eod plugin, used for eod cleanup/rollover, invoked while receiving .u.end signal from tickHF.
/-/ May be used for day wrap-up actions, e.g. memory clearing.
/-/ Default empty implementation of the end plugin.
/P/ day:DATE - day that just have ended
/R/ no return value
/E/  .rp.plug.end[.z.d]
.rp.plug.end:{[day]};

//----------------------------------------------------------------------------//
//                          rproc impolementation                             //
//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`rproc];
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/sub"];
.sl.lib["qsl/u"];

//----------------------------------------------------------------------------//
/F/ Initializes rproc component - invoked at the end of this script.
/-/ - loads tickLF default callbacks
/-/ - loads custom libraries
/-/ - opens connection to the servers from cfg.serverAux
/-/ - invokes .rp.plug.init[] plugin function
/-/ - initializes publishing library qsl/u
/R/ no return value
/E/ .rp.init[]
.rp.init:{[]
  .sub.initCallbacks[`PROTOCOL_TICKLF];
  .sl.libCmd[];

  /G/ List of auxiliary servers, loaded from cfg.serverAux from system.cfg.
  .rp.cfg.serverAux:.cr.getCfgField[`THIS;`group;`cfg.serverAux];

  /G/ Connection timeout, loaded from cfg.timeout from system.cfg.
  .rp.cfg.timeout:.cr.getCfgField[`THIS;`group;`cfg.timeout];
  model:.cr.getModel[`THIS];
  if[model~();'"rproc process must be subscribed to at least one table"];

  /G/ Dictionary with the (table->data model) mapping, loaded from dataflow.cfg.
  .rp.cfg.model:(!) . flip model;

  /G/ List of source tables from tickHF source server, loaded from subSrc from dataflow.cfg.
  .rp.cfg.srcTabs:exec sectionVal from .cr.getCfgTab[`THIS;`table;`subSrc] where not null finalValue;

  //open the serverAux conn immediately
  .hnd.hopen[.rp.cfg.serverAux;.rp.cfg.timeout;`eager];
  .event.at[`rproc;`.rp.plug.init;.rp.cfg.serverAux;`;`info`info`error;"executing plugin initialization - .rp.plug.init[]"];
  //initialize publishing
  .u.init[];
  };

//----------------------------------------------------------------------------//
//                           tickHF subscription callbacks                    //
//----------------------------------------------------------------------------//
/F/ Callback with on tickHF subscription. Not used.
/P/ server:SYMBOL - src server
/P/ schema:LIST   - data model of subscribed tables
/R/ no return value
/E/  sub[`core.tickHF;schema]
sub:{[server;schema] };

//----------------------------------------------------------------------------//
/F/ Callback for real-time updates from tickHF. Executes .rp.plug.upd[] plugin.
/-/ - invoking .rp.plug.upd[] plugin function
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
/R/ no return value
/R/  upd[`trade;tradeData]
upd:{[tab;data] .rp.plug.upd[tab;data]};

//----------------------------------------------------------------------------//
/F/ Callback for journal updates from tickHF. Executes .rp.plug.upd[] plugin.
/-/ Used only for initialization of in-memory state.
/P/ tab:SYMBOL - table name
/P/ data:TABLE - record with the updates for tab
/R/ no return value
/E/  jUpd[`trade;tradeData]
jUpd:{[tab;data] 
  if[tab in key .rp.cfg.model;
    upd[tab;flip (cols .rp.cfg.model[tab])!data];
    ];
  };

//----------------------------------------------------------------------------//
/F/ Eod callback from tickHF. Executes .rp.plug.end[] plugin.
/P/ day:DATE - day that just have ended
/R/ no return value
/E/ .u.end .z.d
.u.end:{[day]
  .rp.plug.end[day]
  };

//----------------------------------------------------------------------------//
//                          initialization                                    //
//----------------------------------------------------------------------------//
.sl.run[`rproc; `.rp.init; `];

//----------------------------------------------------------------------------//
