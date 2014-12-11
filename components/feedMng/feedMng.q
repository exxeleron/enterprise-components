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

/A/ DEVnet:  Joanna Jarmulska
/V/ 3.0
/S/ Feed management component:
/S/ Responsible for:
/S/ - basic universe management (division of the universe between multiple feeds)
/S/ - providing interface for subscription and un-subscription
/S/ 
/S/ Notes:
/S/ - universe is derived from the reference data received from tickLF (<tickLF.q>) component
/S/ - universe is distributed by the tickLF interface as sysUniverse table
/S/ - intraday updates of the sysUniverse can be modified only by the reference data and should be triggered from tickLF (<tickLF.q>)
/S/ - manual modification of the sysUniverse is not supported and can cause inconsistency of the universe inside the system
/S/ 
/S/ Workflow:
/S/ 1. - FeedMng on initialization replays current state of the sysUniverse using <.feedMng.plug.jrn[]> interface
/S/ 2. - Restored sysUniverse is cross-checked whether any actions are required to add/delete instruments
/S/ 3. - During run-time updates of the reference data are processed by plugins
/S/ 
/S/ Plugins:
/S/ Updates of the sysUniverse can be implemented through plugins, examples of plugins can be found in <pluginExample.q>
/S/ - receiving reference data during the day from tickLF
/S/ (start code)
/S/ .feedMng.plug.img[tabName][data] - data images
/S/ .feedMng.plug.upd[tabName][data] - data inserts
/S/ .feedMng.plug.ups[tabName][(data;constraints;bys;aggregates)] - data upserts
/S/ .feedMng.plug.del[tabName][(constraints;bys;aggregates)] - deletes
/S/ (end)
/S/ where
/S/ (start code)
/S/ tabName:SYMBOL - table name of the reference data, that is received form tickLF
/S/ data:TABLE - data
/S/ constraints:LIST GENERAL - list of constraints
/S/ bys:DICTIONARY - dictionary of group-bys
/S/ aggregates:DICTIONARY - dictionary of aggregates
/S/ (end)
/S/ - replay reference data on initialization, plugin to create latest sysUniverse from reference data restored from the journal file
/S/ (start code)
/S/ .feedMng.plug.jrn - return sysUniverse, takes no arguments
/S/ (end)
/S/ 
/T/ q feedMng.q 

system"l ",getenv[`EC_QSL_PATH],"/sl.q";

.sl.init[`feedMng];

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/handle"];

