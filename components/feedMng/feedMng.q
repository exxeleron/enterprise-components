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

/A/ DEVnet:  Joanna Jarmulska
/V/ 3.0
/S/ Feed management component:
/-/ Responsible for:
/-/ - basic universe management (division of the universe between multiple feeds)
/-/ - providing interface for subscription and un-subscription
/-/ 
/-/ Notes:
/-/ - universe is derived from the reference data received from tickLF (<tickLF.q>) component
/-/ - universe is distributed by the tickLF interface as sysUniverse table
/-/ - intraday updates of the sysUniverse can be modified only by the reference data and should be triggered from tickLF (<tickLF.q>)
/-/ - manual modification of the sysUniverse is not supported and can cause inconsistency of the universe inside the system
/-/ 
/-/ Workflow:
/-/ 1. - FeedMng on initialization replays current state of the sysUniverse using <.feedMng.plug.jrn[]> interface
/-/ 2. - Restored sysUniverse is cross-checked whether any actions are required to add/delete instruments
/-/ 3. - During run-time updates of the reference data are processed by plugins
/-/ 
/-/ Plugins:
/-/ Updates of the sysUniverse can be implemented through plugins, examples of plugins can be found in <pluginExample.q>
/-/ - receiving reference data during the day from tickLF
/-/ (start code)
/-/ .feedMng.plug.img[tabName][data] - data images
/-/ .feedMng.plug.upd[tabName][data] - data inserts
/-/ .feedMng.plug.ups[tabName][(data;constraints;bys;aggregates)] - data upserts
/-/ .feedMng.plug.del[tabName][(constraints;bys;aggregates)] - deletes
/-/ (end)
/-/ where
/-/ (start code)
/-/ tabName:SYMBOL - table name of the reference data, that is received form tickLF
/-/ data:TABLE - data
/-/ constraints:LIST GENERAL - list of constraints
/-/ bys:DICTIONARY - dictionary of group-bys
/-/ aggregates:DICTIONARY - dictionary of aggregates
/-/ (end)
/-/ - replay reference data on initialization, plugin to create latest sysUniverse from reference data restored from the journal file
/-/ (start code)
/-/ .feedMng.plug.jrn - return sysUniverse, takes no arguments
/-/ (end)

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";

.sl.init[`feedMng];

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/handle"];

/------------------------------------------------------------------------------/
/G/ Universe table that is distributed between multiple feeds by the tickLF component.
/-/  -- time:TIME               - timestamp at which sysUniverse was updated
/-/  -- sym:SYMBOL              - feed handler name (name should be consistent with <system.cfg>)
/-/  -- instrumentGroup:SYMBOL  - logical name of the instrument group
/-/  -- instrument:SYMBOL       - instrument name
/-/  -- subItem:SYMBOL          - name that will be used for subscription
sysUniverse:([]time:`time$(); sym:`symbol$(); instrumentGroup:`symbol$(); instrument:`symbol$();subItem:`symbol$());

/------------------------------------------------------------------------------/
/G/ Initial definition for handling images received from tickLF.
.feedMng.plug.img:(enlist `)!enlist (::);

/G/ Initial definition for handling inserts received from tickLF.
.feedMng.plug.upd:(enlist `)!enlist (::);

/G/ Initial definition for handling upserts received from tickLF.
.feedMng.plug.ups:(enlist `)!enlist (::);

/G/ Initial definition for handling deletes received from tickLF.
.feedMng.plug.del:(enlist `)!enlist (::);

/------------------------------------------------------------------------------/
/G/ Initial definition for handling reference data after recovery from journal file.
.feedMng.plug.jrn:{sysUniverse};

/------------------------------------------------------------------------------/
/G/ Function for receiving images, interface corresponds to <.tickLF.img[table;data]>.
.feedMng.load.img:.sub.tickLF.default[`.tickLF.img];

/G/ Function for receiving upserts, interface corresponds to <.tickLF.ups[table;data;c;b;a]>.
.feedMng.load.ups:.sub.tickLF.default[`.tickLF.ups];

/G/ Function for receiving updates, interface corresponds to <.tickLF.upd[table;data]>.
.feedMng.load.upd:.sub.tickLF.default[`.tickLF.upd];

/G/ Function for receiving deletes, interface corresponds to <.tickLF.del[table;c;b;a]>.
.feedMng.load.del:.sub.tickLF.default[`.tickLF.del];

/------------------------------------------------------------------------------/
/G/ Default callback for journal replay of img message from tickLF.
.tickLF.jImg:.sub.tickLF.default[`.tickLF.jImg];

/G/ Default callback for journal replay of ups message from tickLF.
.tickLF.jUps:.sub.tickLF.default[`.tickLF.jUps];

/G/ Default callback for journal replay of upd message from tickLF.
.tickLF.jUpd:.sub.tickLF.default[`.tickLF.jUpd];

/G/ Default callback for journal replay of del message from tickLF.
.tickLF.jDel:.sub.tickLF.default[`.tickLF.jDel];

