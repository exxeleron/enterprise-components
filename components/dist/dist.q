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

/S/ Distribution component:
/-/ - handling inserts, upserts, deletes and eod signals, where each of these actions has to be assigned to a table and sector combination 
/-/ - journal rollouts:
/-/ a - journal can be rolled independently for every table/sector combination using .dist.rollJrn[tab;sector;newDir]
/-/ b - journal directory can be rolled independently
/-/ 
/-/ Note: the data is kept in the following directory structure
/-/    [root] / [table] / [sector] / [tsDir] / [current journals]
/-/ Future extensions will include:
/-/ - custom actions 
/-/ - incoming data validation

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`dist];

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/sub"];
.sl.lib["qsl/handle"];

/------------------------------------------------------------------------------/
/F/ Returns information about subscription protocols supported by the dist component.
/-/  This definition overwrites default implementation from qsl/sl library.
/-/  This function is used by qsl/sub library to choose proper subscription protocol.
/R/ :LIST SYMBOL - returns list of protocol names that are supported by the server - `PROTOCOL_DIST
/E/ .sl.getSubProtocols[]
.sl.getSubProtocols:{[] enlist `PROTOCOL_DIST};

/------------------------------------------------------------------------------/
.dist.p.init:{[]
  /G/ Table with all currently supported actions including callback names for each action.
  /-/  -- action:SYMBOL - action name
  /-/  -- ipc:SYMBOL    - name of the callback for ipc messages
  /-/  -- jrn:SYMBOL    - name of the callback for messages replayed from the journal file
  .dist.actions:(exec first ipc, first jrn by action from .dist.cfg.actions);

  diskState:1!update sectors:key each .dist.cfg.jrn .Q.dd'table from ([]table:key .dist.cfg.jrn);
  tabs:ungroup select tab:table, sector:sectors from diskState,.dist.cfg.tables;
  /G/ Table with current dist process status, including all managed tables and current subscriptions.
  /-/  -- tab:SYMBOL    - table name
  /-/  -- sector:SYMBOL - sector name
  /-/  -- jrnDir:SYMBOL - current journal directory
  /-/  -- jrn:SYMBOL    - current journal name
  /-/  -- jrnI:LONG     - current position in the current journal name
  /-/  -- w:LIST INT    - list of handles subscribed for given table/sector  
  /-/  -- jrnHnd:SHORT  - journal handle
  .dist.status:2!update jrnDir:.dist.p.initSectorDir'[tab;sector], jrn:`, jrnHnd:0Ni, jrnI:0Nj, w:`int$count[i]#() from tabs;

  //open and count all journals
  .dist.status:2!@[.dist.p.initJrn;;::] each 0!.dist.status;
  .dist.p.refreshW[];

  /G/ List of all all currently supported actions, based on .dist.cfg.actions.
  .dist.actionList:exec action from .dist.cfg.actions;
  .cb.add[`.z.pc;`.dist.p.pc];
  };

/------------------------------------------------------------------------------/
.dist.p.refreshW:{[]
  .dist.p.byW:exec tab(,)'sector by w from ungroup select tab, sector, w from .dist.status;
  };

/------------------------------------------------------------------------------/
.dist.p.pc:{[x]
  if[not x in key .dist.p.byW;:()];
  .log.info[`dist]"Removing subscription on h:",.Q.s1 x;
  .dist.p.usub[`;`;x]
  };

