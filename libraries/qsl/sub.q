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

/S/ Subscription management library:
/S/ Allows subscription to one of the for subscription to data published in tickLF (<tickLF.q>) or tickHF (<tickHF.q>) protocols

/S/ Features:
/S/ - subscribe
/S/ - replay the data
/S/ - check the subscription status

/------------------------------------------------------------------------------/
.sl.lib["qsl/sub_tickHF"];
.sl.lib["qsl/sub_tickLF"];
.sl.lib["qsl/sub_dist"];

/------------------------------------------------------------------------------/
/                                    globals                                   /
/------------------------------------------------------------------------------/
/G/ Supported protocols and subscription libraries and functions
.sub.p.protocols:([protocol:`PROTOCOL_TICKHF`PROTOCOL_TICKLF`PROTOCOL_DIST]
  callbacks:`.sub.tickHF.default`.sub.tickLF.default`.sub.dist.default;
  loaded:0b);

//----------------------------------------------------------------------------//
/F/ Initialize subscription library
/F/ - initialization of connection to the source server
/F/ - subscription to requested tables/sectors on connection open
/P/ subCfg:TABLE - table with subscription configuration
/E/.sub.init[subCfg:.sub.cfg.subCfg]
.sub.init:{[subCfg]
  if[0=count subCfg;:()];
  .sub.cfg.timeout:500i;
  .sub.tabs:1!select tab, name:?[null subNs;tab;(` sv/: subNs,'tab)], subNs, subList, subSrc, subPredefineCallbacks, subProtocol:`, whr:count[i]#(), grp:0b, cnd:subCols!'subCols from subCfg;
  .sub.src:exec distinct subSrc from subCfg;
  //activate callback in hnd library
  .hnd.poAdd[;`.sub.p.po]each .sub.src;
  };

//----------------------------------------------------------------------------//
/F/ Subscription status.
/R/ table with current subscription status
/E/ .sub.status[]
.sub.status:{[] 
  select tab, name, src:subSrc, subProtocol, srcConn:(exec server!state from .hnd.status)subSrc, rowsCnt:@[{count value x};;0Nj]'[tab] from .sub.tabs
  };

//----------------------------------------------------------------------------//
/F/open connection to the source servers. Subscription will happen automatically after hopen
.sub.hopenSrc:{[]
  if[not `src in key .sub;:()];
  .hnd.hopen[; .sub.cfg.timeout; `eager] each .sub.src;
  };

/------------------------------------------------------------------------------/
/F/ get subscription protocol, one of PROTOCOL_TICKHF, PROTOCOL_TICKLF or PROTOCOL_DIST
.sub.p.getSubProtocol:{[src]
  :.hnd.h[src]".sl.getSubProtocols[]";
  };

//----------------------------------------------------------------------------//
/F/ Port open (po) callback invoked once the connection to any of the source servers is established.
/F/ Initiates subscription to the server
//src :`admin.monitor
//src :`in.tickHF
.sub.p.po:{[src]
  subProtocol:.pe.atLog[`sub;`.sub.p.getSubProtocol;src;`;`error];
  if[`error~subProtocol;
    .log.warn[`sub]"Source server ", string[src], " does not have .sl.getSubProtocols[] function defined (see qsl/sl.q). - using default protocol `PROTOCOL_TICKHF";
    subProtocol:enlist`PROTOCOL_TICKHF;
    ];
  if[0=count subProtocol;
    .log.error[`sub]"Source server ", string[src], " have no default subscription protocols defined in .sl.getSubProtocols[] function (see qsl/sl.q).";
    :();
    ];
  supported:subProtocol inter exec protocol from .sub.p.protocols;
  if[0=count supported;
    .log.error[`sub]"Source server ", string[src], " have supports only following protocols:",.Q.s1[subProtocol]," defined in .sl.getSubProtocols[] function (see qsl/sl.q). qsl/sub library supports follwoing protocols ", .Q.s1[exec protocol from .sub.p.protocols];
    :();
    ];
  prot:first supported;
  .sub.tabs:update subProtocol:prot from .sub.tabs where subSrc=src;
  toSub:select from .sub.tabs where subSrc=src;

  .sub.p.predefineCb:exec subPredefineCallbacks by subProtocol from .sub.tabs where not null subProtocol;
  if[all .sub.p.predefineCb[prot];
    .event.at[`sub;`.sub.initCallbacks;prot;`;`debug`debug`error;"Initializing callbacks for ",string[prot]];
    ];
  .event.dot[`sub;`.sub.p.sub;(prot;toSub);`;`debug`debug`error;"Subscribing to server:",string[src],", tables:",.Q.s1[exec tab from toSub]];
  
  };

//----------------------------------------------------------------------------//
.sub.p.sub:{[prot;toSub]
  if[prot~`PROTOCOL_TICKHF;
    :.sub.tickHF.subscribe[server:exec first subSrc from toSub;tabs:exec tab from toSub;uni:`];
    ];
  if[prot~`PROTOCOL_TICKLF;
    :.sub.tickLF.subscribe[server:exec first subSrc from toSub;tabs:exec tab from toSub;uni:`];
    ];
  if[prot~`PROTOCOL_DIST;
    .sub.dist.subscribe[server:exec first subSrc from toSub];
    ];
   };

//----------------------------------------------------------------------------//
/F/ Initialize callbacks for subscription protocol with default implementation.
/F/ See qsl/sub_tickLF.q, qsl/sub_tickHF.q and qsl/sub_dist.q scripts for default implementation.
/P/ protocol - one of `PROTOCOL_TICKHF`PROTOCOL_TICKLF`PROTOCOL_DIST
.sub.initCallbacks:{[protocol]
  cb:value .sub.p.protocols[protocol]`callbacks;
  .log.info[`sub] "Initializing ", string[protocol], "callbacks for :", .Q.s1[key cb];
  key[cb] set' value[cb];  
  };

//----------------------------------------------------------------------------//
/F/ read initial configuration
.sub.readCfg:{[]
  .sub.cfg.subCfg:1!`tab xcol 0!select from .cr.getCfgPivot[`THIS;`table`sysTable;`subSrc`subNs`subCols`subList`subPredefineCallbacks] where not null subSrc;
  .sub.cfg.autoSubscribe:.cr.getCfgField[`THIS;`group;`subAutoSubscribe];
  };

/==============================================================================/
/
.hnd.hclose src
.hnd.status
.cb.status
.sub.status[]
.sub.tabs
upd
.store.status[]

.sub.p.po src:`admin.monitor
.hnd.status
.stats.p.fxQuote
jUpd
upd
sub
\a
fxQuoteSnap