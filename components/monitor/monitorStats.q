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
/D/ 2012.04.10

/S/ Monitor component:
/-/ Responsible for:
/-/ - capturing system daily statistics
/-/ Note:
/-/ Schema of monitor tables is described in <monitor.qsd>.

/------------------------------------------------------------------------------/
/                         sysHdbSummary                                        /
/------------------------------------------------------------------------------/
.monitor.p.getHdbTabs:{[hdb]
  dir:hsym`$hdb;
  part:key[dir]like "????.??.??";
  tabs:key ` sv dir,key[dir]last where part;
  if[count key par:` sv dir,`par.txt;
    tabs:key last` sv/: raze pars,/:'key each pars:hsym each `$read0[par]
    ];
  tabs,:(key[dir]where not part)except `sym`par.txt;
  tabs
  };

/------------------------------------------------------------------------------/
/F/ Calculates hdb size.
.monitor.p.hdbSummary:{[path]
  if["w"~first string .z.o;:([]hdb:enlist `$path;sizeMB:0Nj)];
  sizeKB:.pe.atLog[`monitor;`.q.system;"du --max-depth=0 ",path;enlist"\t",path;`error];
  r:select hdb:`$path, sizeMB:1+`int$sizeKB%1024 from flip `dir`sizeKB!reverse "IS"$'flip"\t"vs/:sizeKB;
  if[count key par:hsym `$path,"/par.txt";
    tmp:raze .monitor.p.hdbSummary each read0 par;
    :select hdb:enlist`$path, sizeMB:sum sizeMB from r,tmp;
    ];
  :r
  };

/------------------------------------------------------------------------------/
.monitor.p.getHdbSummary:{[hdbProcToPathDict]
  `time`sym`path`hdbSizeMB`hdbTabCnt`tabList xcols update hdbTabCnt:count each tabList from 
  ([]time:.sl.zt[]; sym:key hdbProcToPathDict; path:value hdbProcToPathDict; 
    tabList:.monitor.p.getHdbTabs each 1_/:string value hdbProcToPathDict;
    hdbSizeMB:{exec first sizeMB from .monitor.p.hdbSummary x}each 1_/:string value hdbProcToPathDict)
  };

/------------------------------------------------------------------------------/
/                         sysHdbStats                                          /
/------------------------------------------------------------------------------/
.monitor.p.getOneHdbStats:{[hdbProc;day]
  defVal:([] hdbDate:`date$();hour:`time$();table:`symbol$();totalRowsCnt:`long$();minRowsPerSec:`long$();avgRowsPerSec:`long$();medRowsPerSec:`long$();maxRowsPerSec:`long$();dailyMedRowsPerSec:`long$());
  res:defVal,raze {[hdbProc;day;defVal;tab].pe.at[.hnd.h[hdbProc];(`.hdb.dataVolumeHourly;tab;day);{[x;defVal] :defVal}[;defVal]]}[hdbProc;day;defVal;] each .hnd.h[hdbProc]"tables[]";
  `time`sym xcols update time:.sl.zt[], sym:hdbProc from res
  };
/------------------------------------------------------------------------------/
.monitor.p.getHdbStats:{[hdbProcList;day]
  res:raze .monitor.p.getOneHdbStats[;day] each hdbProcList;
  res
  };

/------------------------------------------------------------------------------/
/                         sysFuncSummary                                       /
/------------------------------------------------------------------------------/
//server:`ap1;procNs:`.ns
.monitor.p.getRemoteFuncList:{[server;procNs] 
  funcList:@[.hnd.h[server];"\\f ",string procNs;::];
  if[string[procNs]~funcList;:`funcCnt`func!(0i;`symbol$())];
  if[0=count funcList;:`funcCnt`func!(0i;`symbol$())];
  funcWithNs:` sv/:(procNs(;)'funcList);
  `funcCnt`func!(`int$count funcWithNs;funcWithNs)
  };

/------------------------------------------------------------------------------/
/F/ Gets func stats.
.monitor.p.getFuncSummary:{[procList;procNs]
  toCheck:([]sym:procList)cross ([](),procNs);
  if[count notCfg:procList where not procList in (distinct .monitor.status[`sym]);
    .log.warn[`monitor]"Process: ",( "," sv string[notCfg]), " are either not added to the cfg.procMaskList in system.cfg [[admin.monitor]] or are not configured in system.cfg at all";
    .log.info[`monitor]"Process: ",( "," sv string[notCfg]), " will be excluded from the sysFuncSummary";
    toCheck:select from ([]sym:procList)cross ([](),procNs) where not sym in notCfg;
    ];
  if[not count toCheck; :0#([] time:enlist 0Nt; sym:`; procNs:`;funcCnt:0Ni; func:`)];
  funcStats:.pe.dotLog[`monitor;`.monitor.p.getRemoteFuncList;;`funcCnt`func!(0Ni;`symbol$());`error] each flip value flip toCheck;
  select time:.sl.zt[], sym, procNs,funcCnt, func from flip flip[toCheck],flip[funcStats]
  };

/------------------------------------------------------------------------------/
/                         sysKdbLicSummary                                     /
/------------------------------------------------------------------------------/
.monitor.p.getKdbLicSummary:{[]
  ([]time:enlist .sl.zt[]; sym:.sl.componentId; 
    maxCoresAllowed:first "I"$.z.l 0; 
    expiryDate:first "D"$.z.l 1; 
    updateDate:first "D"$.z.l 2; 
    cfgCoreCnt:.z.c)
  };

/------------------------------------------------------------------------------/
/                         one time exec triggers                               /
/------------------------------------------------------------------------------/
.monitor.p.dailyExec.sysHdbSummary:{
  .monitor.pub[`sysHdbSummary; .monitor.p.getHdbSummary[.monitor.cfg.sysHdbSummaryPathDict]];
  };

/------------------------------------------------------------------------------/
.monitor.p.dailyExec.sysHdbStats:{
  .monitor.pub[`sysHdbStats; .monitor.p.getHdbStats[.monitor.cfg.sysHdbStatsProcList;.sl.eodSyncedDate[]-1]];
  };

/------------------------------------------------------------------------------/
.monitor.p.dailyExec.sysFuncSummary:{
  .monitor.pub[`sysFuncSummary; .monitor.p.getFuncSummary[.monitor.cfg.sysFuncSummaryProcList;.monitor.cfg.sysFuncSummaryProcNs]];
  };

/------------------------------------------------------------------------------/
.monitor.p.dailyExec.sysKdbLicSummary:{
  .monitor.pub[`sysKdbLicSummary; .monitor.p.getKdbLicSummary[]];
  };

/------------------------------------------------------------------------------/
/

