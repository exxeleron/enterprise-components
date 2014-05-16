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

/V/ 3.0

/T/ q tickLF.q
/T/ q tickLF.q -lib plugins.q

/S/ Tick Low Frequency component:
/S/ Tick with extended functionality, ideal for reference data

/S/ Responsible for:
/S/ - handling inserts, overwrites and deletes
/S/ - data validating
/S/ - supporting journal switching when data image is received (<.tickLF.pubImg> is called) or at the end-of-day
/S/ - enabling data enrichment and validation trough custom plugins
/S/ - data manipulating at the end-of-day trough <.tickLF.plug.eod> plugin
/S/ - protecting data publishing - in case of connection failure or handle corruption to one of subscribers, data publishing is not affected to the others; publishing failure will be logged as an error in the log file
/S/ - protecting against loops between publisher-subscriber in case if publisher is also subscribed to the same table; data published by tickLF interface by such process won't be send back to the producer; producer should handle updates that are sent through tickLF on its side
/S/ Note:
/S/ sym (type:SYMBOL) column is mandatory in the data model for tickLF tables

/S/ List of plugins to setup:
/S/ - custom data validation, return: signal in case of validation failure
/S/ (start code)
/S/ .tickLF.plug.validate[table name:SYMBOL;data as nested list:LIST GENERAL]
/S/ (end)
/S/ - data enriching parameters, return: LIST GENERAL
/S/ (start code)
/S/ .tickLF.plug.enrich[table name:SYMBOL;data as nested list:LIST GENERAL]
/S/ (end)
/S/ - end-of-day plugin
/S/ (start code)
/S/ .tickLF.plug.eod[table name:SYMBOL;table name:SYMBOL]
/S/ (end)
/S/ Interface for receiving data from tickLF is described in qsl/<sub.q>


/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`tickLF];

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/sub_tickLF"];
.sl.lib["qsl/handle"];

/------------------------------------------------------------------------------/
/F/ Information about subscription protocols supported by the tickLF component.
/F/ This definition overwrites default implementation from qsl/sl library.
/F/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server - `PROTOCOL_TICKLF
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKLF};

/------------------------------------------------------------------------------/
/G/ definition of custom data validation
.tickLF.plug.validate:()!();
/G/ definition of custom data enrichment
.tickLF.plug.enrich:()!();
/G/ definition of eod plugin
.tickLF.plug.eod:()!();

/------------------------------------------------------------------------------/
/G/ journal handles
.tickLF.jrnHnd:()!();
/G/ journal files
.tickLF.jrn:()!();
/G/ directories with journal files
.tickLF.jrnDirs:()!();
/G/ number of entries in journals
.tickLF.jrnI:()!();
/G/ supported tables
.tickLF.t:();
/G/ supported tables and subscription details
.tickLF.w:()!();
/G/ current date
.tickLF.d:0Nd;
/G/ configuration for tables
.tickLF.tables:();
/G/ number of published messages
.tickLF.PubNo:()!();
/G/ time of last update, delete, upsert, image
.tickLF.PubLast:()!();
/G/ group of data validating functions
.tickLF.validate:()!();
/G/ group of data validating functions for deletes
.tickLF.validateDel:()!();
/G/ group of status updates functions
.tickLF.updStatus:()!();
/G/ group of functions that require journal operations
.tickLF.actionJrn:()!();
/------------------------------------------------------------------------------/
/F/ generic function for publishing updates and images
/P/ fn - function name (symbol)
/P/ t - table name (symbol)
/P/ d - data (list)
/E/ t:`universe;// t:`underlyings// t:`calendar
/E/ d:(2#.z.t ;`a`b; 2#.z.d) // d:(.z.t ;`a; .z.d)
/E/ fn:`.tickLF.img // fn:`.tickLF.upd
/E/ .tickLF.p.pubSimple[fn;t;d]
.tickLF.p.pubSimple:{[fn;t;d]
  d:.tickLF.validate[t][d;fn]; //218/1
  //pub
  f:key flip value t;
  .tickLF.p.pub[t;fn;flip f!(),/:d];
  //take action in order to config
  // journal switch and update
  .tickLF.actionJrn[(t;fn)][d];
  //update status
  .tickLF.updStatus[t][fn];
  };

/------------------------------------------------------------------------------/
/F/ function for publishing updates
/P/ t - table name (symbol)
/P/ d - data (list)
/E/ .tickLF.pubUpd[`universe;d]
.tickLF.pubUpd:.tickLF.p.pubSimple[`.tickLF.upd];

/------------------------------------------------------------------------------/
/F/ function for publishing images
/P/ t - table name (symbol)
/P/ d - data (list)
/E/ .tickLF.pubImg[`universe;d]
.tickLF.pubImg:.tickLF.p.pubSimple[`.tickLF.img];

/------------------------------------------------------------------------------/
/F/ function for publishing upserts
/P/ t - table name as symbol
/P/ d - incoming data as list
/P/ a is a dictionary of aggregates, b is a dictionary of group-bys and c is a list of constraints   
/E/ t:`universe;
/E/ d:(.z.t ;`a; .z.d+1);
/E/ d:(.z.t ;`b; .z.d);
/E/ c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)

.tickLF.pubUps:{[t;d;c;b;a]
  d:.tickLF.validate[t][d;(`.tickLF.ups;c;b;a)]; 
  //pub
  f:key flip value t;
  .tickLF.p.pubUps[t;flip f!(),/:d;c;b;a];
  //take action in order to config
  // journal switch and update
  .tickLF.actionJrn[(t;`.tickLF.ups)][(d;c;b;a)];
  //update status
  .tickLF.updStatus[t][`.tickLF.ups];
  };