/G/ universe that is distributed between multiple feeds by the tickLF component
/P/ time:TIME           - timestamp at which sysUniverse was updated
/P/ sym:SYMBOL          - feed handler name (name should be consistent with <system.cfg>)
/P/ instrumentGroup:SYMBOL  - logical name of the instrument group
/P/ instrument:SYMBOL       - instrument name
/P/ subItem:SYMBOL          - name that will be used for subscription
sysUniverse:([]  time:`time$(); sym:`symbol$(); instrumentGroup:`symbol$(); instrument:`symbol$();subItem:`symbol$());


/G/ initial definition for handling images received from tickLF
.feedMng.plug.img:(enlist `)!enlist (::);
/G/ initial definition for handling inserts received from tickLF
.feedMng.plug.upd:(enlist `)!enlist (::);
/G/ initial definition for handling upserts received from tickLF
.feedMng.plug.ups:(enlist `)!enlist (::);
/G/ initial definition for handling deletes received from tickLF
.feedMng.plug.del:(enlist `)!enlist (::);

/G/ initial definition for handling reference data after recovery from journal file
.feedMng.plug.jrn:{sysUniverse};

/------------------------------------------------------------------------------/
/G/ function for receiving images, interface corresponds to <.tickLF.img[table;data]>
.feedMng.load.img:.sub.tickLF.default[`.tickLF.img];
/G/ function for receiving upserts, interface corresponds to <.tickLF.ups[table;data;c;b;a]>
.feedMng.load.ups:.sub.tickLF.default[`.tickLF.ups];
/G/ function for receiving updates, interface corresponds to <.tickLF.upd[table;data]>
.feedMng.load.upd:.sub.tickLF.default[`.tickLF.upd];
/G/ function for receiving deletes, interface corresponds to <.tickLF.del[table;c;b;a]>
.feedMng.load.del:.sub.tickLF.default[`.tickLF.del];

/------------------------------------------------------------------------------/
/G/ default callback for journal replay of img message from tickLF
.tickLF.jImg:.sub.tickLF.default[`.tickLF.jImg];
/G/ default callback for journal replay of ups message from tickLF
.tickLF.jUps:.sub.tickLF.default[`.tickLF.jUps];
/G/ default callback for journal replay of upd message from tickLF
.tickLF.jUpd:.sub.tickLF.default[`.tickLF.jUpd];
/G/ default callback for journal replay of del message from tickLF
.tickLF.jDel:.sub.tickLF.default[`.tickLF.jDel];

/------------------------------------------------------------------------------/
/F/ subscription to new universe; it will send asynchronously sysUniverse update message to tickLF (<.tickLF.pubUpd>).
/P/ data:TABLE - table with new instruments to subscribe, model should match sysUniverse
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
/F/ un-subscription to new universe; it will send asynchronously sysUniverse delete message to tickLF (<.tickLF.pubDel[t;c;b;a]>).
/P/ data:TABLE - table with instruments that should be un-subscribed, model should match sysUniverse
/E/ .feedMng.del[([] time:(.z.t;.z.t); sym:`rtr.feed1`rtr.feed2; instrumentGroup:`Share`Share; instrument:`sym1`sym2)]
//data:`time xcols update time:.z.t from uni`del
//data:ddd
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
// .hnd.hclose[enlist `kdb.tickLF]

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
/F/ compare two tables with universes
/P/ old:TABLE - table with old sysUniverse
/P/ new:TABLE - table with new sysUniverse
/R/ DICTIONARY `upd`del!(TABLE;TABLE) - table with universe that can be called by <.feedMng.upd[data]> or <.feedMng.del[data]>
.feedMng.compareUni:{[old;new]
  newSym:select newInstr:instrument,newItem:subItem, newGr:instrumentGroup by sym from new;
  oldSym:select oldInstr:instrument,oldItem:subItem, oldGr:instrumentGroup  by sym from old;
  join:lj/[(([] sym:distinct (exec sym from new), exec sym from old);newSym;oldSym)];
  `upd`del!(ungroup select sym, instrumentGroup:newGr@'(where'[ not newInstr in' oldInstr]), instrument:(newInstr except' oldInstr), subItem:newItem@'(where'[ not newInstr in' oldInstr]) from join;
    ungroup select sym, instrumentGroup:oldGr@'(where'[ not oldInstr in' newInstr]), instrument:(oldInstr except' newInstr), subItem:oldItem@'(where'[ not oldInstr in' newInstr]) from join)
  };



/------------------------------------------------------------------------------/
/F/ function for receiving intra-day images
/F/ - interface corresponds to .tickLF.img
/F/ - previous data is kept in .feedMng.prev.[table]
/F/ - applies image in the memory
/F/ - performs .feedMng.plug.img
.tickLF.img:{[table;data]
  (` sv `.feedMng.prev,table) set value[table];
  .feedMng.load.img[table;data];
  .feedMng.plug.img[table;data];
  };

/F/ function for receiving intra-day updates
/F/ - interface corresponds to .tickLF.upd
/F/ - previous data is kept in .feedMng.prev.[table]
/F/ - applies insert in the memory
/F/ - performs .feedMng.plug.upd

.tickLF.upd:{[table;data]
  (` sv `.feedMng.prev,table) set value[table];
  .feedMng.load.upd[table;data];
  .feedMng.plug.upd[table;data];
  };

/F/ function for receiving intra-day upserts
/F/ - interface corresponds to .tickLF.ups
/F/ - previous data is kept in .feedMng.prev.[table]
/F/ - applies upsert in the memory
/F/ - performs .feedMng.plug.ups
.tickLF.ups:{[table;data;c;b;a]
  (` sv `.feedMng.prev,table) set value[table];
  .feedMng.load.ups[table;data;c;b;a];
  .feedMng.plug.ups[table;(data;c;b;a)];
  };

/F/ function for receiving intra-day deletes
/F/ - interface corresponds to .tickLF.del
/F/ - previous data is kept in .feedMng.prev.[table]
/F/ - applies deletes in the memory
/F/ - performs .feedMng.plug.del
.tickLF.del:{[table;c;b;a]
  (` sv `.feedMng.prev,table) set value[table];
  .feedMng.load.del[table;c;b;a];
  .feedMng.plug.del[table;(c;b;a)];
  };


/==============================================================================/
.sl.main:{[flags]
  .feedMng.cfg.tables:             .cr.getCfgPivot[`THIS;`table`sysTable;enlist`subSrc];
  .feedMng.cfg.timeout:            .cr.getCfgField[`THIS;`group;`cfg.timeout];
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