/------------------------------------------------------------------------------/
/E/ .dist.p.getSectors[`sectorGr;`gr2`gr3]
/E/ .dist.p.getSectors[`sector;`sector1]
/E/ .dist.p.getSectors[`sector;`]
/E/ .dist.p.getSectors[`sectorGr;`]
.dist.p.getSectors:{[tabName;subType;subList]
  if[`ALL in subList;:exec sector from .dist.status where tab=tabName];
  if[subType~`SECTOR;:(),subList];
  '"subType:",.Q.s1[subType]," with subList:",.Q.s1[subList], " not supported"
  }; 

/------------------------------------------------------------------------------/
/                             subscription                                     /
/------------------------------------------------------------------------------/
/F/ Subscribes for number of tables/sectors combinations.
/P/ tab:SYMBOL        - table name
/P/ subActions:SYMBOL - action list, currently must be set to ALL
/P/ subType:SYMBOL    - subscription type, currently must be SECTOR
/P/ subList:SYMBOL    - subscription list, currently must be SECTOR list
/R/ :TABLE - table with subscription information containg pointers to the journal files
/-/  -- tab:SYMBOL    - table name
/-/  -- sector:SYMBOL - sector name
/-/  -- jrnDir:SYMBOL - current journal directory
/-/  -- jrn:SYMBOL    - current journal name
/-/  -- jrnI:LONG     - current position in the current journal name
/-/  -- w:LIST INT    - list of handles subscribed for given table/sector  
/-/  -- jrnHnd:SHORT  - journal handle
/-/  -- mode:TABLE    - data model in form of empty table
/E/ .dist.sub[`Account;`;`sector;`sector1`sector2]
/E/ .dist.sub[`Account;`;`sectorGr;`gr3]
.dist.sub:{[tab;subActions;subType;subList]
  if[null tab;tab:exec distinct tab from .dist.status];
  subscriptions:([]tab:tab;subActions;subType;count[tab]#enlist(),subList);
  :.dist.subBatch[subscriptions];
  };

/------------------------------------------------------------------------------/
/F/ Subscribes for a number of tables/sectors combinations. Batch version of .dist.sub[]
/P/ tab:TABLE:
/P/  -- tab:SYMBOL        - table name
/P/  -- subActions:SYMBOL - action list, currently must be set to ALL
/P/  -- subType:SYMBOL    - subscription type, currently must be SECTOR
/P/  -- subList:SYMBOL    - subscription list, currently must be SECTOR list
/R/ :TABLE - table with subscription information containg pointers to the journal files
/-/  -- tab:SYMBOL    - table name
/-/  -- sector:SYMBOL - sector name
/-/  -- jrnDir:SYMBOL - current journal directory
/-/  -- jrn:SYMBOL    - current journal name
/-/  -- jrnI:LONG     - current position in the current journal name
/-/  -- w:LIST INT    - list of handles subscribed for given table/sector  
/-/  -- jrnHnd:SHORT  - journal handle
/-/  -- mode:TABLE    - data model in form of empty table
/E/ .dist.subBatch ([]tab:`Account`Account`Agreement; subActions:`ALL`ALL`eod; subType:`SECTOR; subList:`sector1`sector2`sector3)
.dist.subBatch:{[subscriptions]
  if[count unsupActFilter:distinct[subscriptions`subActions]except `ALL;
    .log.warn[`dist]"unsupported action filter ",.Q.s1[unsupActFilter],"- all actions will be published";
    ];
  new:ungroup select tab, sector:.dist.p.getSectors'[tab;subType;subList], subActions from subscriptions;
  newPairs:select tab, sector from new;
  .dist.status[newPairs;`w]:distinct each .dist.status[newPairs;`w],\:.z.w;
  .dist.p.refreshW[];
  `tab`sector xcols update model:value each tab from update tab:newPairs`tab, sector:newPairs`sector from .dist.status[newPairs]
  };

/------------------------------------------------------------------------------/
/F/ Unsubscribes from dist component.
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector name
/R/ no return value
/E/ .dist.usub[`Account;`sector1]
.dist.usub:{[tab;sec]
  .dist.p.usub[tab;sec;.z.w]
  };

/------------------------------------------------------------------------------/
/E/.dist.p.usub[`;`;56i]
.dist.p.usub:{[tabName;sec;wToRemove]
  update w:w (except)' wToRemove from `.dist.status where (tab in tabName)or(tabName=`),(sector in sec) or (sec=`);
  .dist.p.refreshW[];
  };

/------------------------------------------------------------------------------/
/                             publishing                                       /
/------------------------------------------------------------------------------/
/F/ Publishes one action to subscribers.
/P/ a:SYMBOL - one of actions `upd`ups`del`eod
/P/ t:SYMBOL - table name
/P/ s:SYMBOL - sector
/P/ d:ANY    - action data - format dependent on specific action
/R/ no return value
/E/ .dist.pubOne[`upd;`Audit;`sector1;(10#`second$.z.t;10?100i;10?0x10;string 10?`4;string 10?`4;string 10?`4;string 10?`4)]
/E/ .dist.pubOne[`del;`Account;`sector1;1 2 3]
/E/ .dist.pubOne[`eod;`Account;`sector1;2013.03.05]
.dist.pubOne:{[a;t;s;d]
  if[a~`eod;`a`t`s`d set' (a;t;s;d)];
  ts:.sl.zp[];
  //1. validate action
  if[not a in .dist.actionList; .log.warn[`dist]"unknown action `",string[a], ". Only actions: ", .Q.s1[.dist.actionList] , " are supported."];
  action:(a;t;s;d);
  action[0]:.dist.actions[a;`ipc];
  //2. journal action
  sector:.dist.status[t,s];
  
  .dist.p.jrnOne[ts; .dist.actions[a;`jrn]; action; sector`jrnHnd];
  //3. publish action
  .dist.p.pubOne[action;w:sector`w];
  };

/------------------------------------------------------------------------------/
/F/ Publishes bundle of action to subscribers.
/P/ actions:LIST - list of actions (out of `upd`ups`del`eod)
/R/ no return value
/E/ .dist.pubBundle[((`upd;`Account;`sector1;(400#/: til 18));(`ups;`AccountSDP;`sector2;(`xxx`yyy;12 13));(`del;`Account;`sector1;(`dm_account_id;1 2 3)))]
.dist.pubBundle:{[actions]
  ts:.sl.zp[];
  //1. validate all actions
  if[not all actions[;0] in .dist.actionList; .log.warn[`dist]"unknown actions `",.Q.s1[actions[;0]], ". Only actions: ", .Q.s1[.dist.actionList] , " are supported."];
  act:actions[;0];
  actions[;0]:.dist.actions[act;`ipc];
  //2. journal all actions
  sectors:.dist.status[actions[;1 2]];

  .dist.p.jrnOne'[ts; .dist.actions[act;`jrn]; actions; sectors`jrnHnd];
  //3. publish all actions, each subscriber gets all matching actions in one bundle
  actionIds:exec i by (tab,'sector) from flip `action`tab`sector`data!flip actions;
  bundles:actions raze each actionIds each value .dist.p.byW;

  .dist.p.pubBundle'[bundles;w:key .dist.p.byW];
  };

/------------------------------------------------------------------------------/
.dist.p.pubErr:{[x]
  //.log.error[`dist]"Failed publishing `", string[.dist.p.tmp[1;0]]," for table `", string[.dist.p.tmp[1;1]]," to hnd ",.Q.s1[.dist.p.tmp[0]]," with signal '",x,". Parameters:(",(";" sv .Q.s1'[2_.dist.p.tmp[1]]),")"
  .log.error[`dist]"Failed publishing `", .Q.s1[.dist.p.lastMsg]," with error ",.Q.s1[x];
  };

/------------------------------------------------------------------------------/
.dist.p.pubOne:{[action;w]
  .dist.p.lastMsg:(action);
  if[count w;
    {[h;action].[@;(h;action);.dist.p.pubErr]}[;action] each neg w;
    ];
  }

/------------------------------------------------------------------------------/
//bundle:bundles[0]
.dist.p.pubBundle:{[bundle;w]
  .dist.p.lastMsg:(`.d.bundle;bundle);
  if[count w;
    {[h;bundle].[@;(h;(`.d.bundle;bundle));.dist.p.pubErr]}[;bundle] each neg w;
    ];
  };

