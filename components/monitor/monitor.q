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
/D/ 2012.04.10

/S/ Monitor component:
/S/ Responsible for:
/S/ - capturing various information relevant to the system monitoring and profiling

/S/ Captured information:
/S/ Captured information is grouped into following sections
/S/ - resources usage - memory, cpu (information based on q internal information and OS information)
/S/ - state (process state, number of fatals/errors/warnings, connections state, internal kdb+ state etc. )
/S/ - system events (like initialization of each component, subscription, journal replay)

/S/ List of monitored processes:
/S/ List of monitored processes is based on <.monitor.cfg.procMaskList> process mask list. 
/S/ Mask list is applied to process names defined in the main system configuration file (system.cfg). The list is periodically updated.
/S/ If a new process appears, it is added to the monitoring list <.monitor.status> and connection to the process is established with `eager mode.
/S/ If process disappears, it is removed from the monitoring list <.monitor.status> and connection to the process is closed.

/S/ Communication model:
/S/ Monitor is keeping opened connection to all monitored processes and regularly polling for status information. 
/S/ Different frequency can be set for each group of checks.
/S/ The primary goal for the communication protocol is to minimize time-footprint on the monitored servers. This is achieved by the following mechanism
/S/  - Checks are grouped and code for execution is optimized
/S/  - There is always at most one request per server at a time, next request is done only after getting response from the previous request
/S/ The consequence of this approach is the following, if monitored server for some reason will not respond for the probing check, 
/S/ it might cause a gap in monitor tables, i.e. no updates for some time from the malfunctioning server.
/S/
/S/ Additional monitoring information is retrieved using the yak service.

/S/ System events reader:
/S/ .monitor.cfg.eventDir directory is regularly checked in order to discover and process new event files.
/S/ Once event is discovered, it is processed, published to subscribers in correct form and archived in the backup directory.

/S/ Data publishing:
/S/ Data is published in tickHF (<tickHF.q>) protocol in the form of predefined tables.
/S/ All published messages are journalled in .monitor.cfg.jrn daily journal file.
/S/ Published data can be stored in rdb and hdb for later analysis or processed in any tickHF (<tickHF.q>) protocol-compatible tool e.g. stream process.

/S/ End of day actions: 
/S/ - eod of day message ".u.end[date]" is published to all subscribers; date parameter is equal to the day that has just ended
/S/ - monitor journal for completed day is closed; journal for new day is opened

/S/ Schema of monitor tables is described in <monitor.qsd>.

/T/ - q monitor.q

/------------------------------------------------------------------------------/
/                                 libraries                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";

.sl.init[`monitor];
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/handle"];
.sl.lib["qsl/u"];
.sl.lib["monitorStats"];

