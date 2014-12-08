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

/S/ Distribution component:
/S/ Responsible for:
/S/ - handling inserts, upserts, deletes and eod signals, where each of these actions has to be assigned to a table and sector combination 
/S/ - journal rollouts:
/S/ a - journal can be rolled independently for every table/sector combination using .dist.rollJrn[tab;sector;newDir]
/S/ b - journal directory can be rolled independently
/S/ Please note that data is kept in the following directory structure
/S/    [root] / [table] / [sector] / [tsDir] / [current journals]
/S/ Future extensions will include:
/S/ - custom actions 
/S/ - incoming data validation

/T/ q dist.q

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`dist];

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/sub"];
.sl.lib["qsl/handle"];

/------------------------------------------------------------------------------/
/F/ Information about subscription protocols supported by the dist component.
/F/ This definition overwrites default implementation from qsl/sl library.
/F/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server - `PROTOCOL_DIST
.sl.getSubProtocols:{[] enlist `PROTOCOL_DIST};

//----------------------- dist -----------------------------------------------//
.dist.p.init:{[]
  .dist.actions:(exec first ipc, first jrn by action from .dist.cfg.actions);

  diskState:1!update sectors:key each .dist.cfg.jrn .Q.dd'table from ([]table:key .dist.cfg.jrn);
  tabs:ungroup select tab:table, sector:sectors from diskState,.dist.cfg.tables;
  .dist.status:2!update jrnDir:.dist.p.initSectorDir'[tab;sector], jrn:`, jrnHnd:0Ni, jrnI:0Nj, w:`int$count[i]#() from tabs;

  //open and count all journals
  .dist.status:2!@[.dist.p.initJrn;;::] each 0!.dist.status;
  .dist.p.refreshW[];
  .dist.actionList:exec action from .dist.cfg.actions;
  .cb.add[`.z.pc;`.dist.p.pc];
  };

.dist.p.refreshW:{[]
  .dist.p.byW:exec tab(,)'sector by w from ungroup select tab, sector, w from .dist.status;
  };

.dist.p.pc:{[x]
  if[not x in key .dist.p.byW;:()];
  .log.info[`dist]"Removing subscription on h:",.Q.s1 x;
  .dist.p.usub[`;`;x]
  };

//subList:`gr2
//.dist.p.getSectors[`sectorGr;`gr2`gr3]
//.dist.p.getSectors[`sector;`sector1]
//.dist.p.getSectors[`sector;`]
//.dist.p.getSectors[`sectorGr;`]
.dist.p.getSectors:{[tabName;subType;subList]
  if[`ALL in subList;:exec sector from .dist.status where tab=tabName];
  if[subType~`SECTOR;:(),subList];
  '"subType:",.Q.s1[subType]," with subList:",.Q.s1[subList], " not supported"
  }; 

//.dist.sub[`Account;`;`sector;`sector1`sector2]
//.dist.sub[`Account;`;`sectorGr;`gr3]
//tab:`Account;subActions:`ALL;subType:`SECTOR;subList:`sector1
/F/ Subscribe to receive number of tables/sectors combinations
/P/  tab:SYMBOL - table name
/P/  subActions:SYMBOL - action list, currently must be set to ALL
/P/  subType:SYMBOL - subscription type, currently must be SECTOR
/P/  subList:SYMBOL - subscription list, currently must be SECTOR list
.dist.sub:{[tab;subActions;subType;subList]
  if[null tab;tab:exec distinct tab from .dist.status];
  subscriptions:([]tab:tab;subActions;subType;count[tab]#enlist(),subList);
  :.dist.subBatch[subscriptions];
  };

/F/ Subscribe to receive number of tables/sectors combinations
/P/ tab:TABLE:
/P/   col tab:SYMBOL - table name
/P/   col subActions:SYMBOL
/P/   col subType:SYMBOL 
/P/   col subList:SYMBOL 
//subscriptions:([]tab:`Account`Account`Agreement; subActions:`ALL`ALL`eod; subType:`SECTOR; subList:`sector1`sector2`sector3)
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

/F/ Unsubscribe from dist component
/P/ tab:SYMBOL - table name
/P/ sec:SYMBOL - sector name
.dist.usub:{[tab;sec]
  .dist.p.usub[tab;sec;.z.w]
  };

//.dist.p.usub[`;`;56i]
//`tab`sec`w set' (`;`;56i);
//`tab`sec`w set' (`Account;`sector2;56i)
.dist.p.usub:{[tabName;sec;wToRemove]
  update w:w (except)' wToRemove from `.dist.status where (tab in tabName)or(tabName=`),(sector in sec) or (sec=`);
  .dist.p.refreshW[];
  };

//----------------------- pub v.2 --------------------------------------------//
//t:`Account;d:(4#/: til 18);s:`
//.dist.pubOne[`upd;`Account;`sector1;(4#/: til 18)]
//`a`t`s`d set' (`upd;`Account;`sector1;(4#/: til 18))
//.dist.pubOne[`ups;`Account;`sector1;([]sym:`xxx`yyy;price:12 13)]
//.dist.pubOne[`del;`Account;`sector1;1 2 3]
/F/ Publish one action to subscribers
/P/ a:SYMBOL - one of actions `upd`ups`del`eod
/P/ t:SYMBOL - table name
/P/ s:SYMBOL - sector
/P/ d:ANY    - action data - format dependent on specific action
/E/.dist.pubOne[`upd;`Audit;`sector1;(10#`second$.z.t;10?100i;10?0x10;string 10?`4;string 10?`4;string 10?`4;string 10?`4)]
/E/.dist.pubOne[`eod;`Account;`sector1;2013.03.05]
.dist.pubOne:{[a;t;s;d]
  if[a~`eod;`a`t`s`d set' (a;t;s;d)];
  ts:.sl.zp[];
  //1. validate action
  if[not a in .dist.actionList; .log.warn[`dist]"unknown action `",string[a]];
  action:(a;t;s;d);
  action[0]:.dist.actions[a;`ipc];
  //2. journal action
  sector:.dist.status[t,s];
  
  .dist.p.jrnOne[ts; .dist.actions[a;`jrn]; action; sector`jrnHnd];
  //3. publish action
  .dist.p.pubOne[action;w:sector`w];
  };

/F/ Publish bundle of action to subscribers
/P/ actions:LIST - list of actions (out of `upd`ups`del`eod)
/E/ .dist.pubBundle[actions:(
    /E/   (`upd;`Account;`sector1;(400#/: til 18));
    /E/   (`ups;`AccountSDP;`sector2;(`xxx`yyy;12 13));
    /E/   (`del;`Account;`sector1;(`dm_account_id;1 2 3));
    /E/   (`del;`Account;`sector1;(`dm_account_id;4 5));
    /E/   (`del;`Account;`sector2;(`dm_account_id;4 5)))]