/------------------------------------------------------------------------------/
//action:first actions;s:first sectors;jrnAction:`.j.upd
.dist.p.jrnOne:{[ts;jrnAction;action;jrnHnd]
  if[not null jrnHnd;
    jrnHnd enlist jrnAction,1_action,ts;
    .dist.status[action 1 2;`jrnI]+:1;
    ];
  };

/------------------------------------------------------------------------------/
//x:first 0!.dist.status
.dist.p.initJrn:{[x]
  newJrn:.dist.p.jrnNewFile[x`jrnDir];
  x[`jrn]:newJrn;
  if[()~key x[`jrn];x[`jrn] set ()];
  x[`jrnHnd]:hopen x[`jrn];
  x[`jrnI]:-11!(-2;x[`jrn]);
  x
  };

/------------------------------------------------------------------------------/
//jrnDir:x`jrnDir
.dist.p.jrnNewFile:{[jrnDir]
  ts:string[.sl.zz[]]except":";
  ` sv jrnDir,`$"jrn",ts
  };

/------------------------------------------------------------------------------/
.dist.p.initSectorDir:{[tab;sec]
  lastTs:last asc "Z"$string key ` sv .dist.cfg.jrn,tab,sec;
  if[null lastTs;
    lastTs:.sl.zz[];
    ];
  .dist.p.newSectorDir[tab;sec;lastTs]
  };

/------------------------------------------------------------------------------/
.dist.p.newSectorDir:{[tab;sec;ts]
  tsStr:`$string[ts]except":";
  ` sv .dist.cfg.jrn,tab,sec,tsStr,`
  };

/------------------------------------------------------------------------------/
/F/ Rolls over journal for specified table and sector.
/P/ tab:SYMBOL     - table name
/P/ sector:SYMBOL  - sector name
/P/ newDir:BOOLEAN - if set to true, the new sector directory should be created and used together with an eod action
/R/ no return value
/E/ .dist.rollJrn[`Account;`sector1;1b];
/-/   - rolled journal can be checked via .dist.status
.dist.rollJrn:{[tab;sector;newDir]
  //close current journal
  hclose .dist.status[tab,sector][`jrnHnd];
  if[newDir;   //create new sector dir
    newPath:.dist.p.newSectorDir[tab;sector;.sl.zz[]];
    .log.info[`dist] "new secotor path:", .Q.s1[newPath];
    .dist.status[tab,sector;`jrnDir]:newPath;
    ];
  //create new journal
  .dist.status,:.dist.p.initJrn first 0!?[`.dist.status;((=;`tab;enlist tab);(=;`sector;enlist sector));0b;()];
  };

/------------------------------------------------------------------------------/
/F/ Adds ad-hoc new table which was not configured using dataflow.cfg file.
/P/ tab:SYMBOL          - table name
/P/ sectors:LIST SYMBOL - list of sectors
/P/ dataModel:TABLE     - empty table with the data model of added table
/R/ no return value
/E/ .dist.addTable[`NewTab;`sector0`sector1; ([]col1:`int$();col2:`float$())]
.dist.addTable:{[tab;sectors;dataModel]
  //validation
  if[-11<>type tab;'"tab should be of type -11h, not ", .Q.s1 type sectors];
  if[11<>type sectors;'"sectors should be of type 11h, not ", .Q.s1 type sectors];
  if[98<>type dataModel;'"dataModel should be of type 98h, not ", .Q.s1 type dataModel];
  if[tab in distinct exec tab from .dist.status;'"table ",.Q.s1[tab]," already added"];

  tab set dataModel;
  new:2!update jrnDir:.dist.p.initSectorDir'[tab;sector], jrn:`, jrnHnd:0Ni, jrnI:0Nj, w:`int$count[i]#() from ([]tab;sector:sectors);
  //open and init journals
  new:update jrnI:0j, jrnHnd:hopen'[jrn] from update jrn:.dist.p.jrnNewFile'[jrnDir] from new;
  .dist.status,:new;
  .dist.p.refreshW[];
  };

/------------------------------------------------------------------------------/
/F/ Component initialization entry point.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]
  (set) ./: .cr.getModel[`THIS];
  /G/ Journal directory, loaded from cfg.jrnDir field from system.cfg.
  .dist.cfg.jrn:.cr.getCfgField[`THIS;`group;`cfg.jrnDir];
  /G/ List of supported actions, currently hardcoded in the .sl.main[] function.
  .dist.cfg.actions:([action:`upd`ups`del`eod]ipc:`.d.upd`.d.ups`.d.del`.d.eod; jrn:`.j.upd`.j.ups`.j.del`.j.eod);
  /G/ Table with sectors information
  /-/  -- table:SYMBOL        - table name, based on entries from dataflow.cfg
  /-/  -- sectors:LIST SYMBOL - list of sectors allowed for the given table name, loaded from sectors field from the dataflow.cfg.
  .dist.cfg.tables:1!`table xcol 0!.cr.getCfgPivot[`THIS;`table`sysTable;`sectors];
  .sl.libCmd[];
  .dist.p.init[.dist.cfg];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`dist;`.sl.main;`];

/------------------------------------------------------------------------------/
\
