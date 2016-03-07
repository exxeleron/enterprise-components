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

/S/ Subscription management library:
/-/ Allows subscription to one of the for subscription to data published in tickLF (<tickLF.q>) or tickHF (<tickHF.q>) protocols

/-/ Features:
/-/ - subscribe
/-/ - replay the data
/-/ - check the subscription status

/------------------------------------------------------------------------------/
.sl.lib["qsl/sub_tickHF"];
.sl.lib["qsl/sub_tickLF"];
.sl.lib["qsl/sub_dist"];

/------------------------------------------------------------------------------/
/                                    globals                                   /
/------------------------------------------------------------------------------/
/G/ Supported protocols and subscription libraries and functions.
.sub.p.protocols:([protocol:`PROTOCOL_TICKHF`PROTOCOL_TICKLF`PROTOCOL_DIST]
  callbacks:`.sub.tickHF.default`.sub.tickLF.default`.sub.dist.default;
  loaded:0b);

//----------------------------------------------------------------------------//
//                          interface functions                               //
//----------------------------------------------------------------------------//
/F/ Initializes subscription library. Automatically invoked in .sl.run[] on process startup.
/-/   - initialization of connection to the source server
/-/   - subscription to requested tables/sectors on connection open
/-/ Note: system.cfg subAutoSubscribe configuration field must be set to 0b, 
/-/       in order to be able to perform custom .sub.init[] call.
/P/ subCfg:TABLE - table with subscription configuration
/R/ no return value
/E/ .sub.init[.sub.cfg.subCfg]
.sub.init:{[subCfg]
  if[0=count subCfg;:()];
  /G/ Timeout for the opening of the connection to the source servers.
  .sub.cfg.timeout:500i;
  /G/ Table with information about all subscriptions.
  /-/  -- tab:SYMBOL                    - subscribed table name
  /-/  -- name:SYMBOL                   - in-mem table name (by default the same as tab)
  /-/  -- subNs:SYMBOL                  - namespace in which subscribed tables should exist, the default is global namespace.
  /-/  -- subList:LIST SYMBOL           - list of instruments to subscribe or `ALL to subscribe all instruments
  /-/  -- subSrc:SYMBOL                 - subscription source server
  /-/  -- subPredefineCallbacks:BOOLEAN - if TRUE, default callbacks will be defined directly before subscription, it will overwrite any existing callback content.
  /-/  -- subProtocol:SYMBOL            - subscription protocol, one of PROTOCOL_TICKHF, PROTOCOL_TICKLF, PROTOCOL_DIST
  /-/  -- whr:LIST                      - list of conditions used on received data - allows keeping only a subset of incomming data rows
  /-/  -- grp:BOOLEAN                   - groupping condition - allows keeping only an aggregation of incomming data rows
  /-/  -- cnd:DICTIONARY                - sublist of columns - allows keeping only a subset of incomming data columns
  .sub.tabs:1!select tab, name:?[null subNs;tab;(` sv/: subNs,'tab)], subNs, subList, subSrc, subPredefineCallbacks, subProtocol:`, whr:count[i]#(), grp:0b, cnd:subCols!'subCols from subCfg;
  /G/ List of all source servers.
  .sub.src:exec distinct subSrc from subCfg;
  //activate callback in hnd library
  .hnd.poAdd[;`.sub.p.po]each .sub.src;
  };

//----------------------------------------------------------------------------//
/F/ Returns actual subscription status.
/R/ :TABLE - table with current subscription status
/-/   -- tab:SYMBOL         - subscribed table name
/-/   -- name:SYMBOL        - in-mem table name (by default the same as tab)
/-/   -- subProtocol:SYMBOL - subscription protocol, one of `PROTOCOL_TICKHF`PROTOCOL_TICKLF`PROTOCOL_DIST
/-/   -- srcConn:SYMBOL     - state of the source server, one of `registered`open`closed`failed`lost
/-/   -- tab:SYMBOL         - subscribed table name
/-/   -- rowsCnt:LONG       - number of rows currently in memory
/E/ .sub.status[]
.sub.status:{[] 
  select tab, name, src:subSrc, subProtocol, srcConn:(exec server!state from .hnd.status)subSrc, rowsCnt:@[{count value x};;0Nj]'[tab] from .sub.tabs
  };

//----------------------------------------------------------------------------//
/F/ Opens connection to the source servers. Automatically invoked in .sl.run[] on process startup.
/-/ Subscription will happen automatically after hopen.
/-/ Source servers are extracted from global variable .sub.src.
/R/ no return value
/E/ .sub.hopenSrc[]
.sub.hopenSrc:{[]
  if[not `src in key .sub;:()];
  .hnd.hopen[; .sub.cfg.timeout; `eager] each .sub.src;
  };

//----------------------------------------------------------------------------//
//                          private functions                                 //
//----------------------------------------------------------------------------//
/F/ Get subscription protocol from the source server.
/-/ One of PROTOCOL_TICKHF, PROTOCOL_TICKLF or PROTOCOL_DIST.
/P/ src:SYMBOL - source component name
/R/ :ENUM[`PROTOCOL_TICKHF`PROTOCOL_TICKLF`PROTOCOL_DIST]
.sub.p.getSubProtocol:{[src]
  :.hnd.h[src]".sl.getSubProtocols[]";
  };

//----------------------------------------------------------------------------//
/F/ Port open (po) callback invoked once the connection to any of the source servers is established.
/-/ Initiates subscription to the server.
/P/ src:SYMBOL - source component name
/E/ .sub.p.po`admin.monitor
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
//               functions for automatic subscription handling                //
//----------------------------------------------------------------------------//
/F/ Initializes subscription callbacks with default implementation. Automatically executed on source server port open.
/-/ Note: How to define custom subscription callbacks:
/-/      - set dataflow.cfg configuration field subPredefineCallbacks to FALSE 
/-/        (otherwise the callbacks will be restored from default values automatically on port open)
/-/      - define callbacks in the custom code and load it with system.cfg lib configuration field
/-/ Default callbacks implementation can be found in:
/-/      - PROTOCOL_TICKHF - qsl/sub_tickHF.q file, .sub.tickHF.default dictionary
/-/      - PROTOCOL_TICKLF - qsl/sub_tickLF.q file, .sub.tickLF.default dictionary
/-/      - PROTOCOL_DIST   - qsl/sub_dist.q file,   .sub.dist.default dictionary
/P/ protocol:SYMBOL - subscription protocol name, one of `PROTOCOL_TICKHF`PROTOCOL_TICKLF`PROTOCOL_DIST
/R/ no return value
/E/ .sub.initCallbacks[`PROTOCOL_TICKHF]
/-/   - all callbacks for the PROTOCOL_TICKHF are reset to default implementation
.sub.initCallbacks:{[protocol]
  cb:value .sub.p.protocols[protocol]`callbacks;
  .log.info[`sub] "Initializing ", string[protocol], " callbacks for: ", .Q.s1[key cb];
  key[cb] set' value[cb];  
  };

//----------------------------------------------------------------------------//
/F/ Reads initial subscription configuration.
/R/ no return value
/E/ .sub.readCfg[]
.sub.readCfg:{[]
  /G/ Table with configuration for subscription extracted from the dataflow.cfg, activated only if .sub.cfg.autoSubscribe is 1b.
  .sub.cfg.subCfg:1!`tab xcol 0!select from .cr.getCfgPivot[`THIS;`table`sysTable;`subSrc`subNs`subCols`subList`subPredefineCallbacks] where not null subSrc;
  /G/ Boolean responsible for automatic subscription based on dataflow.cfg.
  .sub.cfg.autoSubscribe:.cr.getCfgField[`THIS;`group;`subAutoSubscribe];
  };

/==============================================================================/
/