.dist.pubBundle:{[actions]
  ts:.sl.zp[];
  //1. validate all actions
  if[not all actions[;0] in .dist.actionList; .log.warn[`dist]"unknown actions `",.Q.s1[actions[;0]]];
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

.dist.p.pubErr:{[x]
  //.log.error[`dist]"Failed publishing `", string[.dist.p.tmp[1;0]]," for table `", string[.dist.p.tmp[1;1]]," to hnd ",.Q.s1[.dist.p.tmp[0]]," with signal '",x,". Parameters:(",(";" sv .Q.s1'[2_.dist.p.tmp[1]]),")"
  .log.error[`dist]"Failed publishing `", .Q.s1[.dist.p.lastMsg]," with error ",.Q.s1[x];
  };

.dist.p.pubOne:{[action;w]
  .dist.p.lastMsg:(action);
  if[count w;
    {[h;action].[@;(h;action);.dist.p.pubErr]}[;action] each neg w;
    ];
  }

//bundle:bundles[0]
.dist.p.pubBundle:{[bundle;w]
  .dist.p.lastMsg:(`.d.bundle;bundle);
  if[count w;
    {[h;bundle].[@;(h;(`.d.bundle;bundle));.dist.p.pubErr]}[;bundle] each neg w;
    ];
  };

//action:first actions;s:first sectors;jrnAction:`.j.upd
.dist.p.jrnOne:{[ts;jrnAction;action;jrnHnd]
  if[not null jrnHnd;
    jrnHnd enlist jrnAction,1_action,ts;
    .dist.status[action 1 2;`jrnI]+:1;
    ];
  };

//x:first 0!.dist.status
.dist.p.initJrn:{[x]
  newJrn:.dist.p.jrnNewFile[x`jrnDir];
  x[`jrn]:newJrn;
  if[()~key x[`jrn];x[`jrn] set ()];
  x[`jrnHnd]:hopen x[`jrn];
  x[`jrnI]:-11!(-2;x[`jrn]);
  x
  };

//jrnDir:x`jrnDir
.dist.p.jrnNewFile:{[jrnDir]
  ts:string[.sl.zz[]]except":";
  ` sv jrnDir,`$"jrn",ts
  };

.dist.p.initSectorDir:{[tab;sec]
  lastTs:last asc "Z"$string key ` sv .dist.cfg.jrn,tab,sec;
  if[null lastTs;
    lastTs:.sl.zz[];
    ];
  .dist.p.newSectorDir[tab;sec;lastTs]
  };

.dist.p.newSectorDir:{[tab;sec;ts]
  tsStr:`$string[ts]except":";
  ` sv .dist.cfg.jrn,tab,sec,tsStr,`
  };

/F/ Roll over journal for specified table and sector
/P/ tab:SYMBOL - table name
/P/ sector:SYMBOL - sector name
/P/ newDir:BOOLEAN - if set to true, the new sector directory should be created and used together with an eod action
/E/ .dist.rollJrn[`Account;`sector1;1b];
/E/ .dist.status
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
/F/ Add ad-hoc new table which was not configured using dataflow.cfg file.
/P/ tab:SYMBOL - table name
/P/ sectors:LIST SYMBOL - list of sectors
/P/ dataModel:TABLE - empty table with the data model of added table
//tab:`New; sectors:`sec0`sec1
/E/.dist.addTable[`NewTab;`sector0`sector1; ([]col1:`int$();col2:`float$())]
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
/F/ Initialize distribution component
.sl.main:{[flags]
  (set) ./: .cr.getModel[`THIS];
  .dist.cfg.jrn:.cr.getCfgField[`THIS;`group;`cfg.jrnDir];
  .dist.cfg.actions:([action:`upd`ups`del`eod]ipc:`.d.upd`.d.ups`.d.del`.d.eod; jrn:`.j.upd`.j.ups`.j.del`.j.eod);

  .dist.cfg.tables:1!`table xcol 0!.cr.getCfgPivot[`THIS;`table`sysTable;`sectors];
  .sl.libCmd[];

  .dist.p.init[.dist.cfg];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`dist;`.sl.main;`];

/------------------------------------------------------------------------------/
\