/------------------------------------------------------------------------------/
/F/ Information about subscription protocols supported by the monitor component.
/F/ This definition overwrites default implementation from qsl/sl library.
/F/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server - `PROTOCOL_TICKHF
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKHF};

/------------------------------------------------------------------------------/

/G/ Table describing status of all checks being done on monitored components.
/G/ One row contains information about state of one check dedicated to one server
/G/ (start code)
/G/ time:TIME               - information publish timestamp
/G/ sym:SYMBOL              - component name
/G/ hndStatus:SYMBOL        - component handle status
/G/ request:SYMBOL          - request id
/G/ check:SYMBOL            - request name
/G/ code:STRING             - request code
/G/ ts0_req:TIMESTAMP       - timestamp of request sending 
/G/ ts1_befExec:TIMESTAMP   - beginning of request execution
/G/ ts2_afterExec:TIMESTAMP - end of request execution
/G/ ts3_res:TIMESTAMP       - timestamp of result retrieving
/G/ status:SYMBOL           - status of the check
/G/ interval:INT            - interval of check execution
/G/ requestId:LONG          - current request id
/G/ (end)
.monitor.status:([]time:`time$(); sym:`symbol$(); hndStatus:`symbol$();request:`symbol$();check:`symbol$();code:();
  ts0_req:`timestamp$(); ts1_befExec:`timestamp$(); ts2_afterExec:`timestamp$(); ts3_res:`timestamp$(); 
  status:`symbol$(); interval:`int$(); requestId:`long$());


/------------------------------------------------------------------------------/
/                               checks                                         /
/------------------------------------------------------------------------------/
.monitor.p.commonCheck:([]checkGr:`base;check:`proc;code:enlist".sl.componentId";resType:-11h);

.monitor.p.commonCheck,:([]checkGr:`sysResUsageFromQ;
  check:  enlist `memState;
  code:   enlist ".Q.w[]";
  resType:enlist 99h);

.monitor.p.commonCheck,:([]checkGr:`sysLogStatus;
  check:  enlist `logHist;
  code:   enlist ".log.status";
  resType:enlist 99h);

.monitor.p.commonCheck,:([]checkGr:`sysConnStatus;
  check:  (enlist `hndStatus);
  code:   (enlist "delete handle, ashandle from .hnd.status");
  resType:(enlist 99h));

.monitor.p.commonCheck,:([]checkGr:`sysQueues;
  check:  (enlist `tcpQueue);
  code:   (enlist "(sum;count)@\\:/:(.z.W)");
  resType:(enlist 99h));

/------------------------------------------------------------------------------/
/                        send request                                          /
/------------------------------------------------------------------------------/
/F/ timer function to execute scheduled checks
/F/- end of day trigger
/F/- selection of checks that should be executed (based on previous result and configured frequency)
/F/- update of monitor status table
/F/- execute all checks asynchronously
/P/ id - 
/E/.monitor.p.tsCheck `
.monitor.p.tsCheck:{[id]
  ts:.sl.zp[];
  if[.sl.zd[]>.monitor.p.date;  //end of day
    .log.info[`monitor] "end of day";
    .u.end[.monitor.p.date];
    .monitor.p.date:.sl.zd[];
    .monitor.p.initJrn[.monitor.p.date];
    ];

  toSend:exec i from .monitor.status where ts>ts0_req+1000000j*`long$interval, status<>`reqSent, hndStatus=`open, (not null interval)or(request=`base);
  update time:.sl.zt[], ts0_req:ts, ts1_befExec:0Np, ts2_afterExec:0Np, ts3_res:0Np, status:`sending, 
    requestId:.monitor.p.lastReqId+til count[toSend] from `.monitor.status where i in toSend;
  .monitor.p.lastReqId+:count toSend;
  req:exec first[sym](;)\:requestId!code by sym from .monitor.status where i in toSend; //request, check, 
    re::.pe.dotLog[`monitor;`.monitor.p.sendReq;;`reqFailed;`warn]each req;
  update time:.sl.zt[], status:re sym from `.monitor.status where i in toSend;
  if[.monitor.cfg.monitorStatusPublishing;
    .monitor.pub[`sysMonitorStatus;select from .monitor.status where i in toSend];
    ];

  .log.debug[`monitor] "Checks on timer: "," "sv"->"sv/:flip(string key@;","sv/:string value@)@\:group re;
  };

/------------------------------------------------------------------------------/
/F/ execute asynchronously selected checks on monitored process
/F/ Remote execution of code lines is done by calling function defined as a string
/F/ (so that it is working with the compiled code).
/F/ Code lines are executed one after another, each line in protected evaluation mode.
/F/ In case of signal returned from any fo the lines it will be returned as a pair (`signal;signalmessage)
/F/ Total time of execution of all code lines is measured and returned as a part of result.
/F/ Remote execution will return the result as a list in format (`.monitor.response; endTs; resultList; startTs)
/F/ resultList element is (`signal; signalMessage) in case of failure of execution of the check
/F/ As code is executed asynchronously, the result will arrive in the .z.ps callback.
/P/ dest:SYMBOL - server that will be inspected
/P/ ch:LIST[SYMBOL] - list of checks
/R/ :ENUM[`reqSent] -  in case of successful asynchronous execution
/E/`dest`requestIds`checks set' req 0
.monitor.p.sendReq:{[dest;ch]
  `ch set ch;
  remoteExec:"{[codeList](neg .z.w)res:(`.monitor.response;.sl.zp[];@[value;;{(`signal;x)}]each codeList;.sl.zp[])}";
  if[0i~.hnd.ah[dest];
    value value (remoteExec;ch);
    :`resReceived
    ];
  .hnd.ah[dest](remoteExec;ch);
  `reqSent
  };

/------------------------------------------------------------------------------/
/                        receive response                                      /
/------------------------------------------------------------------------------/
/F/handle asych response from the checks
/F/- discover if the message is a response from a check
/F/- update .monitor.status
/F/- publish .monitor.status
/F/- trigger result publishing
/P/ res - should match format returned by .monitor.remoteCheck function.
.monitor.response:{[ts1;data;ts0]
  ts:.sl.zp[];zw:.z.w;
  src:exec first server from .hnd.status where handle~'zw;
  sigId:`signal~'first each data;
  update time:.sl.zt[], ts1_befExec:ts0, ts2_afterExec:ts1, ts3_res:ts, 
    status:?[sigId requestId;`resSignal;`resReceived] from `.monitor.status where sym=src, requestId in key sigId;
  if[.monitor.cfg.monitorStatusPublishing;
    .monitor.pub[`sysMonitorStatus;select from .monitor.status where sym=src, requestId in key sigId];
    ];
  if[count where sigId;
    .log.info[`monitor] each exec ("Check ",/:string[request],'".",/:string[check],' " failed on ",/:string[sym],' " with signal '",/:(last'[data]requestId))
    from .monitor.status where sym=src, requestId in where sigId
    ];
  r:exec(` sv' request,'check)!data requestId from .monitor.status where requestId in key data, status=`resReceived;
  .monitor.p.publishResult[src;r];
  };

/------------------------------------------------------------------------------/
/F/ Publish monitoring update
// convert results to monitor data model which is ready for publishing
/P/ src
/P/ r
//- structure result into monitoring update
//- publish 
//r: last .monitor.tmp.r
.monitor.p.publishResult:{[src;r]
  `.monitor.tmp.r set (.sl.zt[];src;r);
  if[all `base.proc`sysConnStatus.hndStatus in key r;
    sysConn:flip`time`sym`connTo`connStatus`connTimeout! (.sl.zt[];r`base.proc),
      .monitor.p.getHnd[;r`sysConnStatus.hndStatus]'[`server`state`timeout];
    sysConnStatus:`time`sym xcols 0!select last time, 
      connRegistered:`$","sv connTo where connStatus=`registered, 
      connOpen:      `$","sv connTo where connStatus=`open, 
      connClosed:    `$","sv connTo where connStatus=`closed,
      connLost:      `$","sv connTo where connStatus=`lost,
      connFailed:    `$","sv connTo where connStatus=`failed
    by sym from update string connTo from sysConn;
    .monitor.pub[`sysConnStatus;sysConnStatus];
    ];

  if[all `base.proc`sysLogStatus.logHist in key r;
    sysLogStatus:([]time:.sl.zt[];sym:enlist r`base.proc;
      logFatal:r[`sysLogStatus.logHist;`FATAL];logError:r[`sysLogStatus.logHist;`ERROR]; logWarn:r[`sysLogStatus.logHist;`WARN]);
    .monitor.pub[`sysLogStatus;sysLogStatus];
    ];
  if[all `base.proc`sysResUsageFromQ.memState in key r;
    sysResUsageFromQ:([]time:.sl.zt[];sym:enlist r`base.proc;
      memPeak:r[`sysResUsageFromQ.memState;`peak]; memUsed:r[`sysResUsageFromQ.memState;`used];
      memSyms:r[`sysResUsageFromQ.memState;`syms]; memSymw:r[`sysResUsageFromQ.memState;`symw]);
    .monitor.pub[`sysResUsageFromQ;sysResUsageFromQ];
    ];
  };

/------------------------------------------------------------------------------/
/F/read handler status
.monitor.p.getHnd:{[col;hndTab]
  handler:{if[not x~".hnd.status";.log.debug[`monitor] " cannot read handler status: signal:",x];:()};
  :.[{[col;hndTab] ?[hndTab;enlist (not;(null;`server));();col]}; (col;hndTab);handler];
  };

/------------------------------------------------------------------------------/
/F/ publish update of one of sysTable managed by the monitor process.
/F/ - write update to the journal
/F/ - update .u.i
/F/ - publish data to the subscribers
/F/ - update internal mrvs cache
/P/ tab:SYMBOL - one of published system tables generated by monitor e.g. `sysConnStatus
/P/ data:TABLE - update table with columns matching to the model of tab parameter
.monitor.pub:{[tab;data]
  //store data in journal [optional by configuration]
  .monitor.p.jrnH enlist (`jUpd;tab;data);

  .u.i+:1;
  //publish data
  .u.pub[tab;data];
  //keep mrvs [optional by configuration]
  (` sv``mrvs,tab) upsert select by sym from data;
  };

/------------------------------------------------------------------------------/
/                         initialization                                       /
/------------------------------------------------------------------------------/
/F/ initialize monitor process
/F/- read and analyze yak file
/F/- initialize monitor status
/F/- initialize timer
/F/- initialize publishing
/F/- initialize monitor journal
/F/- initialize connections to all monitored servers
.monitor.p.init:{[]
  .event.at[`monitor; `.monitor.p.initJrn; .monitor.p.date:.sl.zd[]; (); `info`info`error; "initializing monitor journal"];
  .event.at[`monitor; `.u.init; (); (); `info`info`error; "initializing publish library"];
  .event.at[`monitor; `.monitor.p.initTimers; (); (); `info`info`error; "initializing timers"];
  .event.at[`monitor; `.monitor.p.initRequestId; (); (); `info`info`error; "initializing requestId"];
  .event.at[`monitor; `.monitor.p.initMrvs;();();`info`info`error; "initializing mrvs tables"];
  };

/------------------------------------------------------------------------------/
/F/initialize monitor journal - should be executed at eod
.monitor.p.initJrn:{[date]
  if[`jrnH in key .monitor.p; @[hclose;.monitor.p.jrnH;::]];
  .u.L:.monitor.p.jrn:`$string[.monitor.cfg.jrn],string[date];
  if[()~key .monitor.p.jrn;
    .monitor.p.jrn set (); 
    ];
  .u.i:-11!(-2;.monitor.p.jrn);
  .monitor.p.jrnH:hopen .monitor.p.jrn;
  };

/------------------------------------------------------------------------------/
.monitor.p.initMrvs:{[]
  `.mrvs set tables[]!{select by sym from x}each tables[];
  };

/------------------------------------------------------------------------------/
.monitor.p.initRequestId:{[]
  if[not `lastReqId in key`.monitor.p;.monitor.p.lastReqId:0j];
  };

/------------------------------------------------------------------------------/
.monitor.p.initTimers:{[]
  .tmr.start[`.monitor.p.tsCheck;.monitor.cfg.checksInterval;`monitor];
  .tmr.start[`.monitor.p.yakTs;.monitor.cfg.yakCheckInterval;`yak];
  .tmr.start[`.monitor.p.tsEventsRead;.monitor.cfg.schedule[`sysEvent];`eventReader];
  .tmr.start[`.monitor.p.diskTs;.monitor.cfg.diskCheckInterval;`diskCheck];
  };

/------------------------------------------------------------------------------/
/                       processes list management                              /
/------------------------------------------------------------------------------/
/F/capture status from yak - should be executed on timer
/F/ - retreive update from yak
/F/ - publish sysStatus and sysResUsageFromOs
/F/ - .monitor.p.addProcesses/.monitor.p.removeProcesses processes in case state changed.
.monitor.p.yakTs:{[x]
  list:$[`ALL in .monitor.cfg.procMaskList;"\"*\"";" "sv string .monitor.cfg.procMaskList];
  yakCmd:"yak . ",list," -f\"uid:1#pid:1#port:1#executed_cmd:1#status:11#started:1#started_by:1#stopped:1#cpu_user:1#cpu_sys:1#cpu_usage:1#mem_rss:1#mem_vms:1#mem_usage:1\" -d,";
  if[`warn~yakRes:.pe.atLog[`monitor;`.q.system;yakCmd;`warn;`warn];:()];
  yakRaw:`sym xcol ("SIISSZSZFFFFJF"; enlist ",")0: yakRes;

  sysResUsageFromOs:select time:.sl.zt[], sym, cpuUser:cpu_user, cpuSys:cpu_sys, cpuUsage:cpu_usage, memRss:mem_rss, memVms:mem_vms, memUsage:mem_usage from yakRaw;
  .monitor.pub[`sysResUsageFromOs;sysResUsageFromOs];

  sysStatus:select time:.sl.zt[], sym, pid, port, command:executed_cmd, status, started, startedBy:started_by, stopped from yakRaw;
  .monitor.pub[`sysStatus;sysStatus];

  yakRunning:exec sym from sysStatus where status in `RUNNING`DISTURBED;
  yakStopped:exec sym from sysStatus where not status in `RUNNING`DISTURBED;
  currentProc:exec server from .hnd.status where not state in``closed;
  if[count toAdd:yakRunning except currentProc;
    .event.at[`monitor; `.monitor.p.addProcesses; toAdd; (); `info`info`error; "Adding processes for monitoring:", .Q.s1[toAdd]];
    ];
  if[count toRemove:currentProc inter yakStopped;
    .event.at[`monitor; `.monitor.p.removeProcesses; toRemove; (); `info`info`error; "Removing processes from monitoring:", .Q.s1[toRemove]];
    ];
  };

/F/ add process to monitoring
/F/ - add/refresh record in .monitor.status
/F/ - publish sysMonitorStatus table
/F/ - define po and pc callbacks 
/F/ - open connection using eager mode
/P/ new:LIST[SYMBOL] - list of symbols with processes names
.monitor.p.addProcesses:{[new]
  statusUpd:update interval:.monitor.cfg.schedule request, requestId:0j from ungroup
  ([]time:.sl.zt[]; sym:new; hndStatus:`none;
    request:count[new]#enlist .monitor.p.commonCheck[`checkGr];
    check:count[new]#enlist .monitor.p.commonCheck[`check];
    code:count[new]#enlist .monitor.p.commonCheck[`code];
    ts0_req:0Wp; ts1_befExec:0Np; ts2_afterExec:0Np; ts3_res:0Np; status:`);
  delete from `.monitor.status where sym in new;
  .monitor.status,:statusUpd;
  if[.monitor.cfg.monitorStatusPublishing;
    .monitor.pub[`sysMonitorStatus;statusUpd];
    ];

  .hnd.poAdd[;`.monitor.p.po]each new;
  .hnd.pcAdd[;`.monitor.p.pc]each new;
  .hnd.hopen[new;10i;`eager];
  };

/F/ remove process from monitoring
/F/ - disconnect process
/F/ - publish sysMonitorStatus table
/F/ - publish empty entries - reset status of the component
/P/ old: LIST[SYMBOL] - list of processesto remove
/E/old:enlist`tick
.monitor.p.removeProcesses:{[old]
  .hnd.hclose old;
  full:exec server from .hnd.status where server in old;
  .monitor.pub[`sysStatus;update time:.sl.zt[], sym:full from count[full]#sysStatus];
  .monitor.pub[`sysConnStatus;update time:.sl.zt[], sym:full from count[full]#sysConnStatus];
  };

/------------------------------------------------------------------------------/
/F/ handling of port close from subscribers
/F/- update status
/P/ s:SYMBOL - component name
.monitor.p.pc:{[s]
  .log.info[`monitor] "pc for ", string[s];
  update time:.sl.zt[], hndStatus:.hnd.status[s][`state] from `.monitor.status where sym=s;
  if[.monitor.cfg.monitorStatusPublishing;
    .monitor.pub[`sysMonitorStatus;select from .monitor.status where sym=s];
    ];
  };

/------------------------------------------------------------------------------/
/F/ handling of port open from subscribers
/F/- update status
/P/ s:SYMBOL - component name
/E/s:`tick
.monitor.p.po:{[s]
  `.monitor.tmp.po set s;
  .log.info[`monitor] "po for ", string[s];

  //initialize .monitor.status for new connection
  update time:.sl.zt[], hndStatus:.hnd.status[s][`state], ts0_req:0Wp, ts1_befExec:0Np, ts2_afterExec:0Np, ts3_res:0Np, status:` from `.monitor.status where sym=s;
  if[.monitor.cfg.monitorStatusPublishing;
    .monitor.pub[`sysMonitorStatus;select from .monitor.status where sym=s];
    ];
  };
/------------------------------------------------------------------------------/
//                    events processing                                       //
/------------------------------------------------------------------------------/
/E/.monitor.p.tsEventsRead .sl.zt[]
.monitor.p.tsEventsRead:{[x]
  newFiles:key[.monitor.cfg.eventDir];
  newFiles:newFiles where not newFiles like "*#";
  newFiles:newFiles where not newFiles like "*archive*";
  //process newEvents
  .monitor.p.processEventFile each newFiles;
  };

/------------------------------------------------------------------------------/
/F/ process event - convert into table update and publish using .monitor.pub[]
/P/ file:Symbol - file name
.monitor.p.processEvent:{[filePath]
  newEvent:get filePath;
  if[10h=type newEvent[`funcName];newEvent[`funcName]:`$newEvent[`funcName]];
  common:.sl.zt[],newEvent[`componentId`module`level`tsId`funcName`descr`status];

  //generic sysEvent
  if[newEvent[`status]~`EVENT_STARTED;
    .monitor.pub[tab:`sysEvent;data:flip cols[sysEvent]!enlist each common, 0N, 0Nt];
    ];
  if[newEvent[`status]~`EVENT_PROGRESS;
    .monitor.pub[tab:`sysEvent;data:flip cols[sysEvent]!enlist each common, newEvent`progress`timeLeft];
    ];
  if[newEvent[`status]~`EVENT_FAILED;
    .monitor.pub[tab:`sysEvent;data:flip cols[sysEvent]!enlist each common, 0N, 0Nt];
    ];
  if[newEvent[`status]~`EVENT_COMPLETED;
    .monitor.pub[tab:`sysEvent;data:flip cols[sysEvent]!enlist each common, 100, 00:00:00.000];
    ];
  };


/------------------------------------------------------------------------------/
//backupDir:.monitor.cfg.eventDir, "/archive/", string[.sl.zd[]],"/";
.monitor.p.backupEvent:{[eventDir;file;backupDir]
  (hsym`$backupDir,"/lastEvent") set file;
  system "mv ", eventDir,string[file], " ",backupDir;
  };

/------------------------------------------------------------------------------/
//file:first newFiles
.monitor.p.processEventFile:{[file]
  .pe.atLog[`monitor;`.monitor.p.processEvent;`$string[.monitor.cfg.eventDir], string[file];`;`debug];
  .pe.dotLog[`monitor;`.monitor.p.backupEvent;(1_string[.monitor.cfg.eventDir];file;1_string[.monitor.cfg.eventDir], "/archive/", string[.sl.zd[]],"/");`;`debug];
  };

/------------------------------------------------------------------------------/
//                    disk usage                                              //
/------------------------------------------------------------------------------/

/F/ calcualtes used disk space in kbytes, including subdirectories
/P/ path - path to be checked
/E/.monitor.p.du`:/home/kdb/devSystem/data/in.tickHF
.monitor.p.du:{[path]
  if["w"~first string .z.o;:0Nj]; // return null on Windows
  `long$("J"$first"\t"vs first system"du -sb ",1_string path)%1024
  };

/F/ calculates disk free space using df command from unix
/P/ p:SYMBOL - path to be checked
/R/ :TABLE(`path`filesystem`blocks1K`totalBytesUsed`totalBytesAvailable`totalCapacityPerc`mountedOn!(SYMBOL;SYMBOL;LONG;LONG;LONG;SYMBOL;SYMBOL)) - 1 row table with statistics
/E/.monitor.p.df `:/home/kdb/devSystem/data/access.ap2
.monitor.p.df:{[p]
  columns:`path`filesystem`blocks1K`totalBytesUsed`totalBytesAvailable`totalCapacityPerc`mountedOn;
  if["w"~first string .z.o; // return nulls on Windows
	:flip columns!(enlist p;enlist `;enlist 0Nj;enlist 0Nj;enlist 0Nj;enlist `;enlist `)
	]; 
  flip columns!enlist[p],"SJJJSS"$flip trim{(0,where -1=deltas " "=x)_x} each 1_system"df -P ",1_string p
  };

/F/ calculates disk usage for all paths in the configuration with name `binPath`etcPath`dataPath`logPath
/F/ result is published as sysDiskUsage table
/F/ function will return empty values if df/du commands are missing (e.g. in windows environment)
/E/select sum procBytesUsed, last totalBytesUsed, last totalBytesAvailable by time, filesystem from sysDiskUsage
.monitor.p.diskTs:{[]
  pathsToCheck:`binPath`etcPath`dataPath`logPath;
  diskStats:select time:.sl.zt[], sym:subsection, pathName:varName, path:finalValue from .cr.getCfgTab[`ALL;`group;pathsToCheck];
  diskStats:diskStats lj delete totalCapacityPerc from 1!raze exec @[.monitor.p.df;;()]'[path] from diskStats;
  diskStats:cols[sysDiskUsage] xcols update procBytesUsed:`long$@[.monitor.p.du;;0Nj]'[path] from diskStats;
  .monitor.pub[`sysDiskUsage;diskStats];
  };

.monitor.p.initSysTables:{[]
  sysStatus::([]time:`time$(); sym:`symbol$(); pid:`int$(); port:`int$(); command:`symbol$(); status:`symbol$(); started:`datetime$(); startedBy:`symbol$(); stopped:`datetime$());
  sysConnStatus::([]time:`time$(); sym:`symbol$(); connRegistered:`symbol$(); connOpen:`symbol$(); connClosed:`symbol$(); connLost:`symbol$(); connFailed:`symbol$());
  sysLogStatus::([]time:`time$(); sym:`symbol$(); logFatal:`int$(); logError:`int$(); logWarn:`int$());
  sysResUsageFromQ::([]time:`time$(); sym:`symbol$(); memPeak:`long$(); memUsed:`long$(); memSyms:`long$(); memSymw:`long$());
  sysResUsageFromOs::([]time:`time$(); sym:`symbol$(); cpuUser:`float$(); cpuSys:`float$(); cpuUsage:`float$(); memRss:`float$(); memVms:`long$(); memUsage:`float$());
  sysEvent::([]time:`time$(); sym:`symbol$(); module:`symbol$(); eventLevel:`symbol$(); tsId:`timestamp$(); funcName:`symbol$(); descr:(); status:`symbol$(); progress:`int$(); timeLeft:`time$());
  sysMonitorStatus::([]time:`time$(); sym:`symbol$();hndStatus:`symbol$();request:`symbol$();check:`symbol$();code:();
    ts0_req:`timestamp$();ts1_befExec:`timestamp$();ts2_afterExec:`timestamp$();ts3_res:`timestamp$();
    status:`symbol$();interval:`int$();requestId:`long$());
  sysKdbLicSummary::([] time:`time$();sym:`symbol$();maxCoresAllowed:`int$();expiryDate:`date$();updateDate:`date$();cfgCoreCnt:`int$());
  sysFuncSummary::([] time:`time$();sym:`symbol$();procNs:`symbol$();funcCnt:`int$();func:());
  sysHdbStats::([] time:`time$();sym:`symbol$();hdbDate:`date$();hour:`time$();table:`symbol$();totalRowsCnt:`long$();
    minRowsPerSec:`long$();avgRowsPerSec:`long$();medRowsPerSec:`long$();maxRowsPerSec:`long$();dailyMedRowsPerSec:`long$());
  sysHdbSummary::([] time:`time$();sym:`symbol$();path:`symbol$();hdbSizeMB:`long$();hdbTabCnt:`long$();tabList:());
  sysDiskUsage::([]time:`time$(); sym:`symbol$();pathName:`symbol$();path:`symbol$();filesystem:`symbol$();mountedOn:`symbol$();
    blocks1K:`long$();totalBytesAvailable:`long$();totalBytesUsed:`long$();procBytesUsed:`long$());
  };

/==============================================================================/
/F/ the main entry point run on start
/P/ flags - currently unused

.sl.main:{[flags]

  .cr.loadCfg[`ALL];

  .monitor.p.initSysTables[];
  
  .monitor.cfg.procMaskList:  .cr.getCfgField[`THIS;`group;`cfg.procMaskList];

  procList:exec subsection from .cr.getCfgTab[`ALL;`group;`type] where finalValue like "q:*";
  nsList:`$distinct first each "." vs/: string procList;
  if[count unknown:.monitor.cfg.procMaskList where not .monitor.cfg.procMaskList in nsList,procList,`ALL;
    .log.error[`monitor] "Unknown processes in the configuration cfg.procMaskList will be excluded from monitoring:", .Q.s1[unknown];
    .monitor.cfg.procMaskList:.monitor.cfg.procMaskList except unknown;
    ];

  .monitor.cfg.jrn:           .cr.getCfgField[`THIS;`group;`cfg.jrn];
  .monitor.cfg.eventDir:      .cr.getCfgField[`THIS;`group;`cfg.eventDir];

  .monitor.cfg.monitorStatusPublishing:.cr.getCfgField[`THIS;`group;`cfg.monitorStatusPublishing];
  .monitor.cfg.schedule:exec sectionVal!finalValue from .cr.getCfgTab[`THIS;`sysTable;`frequency];
  if[0=count .monitor.cfg.schedule;
    .log.error[`monitor] "There is no [sysTable:*] entry which is assigned to the ",string[.sl.componentId]," process in dataflow.cfg. There must be at least one [sysTable:*] with the [[",string[.sl.componentId],"]] process subsection.";
    exit 1;
    ];
  .monitor.cfg.yakCheckInterval:min .monitor.cfg.schedule[`sysStatus`sysResUsageFromQ];
  .monitor.cfg.checksInterval:min .monitor.cfg.schedule[`sysConnStatus`sysLogStatus`sysResUsageFromQ];
  .monitor.cfg.diskCheckInterval:.monitor.cfg.schedule[`sysDiskUsage];

  .sl.libCmd[];
  .monitor.p.init[];
  sysHdbSummaryProcList:raze exec finalValue from .cr.getCfgTab[`THIS;`sysTable;`hdbProcList] where sectionVal=`sysHdbSummary;
  .monitor.cfg.sysHdbSummaryPathDict:sysHdbSummaryProcList!.cr.getCfgField[;`group;`cfg.hdbPath] each sysHdbSummaryProcList;
  .monitor.cfg.sysHdbStatsProcList:raze exec finalValue from .cr.getCfgTab[`THIS;`sysTable;`hdbProcList] where sectionVal=`sysHdbStats;

  .monitor.cfg.sysFuncSummaryProcList:raze exec finalValue from .cr.getCfgTab[`THIS;`sysTable;`procList] where sectionVal=`sysFuncSummary;
  .monitor.cfg.sysFuncSummaryProcNs:raze exec finalValue from .cr.getCfgTab[`THIS;`sysTable;`procNs] where sectionVal=`sysFuncSummary;
  .monitor.cfg.dailyExecTimes:exec sectionVal!finalValue from .cr.getCfgTab[`THIS;`sysTable;`execTime];
  .tmr.runAt'[value .monitor.cfg.dailyExecTimes;` sv/:`.monitor.p.dailyExec,/:key .monitor.cfg.dailyExecTimes;key .monitor.cfg.dailyExecTimes];
  };


/------------------------------------------------------------------------------/
//initialization
.sl.run[`monitor;`.sl.main;`];

/------------------------------------------------------------------------------/
\

//----------------------------------------------------------------------------//
/
.hnd.status
.tmr.status
.monitor.status
.cb.status
.mrvs.sysStatus
count each .mrvs
.mrvs.sysConnStatus

.mrvs.sysMonitorStatus
.mrvs.sysResUsageFromOs

//select from .monitor.status where request=`sysStatus
model:.cr.getModel[`THIS];