/------------------------------------------------------------------------------/
/F/ function for publishing deletes
/P/ t - table name as symbol
/P/ a - dictionary of aggregates
/P/ b - dictionary of group-bys 
/P/ c - list of constraints   
/E/ t:`universe;
/E/ parse"delete from `universe where sym in `a`b, mat>.z.d"
/E/ c:(( in;`sym;enlist `a`b);(>;`mat;.z.d));b:0b;a:0#`
.tickLF.pubDel:{[t;c;b;a]
  .tickLF.validateDel[t][();(`.tickLF.del;c;b;a)]; 
  //pub
  .tickLF.p.pubDel[t;c;b;a];
  .tickLF.actionJrn[(t;`.tickLF.del)][(c;b;a)];
  //update status
  .tickLF.updStatus[t][`.tickLF.del];
  };

/------------------------------------------------------------------------------/
.tickLF.p.pubErr:{[x]
  .log.error[`tickLF]"Failed publishing `", string[.tickLF.p.tmp[1;0]]," for table `", string[.tickLF.p.tmp[1;1]]," to hnd ",.Q.s1[.tickLF.p.tmp[0]]," with signal '",x,". Parameters:(",(";" sv .Q.s1'[2_.tickLF.p.tmp[1]]),")"
  };
/------------------------------------------------------------------------------/   
.tickLF.p.run:{[]
  .[@;.tickLF.p.tmp;.tickLF.p.pubErr]
  };
/------------------------------------------------------------------------------/   
.tickLF.p.wList:{[t;zw]
  x:.tickLF.w[t];res:x where (x[;0]<>zw)|(x[;0]=0);
  .log.debug[`tickLF] "Table:",string[t],". Publisher:",string[zw],". List of receivers:",.Q.s1[res];
  res
  };
/------------------------------------------------------------------------------/   
/F/ data publishing
/P/ t - table 
/P/ x - data 
/P/ fn - function img upd
/E/ fn:`.tickLF.img;x:$[0>type first d;enlist f!d;flip f!d];
.tickLF.p.pub:{[t;fn;x]
  {[t;fn;x;w] if[count x:.tickLF.p.sel[x]w 1;.tickLF.p.tmp:((neg first w);(fn;t;x));.tickLF.p.run[]]}[t;fn;x]each .tickLF.p.wList[t;.z.w];
  };

/------------------------------------------------------------------------------/
/F/ data publishing
/P/ table/data/params - ups
/E/ x:$[0>type first d;enlist f!d;flip f!d];
.tickLF.p.pubUps:{[t;x;c;b;a]
  {[t;x;c;b;a;w] if[count x:.tickLF.p.sel[x]w 1;.tickLF.p.tmp:((neg first w);(`.tickLF.ups;t;x;c;b;a));.tickLF.p.run[]]}[t;x;c;b;a;]each .tickLF.p.wList[t;.z.w];
  };
/------------------------------------------------------------------------------/
/F/ publishing deletes
/P/ table/params - del
.tickLF.p.pubDel:{[t;c;b;a]
  {[t;c;b;a;w] .tickLF.p.tmp:((neg first w);(`.tickLF.del;t;c;b;a));.tickLF.p.run[]}[t;c;b;a;]each .tickLF.p.wList[t;.z.w];
  };

/------------------------------------------------------------------------------/
/F/ select data from table
.tickLF.p.sel:{$[`~y;x;select from x where sym in y]};

/------------------------------------------------------------------------------/
/F/ delete from subscription dictionary
/E/ y:.z.x
.tickLF.p.del:{.tickLF.w[x]_:.tickLF.w[x;;0]?y};

/------------------------------------------------------------------------------/
/F/ add to subscription dictionary
.tickLF.p.add:{$[(count .tickLF.w x)>i:.tickLF.w[x;;0]?z;.[`.tickLF.w;(x;i;1);union;y];.tickLF.w[x],:enlist(z;y)];(x;$[99=type v:value x;.tickLF.sel[v]y;0#v])};

/------------------------------------------------------------------------------/
/F/ internal timer definition
.tickLF.p.ts:{if[.tickLF.d<.sl.eodSyncedDate[];.tickLF.p.endofday[]]};

/------------------------------------------------------------------------------/
/F/ end of day actions
.tickLF.p.endofday:{[]
  .tickLF.d+:1;
  .log.info[`tickLF] "Call eod, switch date to:", string .tickLF.d;
  // switch journal
  jrnSwEod:exec table from .tickLF.tables where `eod in/:jrnSwitch;
  .tickLF.p.switchJrn[;`.tickLF.jEod] each jrnSwEod;
  // call eod plugins
  .log.info[`tickLF] "Call eod plugins for tables:", .Q.s1[eodPlug:key .tickLF.plug.eod];
  .tickLF.plug.eod'[eodPlug;eodPlug];
  storeImg:exec table from .tickLF.tables where eodImg2Jrn;
  .log.info[`tickLF] "Update journals with images for tables:", .Q.s1[storeImg];
  .tickLF.p.updJrn[;`.tickLF.jImg;]'[storeImg;value'[storeImg]];
  };

/------------------------------------------------------------------------------/
// journal operations
/------------------------------------------------------------------------------/
/F/ journal initialization
/E/ tabs:`universe`underlyings`calendar
/E/ jrn:config`jrn
.tickLF.p.initJrn:{[tabs;jrn]
  dirs:` sv/:jrn,/:tabs;
  .tickLF.jrnDirs[tabs]:dirs;
  jrnExist:f@'last each where each (f:asc each key'[dirs]) like'"[0-9]*.",/:string[tabs];
  jrn2Init:where any each (not count'[jrnExist]),'`~/:jrnExist;
  newJrns:` sv/: (`$ssr[string .sl.zz[];":";"."], ".ini"),/:tabs[jrn2Init];
  jrns:` sv/: dirs,'jrnExist;
  new:` sv/:jrns[jrn2Init],'newJrns;
  jrns[jrn2Init]:new;
  .tickLF.p.setJrn each new;
  .tickLF.p.ldJrn'[tabs;jrns];
  };

/------------------------------------------------------------------------------/
.tickLF.p.updJrn:{[t;f;x]
  if[l:.tickLF.jrnHnd[t]; 
    l enlist (f;t;x);
    .tickLF.jrnI[t]+:1;
    ];
  };

.tickLF.p.updJrnNested:{[t;f;p]
  if[l:.tickLF.jrnHnd[t]; 
    l enlist (,/)(f;t;p);
    .tickLF.jrnI[t]+:1;
    ];
  };

/------------------------------------------------------------------------------/
.tickLF.p.setJrn:{[jrn]
  .log.info[`tickLF] "Create new journal:",.Q.s1 jrn;
  .[jrn;();:;()];
  };

/------------------------------------------------------------------------------/
//.tickLF.p.closeJrn each tabs
.tickLF.p.closeJrn:{[t]
  if[l:.tickLF.jrnHnd[t];hclose l;.tickLF.jrnHnd[t]:0i];
  };

/------------------------------------------------------------------------------/
.tickLF.p.ldJrn:{[t;jrn]
  i:-11!(-2;jrn);
  .tickLF.jrnHnd[t]:hopen jrn;
  .log.info[`tickLF] "Loading journal file:",.Q.s1[jrn],", handle:",string[.tickLF.jrnHnd[t]], ", entries:",string i;
  .tickLF.jrn[t]:jrn;
  .tickLF.jrnI[t]:i;
  };

/------------------------------------------------------------------------------/
//t:`universe;f:`.tickLF.img
.tickLF.p.switchJrn:{[t;f]
  .log.debug[`tickLF] "Switch journal for table: ", string[t], " ,func: ", string f;
  f:`$lower 9_string[f];
  .tickLF.p.closeJrn[t];
  newJrn:` sv .tickLF.jrnDirs[t],` sv  (`$ssr[string .sl.zz[];":";"."]),f,t;
  .tickLF.p.setJrn[newJrn];
  .tickLF.p.ldJrn[t;newJrn];
  };

/------------------------------------------------------------------------------/
// setup validation, enriching and status updates
/------------------------------------------------------------------------------/
.tickLF.p.addValidFunc:{[tabsCfg]
  // deafulat validate function - return passed data
  .tickLF.validate[tabsCfg`table]:{[x;y;z] y}@/:tabsCfg`table;
  .tickLF.validateDel[tabsCfg`table]:{[x;y;z] }@/:tabsCfg`table;
  // enriching should return data
  validfuncs:("y:.tickLF.plug.enrich[x;y]"; ".tickLF.plug.validate[x;y]";".tickLF.p.standardValidation[x;y;z]");
  funcDict:exec table!(enrichPlug,'validatePlug,'validation) from tabsCfg;
  tab2valid:where any each funcDict;
  tab2validDict:where each funcDict tab2valid;
  // validation should return data
  .tickLF.validate[tab2valid]:value'["{[x;y;z]",/:(";" sv/: validfuncs[tab2validDict]),\:";:(y)}"]@'tab2valid;
  // x - table, y - data (), z - params (fn +params)
  // functions except data enrichment
  tab2validDel:tab2validDict except\: 0;
  validdelfuncs:(();".tickLF.plug.validate[x;z]";".tickLF.p.standardValidation[x;y;z]");
  .tickLF.validateDel[tab2valid]:value'["{[x;y;z]",/:(";" sv/: validdelfuncs[tab2validDel]),\:"}"]@'tab2valid;
  };

/------------------------------------------------------------------------------/
.tickLF.p.addActionJrn:{[tabsCfg]
  tabs:tabsCfg[`table];
  jrnSwImg:tabs where `img in/:tabsCfg[`jrnSwitch];
  // when img comes - switch jrn then update
  imgAct:{{[x;y;z] .tickLF.p.switchJrn[x;y]; .tickLF.p.updJrn[x;y;z]}[x;`.tickLF.jImg]} each jrnSwImg;
  .tickLF.actionJrn[flip (jrnSwImg;`.tickLF.img)]:imgAct;
  jrnUpdImg:tabs except jrnSwImg;
  imgAct2:{{[x;y;z] .tickLF.p.updJrn[x;y;z]}[x;`.tickLF.jImg]} each jrnUpdImg;
  .tickLF.actionJrn[flip (jrnUpdImg;`.tickLF.img)]:imgAct2;
  // when upd comes - update journal
  updAct:{{[x;y;z] .tickLF.p.updJrn[x;y;z]}[x;`.tickLF.jUpd]} each tabs;
  .tickLF.actionJrn[flip (tabs;`.tickLF.upd)]:updAct;
  // when ups comes - update journal
  upsAct:{{[x;y;z] .tickLF.p.updJrnNested[x;y;z]}[x;`.tickLF.jUps]} each tabs;
  .tickLF.actionJrn[flip (tabs;`.tickLF.ups)]:upsAct;
  // when del comes - update journal
  delAct:{{[x;y;z] .tickLF.p.updJrnNested[x;y;z]}[x;`.tickLF.jDel]} each tabs;
  .tickLF.actionJrn[flip (tabs;`.tickLF.del)]:delAct;
  };


/------------------------------------------------------------------------------/
//t:`universe
//d:(09:41:44.576 09:41:44.576;`a`b;2011.10.25 2011.10.25)
//fnparams:`.tickLF.img
.tickLF.p.standardValidation:{[t;d;fnparams]
  fnparams:(),fnparams;
  fn:fnparams[0];p:1_fnparams;
  .log.debug[`tickLF] "Perform standard validation for table, func, params: ", .Q.s1(t;fn;p);
  // check only in case of upd.img,ups
  if[not`.tickLF.del~fn; .tickLF.p.validateModel[t;d]];
  if[count p;.tickLF.p.validateParams[t;fn;p]];
  };

/------------------------------------------------------------------------------/
/F/ validate data model
/R/ return signal if data model is incorrect
/P/ t - table name (symbol)
/P/ d - data (table, list)
/E/ t:`universe
/E/ d:(.z.t;`a;.z.d)
/E/ d:2#/:(.z.t;`a;.z.d)
/E/ d:([] time:enlist .z.t;sym:enlist `a;mat:enlist .z.d)
.tickLF.p.validateModel:{[t;d]
  f:key flip value t;
  // if it's not a table then convert to table
  if[not 0<type d;
    // check number of columns
    if[(n:count[f])<>dc:count[d];'"Number of columns [",string[t], "] is incorrect:", string[dc],", expected:", string[n]];
    d:$[0>type first d;enlist f!d;flip f!d];
    ];
  // check columns
  if[(n:count[f])<>dc:count c:key flip d;
    '"Number of columns [",string[t], "] is incorrect:", string[dc],", expected:", string[n];
    ];
  if[count m:f where not f in c;
    '"Missing columns in [",string[t], "]:", .Q.s1[m],", expected:", .Q.s1[f];
    ];
  // check types
  if[count w:where not (r:0!meta[d])[`t]=e:.tickLF.cfg.types[t];
    '"Received [",string[t], "] type:",.Q.s1[r[w][`c],'r[w][`t]], ", expected type is: ",.Q.s1[r[w][`c],'e[w]];
    ];
  .log.debug[`tickLF] "Data model for table:", string[t], "is checked, status: ok";
  };

/------------------------------------------------------------------------------/
//p:(`a;enlist[`sym]!enlist `sym;`time`mat!`time`mat)
//p:(();enlist[`sym]!enlist `sym;`time`mat!`time`mat)
//fn:`.tickLF.img
.tickLF.p.validateParams:{[t;fn;p]
  c:p[0];b:bv:p[1];a:av:p[2];
  if[0b~b;bv:()!()];if[any a~/:(0#`;());av:()!()];
  f:key flip value t;
  if[count m:key[bv] where not key[bv] in f; 
    '"Function call [", string[fn],"] table [",string[t],"]: specified columns:",.Q.s1[m], " for group-bys don't exist in data model";
    ];
  if[count m:key[av] where not key[av] in f; 
    '"Function call [", string[fn],"] table [",string[t],"]: specified columns:",.Q.s1[m], " for aggregations don't exist in data model";
    ];
  //TODO: change to ! here? - maybe not, we don't want to delete data during validation
  .pe.dot[?;(t;c;b;a);{[x;t;fn;c;b;a]'"Function call [", string[fn],"] table [",string[t],"]: evaluation of paramters: ",.Q.s1[(c;b;a)]," throws an error: ", x}[;t;fn;c;b;a]];
  .log.debug[`tickLF] "Parameters for function, table:", .Q.s1[(fn;t)], " are checked, status: ok";
  };

/------------------------------------------------------------------------------/
.tickLF.p.eodImg:{[t;d]
  .log.info[`tickLF] "Store img at the eod in journal file: ", .Q.s1(t);
  };

/------------------------------------------------------------------------------/
//tab:`universe
//func:`.tickLF.upd
.tickLF.p.updStatus:{[tab;func]
  .log.debug[`tickLF] "Update status for table,func: ", .Q.s1(tab;func);
  .tickLF.PubNo[(tab;func)]+:1;
  .tickLF.PubLast[(tab;func)]:.sl.zz[];
  };

/------------------------------------------------------------------------------/
// interfaces
/------------------------------------------------------------------------------/
/F/ subscription to the tickLF
/P/ x - table name (symbol)
/P/ y - symbol name (list of symbols or `)
/E/ x:`universe
/E/ y:`
/E/ value each .tickLF.sub[;`] each `universe`underlyings
.tickLF.sub:{[x;y]
  if[x~`;
    :.tickLF.sub[;y]each .tickLF.t
    ];
  if[not x in .tickLF.t;'x];
  .tickLF.p.del[x].z.w;
  .log.info[`tickLF] "Subscription request on h:",(.Q.s1 .z.w),". Table:",(.Q.s1 x),". Sym:",.Q.s1 y;
  model:.tickLF.p.add[x;y;.z.w];
  :(model;(.tickLF.jrnI[x];.tickLF.jrn[x]));
  };

/------------------------------------------------------------------------------/
/F/ timer definition

/F/ port close callback, removing subscriber from the subscription list

.tickLF.p.pc:{
  if[not x in first'[raze value .tickLF.w];:()];
  // disable port close with handle 0. Port close with handle 0 is called when yak closed stream on descriptor 0.
  if[10b x;:()];
  .log.info[`tickLF] "Removing subscription on h:",.Q.s1 x; 
  .tickLF.p.del[;x]each .tickLF.t
  };




/------------------------------------------------------------------------------/
/F/ .tickLF.status[] derives information about
/F/ - tickLF initialization
/F/ - updates processing
/F/ - subscription lists
/R/ table with following details
/R/ (start code)
/R/ table        - table name
/R/ validation   - validation on/off
/R/ jrnSwitch    - list of methods for journal switching
/R/ eodImg2Jrn   - store img to the journal at eod
/R/ memory       - keep table in memory
/R/ status       - status tracking
/R/ enrichPlug   - flag for loaded enrichment plugins
/R/ validatePlug - flag for loaded validation plugins
/R/ jrn          - journal location
/R/ i            - number of entries stored in journal file
/R/ hnd          - handle to the journal file
/R/ .tickLF.img  - last time and number of img messages
/R/ .tickLF.upd  - last time and number of upd messages
/R/ .tickLF.ups  - last time and number of ups messages
/R/ sub          - subscription lists with subscribers handles and universe
/R/ (end)

/E/ .tickLF.status[]
.tickLF.status:{[]
  t:flip `table`f`n!(flip key .tickLF.PubLast,'.tickLF.PubNo),enlist value .tickLF.PubLast,'.tickLF.PubNo;
  t1:exec (asc exec distinct f from t)#(f!n) by table:table from t;
  d:.tickLF.jrn,'.tickLF.jrnI,'.tickLF.jrnHnd;
  sub:([table:key[.tickLF.w]]sub:value .tickLF.w);
  (.tickLF.tables,'(flip `table`jrn`i`hnd!(enlist key d),flip value d) lj t1) lj sub
  };

/------------------------------------------------------------------------------/    
.tickLF.p.getModelTypes:{[componentId]
  componentId:$[`THIS~componentId;`$getenv `EC_COMPONENT_ID;componentId];
  tabs1:.cr.getCfgTab[componentId;`sysTable`table;`model];
  sources:.cr.getCfgTab[componentId;`sysTable;`modelSrc];
  .cr.loadCfg each (),exec finalValue from sources;
  tabs2:.cr.getCfgTab[;`sysTable;`model] (exec finalValue from sources) except componentId;
  tabs:tabs1,tabs2;
  :exec sectionVal!{((lower each .cr.p.simpleDataTypes),((`STRING`SYMBOL)!"Cs"))exec col2 from x}'[finalValue] from tabs;
  };    

/------------------------------------------------------------------------------/
/F/ Initialize default callbacks
.tickLF.p.initDefaultCallbacks:{[]
  {key[x] set' value[x]} .sub.tickLF.default;
  };

/------------------------------------------------------------------------------/
/F/ initialization
/E/ config:.tickLF.cfg;
/E/ .tickLF.p.init[config]
.tickLF.p.init:{[config]


  .cb.add[`.z.pc;`.tickLF.p.pc];
  // load configuration
  tabsCfg:config[`tables]; tabs:tabsCfg[`table];
  if[count missing:tabs where not tabs in tables[];
    .log.error[`tickLF] "Missing data model for table(s): ",.Q.s1[missing];
    ];
  if[count noSym:where not `sym in/:cols each tabs;
    .log.error[`tickLF] "`sym column is mandatory in tickLF tables - it is missing in the following tables ", .Q.s1[tabs noSym];
    ];
  if[count symType:where not "s"~/:symTypeVals:{exec first t from meta x where c=`sym}each tabs;
    .log.error[`tickLF] "`sym column should be of type symbol - it is missing in the following tables ", .Q.s1[(tabs symType),'(symTypeVals symType)];
    ];
  .tickLF.p.initDefaultCallbacks[];
  tabs:tabs where tabs in tables[];
  tabsCfg:select from tabsCfg where table in tabs;
  // init journals
  .tickLF.p.closeJrn each where not null .tickLF.jrnHnd;
  .tickLF.p.initJrn[tabs;config`jrn];
  // setup default validation
  tabsCfg:update enrichPlug:1b from tabsCfg where table in  key .tickLF.plug.enrich;
  tabsCfg:update validatePlug:1b from tabsCfg where table in  key .tickLF.plug.validate;
  .tickLF.p.addValidFunc[tabsCfg];
  .tickLF.p.addActionJrn[tabsCfg];
  // setup status updating
  sStat:tabs where tabsCfg[`status];
  .tickLF.updStatus[sStat]:.tickLF.p.updStatus @/:sStat;
  // add tables to global variables
  $[count .tickLF.tables;`.tickLF.tables set 0!(1!.tickLF.tables) upsert 1!tabsCfg;`.tickLF.tables upsert tabsCfg];
  tabs2Add:tabs except .tickLF.t;
  .tickLF.t,:tabs2Add;
  .tickLF.w[tabs2Add]:count[tabs2Add]#();
  .tickLF.d:.sl.eodSyncedDate[];
  @[;`sym;`g#]each tabs2Add;
  inMemory:(exec table from tabsCfg where table in tabs2Add, memory=1b);
  .sub.tickLF.initAndReplayTab each flip ((flip (inMemory;0#/:value'[inMemory]));(flip (.tickLF.jrnI[inMemory];.tickLF.jrn[inMemory])));
  .tickLF.p.add[;`;0] each inMemory;
  .tickLF.PubNo[raze sStat,\:/:`.tickLF.upd`.tickLF.img`.tickLF.ups`.tickLF.del]:0;
  .tickLF.PubLast[raze  sStat,\:/:`.tickLF.upd`.tickLF.img`.tickLF.ups`.tickLF.del]:0Nz;
  .log.info[`tickLF] "Set tickLF timer to ", string .tickLF.cfg.timer;
  .tmr.start[`.tickLF.p.ts; .tickLF.cfg.timer;`.tickLF.p.ts];
  };

/==============================================================================/
.sl.main:{[flags]
  (set) ./:           .cr.getModel[`THIS];
  .tickLF.cfg.timer:  .cr.getCfgField[`THIS;`group;`cfg.timer];
  .tickLF.cfg.jrn:    .cr.getCfgField[`THIS;`group;`cfg.jrnDir];
  .tickLF.cfg.tables: `table xcol 0!.cr.getCfgPivot[`THIS;`table`sysTable;`validation`jrnSwitch`eodImg2Jrn`memory`status];
  .tickLF.cfg.types:  .tickLF.p.getModelTypes[`THIS];
  .sl.libCmd[];

  .tickLF.p.init[.tickLF.cfg];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`tickLF;`.sl.main;`];

/------------------------------------------------------------------------------/
\