/------------------------------------------------------------------------------/
/F/ Subscribes given new instruments. It will send asynchronously sysUniverse update message to tickLF (<.tickLF.pubUpd>).
/P/ data:TABLE - table with new instruments to subscribe, model should match sysUniverse
/R/ no return value
/E/ .feedMng.upd[([] time:(.z.t;.z.t); sym:`rtr.feed1`rtr.feed2; instrumentGroup:`Share`Share; instrument:`sym1`sym2)]
.feedMng.upd:{[data]
  .log.debug[`feedMng] "Perform .feedMng.upd for #data:", string count data;
  if[not (delete a from meta[data])~delete a from meta[sysUniverse]; '`$"Data that is passed to .feedMng.upd doesn't match sysUniverse schema"];
  {.log.info[`feedMng] "Distribute subscription to ",string[first x], " for #instruments:", string[first y]}.'flip value flip 0!select count i by sym from data;
  .tickLF.upd[`sysUniverse; value flip data];
  .hnd.ah[.feedMng.serverDst](`.tickLF.pubUpd;`sysUniverse; value flip data);
  .log.debug[`feedMng] ".feedMng.upd completed";
  };

/------------------------------------------------------------------------------/
/F/ Un-subscribes given instruments. It will send asynchronously sysUniverse delete message to tickLF (<.tickLF.pubDel[t;c;b;a]>).
/P/ data:TABLE - table with instruments that should be un-subscribed, model should match sysUniverse
/R/ no return value
/E/ .feedMng.del[([] time:(.z.t;.z.t); sym:`rtr.feed1`rtr.feed2; instrumentGroup:`Share`Share; instrument:`sym1`sym2)]
.feedMng.del:{[data]
  .log.debug[`feedMng] "Perform .feedMng.del for #data:", string count data;
  d:exec sym, instrument from data;
  {.log.info[`feedMng] "Distribute un-subscription to ",string[first x], " for #instruments:", string[first y]}.'flip value flip 0!select count i by sym from data;
  if[not (delete a from meta[data])~delete a from meta[sysUniverse]; '`$"Data that is passed to .feedMng.del doesn't match sysUniverse schema"];
  //parse "delete from universe where sym in `a`b, instrument in `a`b"
  whereClause:enlist(in;((';,);`sym;`instrument);enlist (d[`sym],'d[`instrument]));
  .tickLF.del[`sysUniverse;whereClause;0b;0#`];
  .hnd.ah[.feedMng.serverDst](`.tickLF.pubDel;`sysUniverse;whereClause;0b;0#`);
  .log.debug[`feedMng] ".feedMng.del completed";
  }; 

/------------------------------------------------------------------------------/
.feedMng.p.init:{[]
  .feedMng.serverDst:.feedMng.cfg.tables[`sysUniverse][`subSrc];
  //TODO: decide on columns
  .feedMng.cfg.sub:select tab:sectionVal, subSrc, subNs:`, subCols:count[i]#enlist`symbol$(), subList:`ALL, subPredefineCallbacks:0b from .feedMng.cfg.tables;
  .sub.init[.feedMng.cfg.sub];

  server2conn:exec distinct subSrc from .feedMng.cfg.tables;
  .hnd.poAdd'[server2conn;`.feedMng.p.poPlugin];
  server2conn:distinct (server2conn, .feedMng.cfg.serverAux,.feedMng.serverDst) except `;
  .hnd.hopen[server2conn;.feedMng.cfg.timeout;`eager];
  };

/------------------------------------------------------------------------------/
.feedMng.p.poPlugin:{[]
  .event.at[`feedMng;`.feedMng.p.recreateSysUniFromJrn;();();`info`info`error;"Perform recover of the sysUniverse from the journal file"];
  };

/------------------------------------------------------------------------------/
.feedMng.p.recreateSysUniFromJrn:{[]
  .log.info[`feedMng]"Perform .feedMng.plug.jrn";
  new:.feedMng.plug.jrn[];
  .log.debug[`feedMng]".feedMng.plug.jrn completed";
  if[not (delete a from meta[new])~delete a from meta[sysUniverse]; '`$"Meta of the created .feedMng.plug.jrn is not matching sysUniverse"];
  //compare with sysUniverse loaded from memory
  uni:.feedMng.compareUni[sysUniverse;new];
  if[all (count'[uni]) in 0;.log.info[`feedMng]"There is no update to the sysUniverse after data replay"];
  if[count  uni`del;.feedMng.del[`time xcols update time:.sl.zt[] from uni`del]];
  if[count  uni`upd;.feedMng.upd[`time xcols update time:.sl.zt[] from uni`upd]];
  };

/------------------------------------------------------------------------------/    
/F/ Compares two tables with universes.
/P/ old:TABLE - table with old sysUniverse
/P/ new:TABLE - table with new sysUniverse
/R/ DICTIONARY `upd`del!(TABLE;TABLE) - table with universe that can be called by <.feedMng.upd[data]> or <.feedMng.del[data]>
/E/ .feedMng.compareUni[sysUniverse;new]
.feedMng.compareUni:{[old;new]
  newSym:select newInstr:instrument,newItem:subItem, newGr:instrumentGroup by sym from new;
  oldSym:select oldInstr:instrument,oldItem:subItem, oldGr:instrumentGroup  by sym from old;
  join:lj/[(([] sym:distinct (exec sym from new), exec sym from old);newSym;oldSym)];
  `upd`del!(ungroup select sym, instrumentGroup:newGr@'(where'[ not newInstr in' oldInstr]), instrument:(newInstr except' oldInstr), subItem:newItem@'(where'[ not newInstr in' oldInstr]) from join;
    ungroup select sym, instrumentGroup:oldGr@'(where'[ not oldInstr in' newInstr]), instrument:(oldInstr except' newInstr), subItem:oldItem@'(where'[ not oldInstr in' newInstr]) from join)
  };

/------------------------------------------------------------------------------/
/                          tickLF callbacks                                    /
/------------------------------------------------------------------------------/
/F/ TickLF callback function for receiving intra-day images.
/-/   - interface corresponds to .tickLF.img
/-/   - previous data is kept in .feedMng.prev.[table]
/-/   - applies image in the memory
/-/   - performs .feedMng.plug.img
/P/ table:SYMBOL - table name
/P/ data:DATA    - image data
/R/ no return value
/E/ .tickLF.img[`universe;universeImg]
.tickLF.img:{[table;data]
  (` sv `.feedMng.prev,table) set value[table];
  .feedMng.load.img[table;data];
  .feedMng.plug.img[table;data];
  };

/------------------------------------------------------------------------------/
/F/ TickLF callback function for receiving intra-day updates.
/-/   - interface corresponds to .tickLF.upd
/-/   - previous data is kept in .feedMng.prev.[table]
/-/   - applies insert in the memory
/-/   - performs .feedMng.plug.upd
/P/ table:SYMBOL - table name
/P/ data:DATA    - update data
/R/ no return value
/E/ .tickLF.img[`universe;universeUpd]
.tickLF.upd:{[table;data]
  (` sv `.feedMng.prev,table) set value[table];
  .feedMng.load.upd[table;data];
  .feedMng.plug.upd[table;data];
  };

/------------------------------------------------------------------------------/
/F/ TickLF callback function for receiving intra-day upserts.
/-/   - interface corresponds to .tickLF.ups
/-/   - previous data is kept in .feedMng.prev.[table]
/-/   - applies upsert in the memory
/-/   - performs .feedMng.plug.ups
/P/ table:SYMBOL - table name
/P/ data:DATA    - upsert data
/P/ c:LIST       - list of constraints   
/P/ b:DICTIONARY - dictionary of group-bys
/P/ a:DICTIONARY - dictionary of aggregates
/R/ no return value
/E/ .tickLF.ups[`universe;data;c;b;a]
.tickLF.ups:{[table;data;c;b;a]
  (` sv `.feedMng.prev,table) set value[table];
  .feedMng.load.ups[table;data;c;b;a];
  .feedMng.plug.ups[table;(data;c;b;a)];
  };

/------------------------------------------------------------------------------/
/F/ TickLF callback function for receiving intra-day deletes.
/-/   - interface corresponds to .tickLF.del
/-/   - previous data is kept in .feedMng.prev.[table]
/-/   - applies deletes in the memory
/-/   - performs .feedMng.plug.del
/P/ table:SYMBOL - table name
/P/ c:LIST       - list of constraints   
/P/ b:DICTIONARY - dictionary of group-bys
/P/ a:DICTIONARY - dictionary of aggregates
/R/ no return value
/E/ .tickLF.del[`universe;c;b;a]
.tickLF.del:{[table;c;b;a]
  (` sv `.feedMng.prev,table) set value[table];
  .feedMng.load.del[table;c;b;a];
  .feedMng.plug.del[table;(c;b;a)];
  };

/==============================================================================/
/F/ Component initialization entry point.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]
  /G/ List of universe source servers for each table, loaded from cfg.subScr field from dataflow.cfg.
  .feedMng.cfg.tables:             .cr.getCfgPivot[`THIS;`table`sysTable;enlist`subSrc];
  /G/ Connection opening timeout, loaded from cfg.timeout field from system.cfg.
  .feedMng.cfg.timeout:            .cr.getCfgField[`THIS;`group;`cfg.timeout];
  /G/ List of auxliary serers required during universe management custom procedures, loaded from cfg.serverAux field from system.cfg.
  .feedMng.cfg.serverAux:          .cr.getCfgField[`THIS;`group;`cfg.serverAux];
  .sl.libCmd[];
  .feedMng.p.init[];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`feedMng;`.sl.main;`];

/------------------------------------------------------------------------------/
\

/
