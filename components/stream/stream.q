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

/S/ Stream component:
/S/ Responsible for:
/S/ - facilitating processing on stream of data using tickHF (<tickHF.q>) protocol
/S/
/S/ stream.q functionality:
/S/ - subscription to streaming data source (<tickHF.q>-compatible server)
/S/ - subscription to additional data sources (<tickLF.q>-compatible server)
/S/ - calculation of derived data e.g. mrvs, snapshots, etc.
/S/ - serving derived data in memory
/S/ - publishing and journalling of derived data
/S/ - savepoint functionality for faster recovery after component restart
/S/ - data caching facility
/S/ - high level plugin interface

/S/ Business logic:
/S/ - <stream.q> itself does not provide any business logic code for data processing
/S/ - specific functionality of data processing has to be loaded additionally in a form of a plugin code
/S/ - plugin code should be defined in a separate file and loaded into <stream.q> using -lib command line option, for example
/S/ (start code)
/S/ q stream.q -lib <plugin file>
/S/ (end)

/S/ Plugins:
/S/ *Defining plugin in "lowLevel" mode*
/S/ - provides more flexibility but requires more implementation
/S/ - definition of mode is done by implementation of direct callbacks from the data source
/S/ - plugin must implement *all* low-level callbacks
/S/ (start code)
/S/ jUpd[tabName;data] - callback function for retrieving high frequency data from journal file
/S/ upd[tabName;data]  - callback function for retrieving high frequency data from tick server
/S/ sub[server;schema] - callback invoked after subscription to tick server but before the journal replay
/S/ (end)
/S/ - timers can be defined if required using qsl/timer.q library (i.e. add new timer with <.tmr.start[]>)

/S/ *Defining plugin using "cache" mode*
/S/ - provides less flexibility but requires less implementation
/S/ - pre-defined callbacks implemented in "lowLevel" mode can be readily used
/S/ - following plugin functions must be defined in order to specify mode logic
/S/ (start code)
/S/ .stream.plug.init[] - invoked during initialization of stream process
/S/ .stream.plug.sub[]  - invoked after successful subscription to the data source
/S/ .stream.plug.ts[]   - invoked on timer with frequency defined via configuration entry cfg.tsInterval
/S/                       The timer is:
/S/                         - activated after .stream.plug.init[] callback
/S/                         - active during whole lifetime of stream process
/S/                       Notes: 
/S/                         - it is possible that .stream.plug.ts[] is invoked before .plug.stream.sub[] callback
/S/                         - .stream.plug.ts[] is invoked using protected execution mode
/S/                         - .stream.plug.ts[] is invoked directly before eod callback .stream.plug.eod[]
/S/ .stream.plug.eod[] - invoked after eod (end of day) event in stream process.
/S/ (end)
/S/ Functionality can be implemented using predefined helper interface
/S/ (start code)
/S/ .stream.initPub[]
/S/ .stream.pub[]
/S/ .stream.savepoint[]
/S/ (end)
/S/ *Predefined plugins*
/S/ There is a set of predefined plugins that are ready to use
/S/ mrvs - most recent values implemented in <streamMrvs.q>
/S/ (start code)
/S/ q stream.q -lib streamMrvs.q
/S/ (end)

/S/ snap - snapshoting implemented in <streamSnap.q>
/S/ (start code)
/S/ q stream.q -lib streamSnap.q
/S/ (end)

/S/ aggr - aggregation of data into buckets implemented in <streamAggr.q>
/S/ (start code)
/S/ q stream.q -lib streamAggr.q
/S/ (end)

/------------------------------------------------------------------------------/
/                               lib and etc                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`stream];

.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/handle"];
.sl.lib["qsl/sub"];
.sl.lib["qsl/u"];

/------------------------------------------------------------------------------/
/                              initialization                                  /
/------------------------------------------------------------------------------/
/F/ Stream main initialization function
/F/ - selection of stream mode - loading custom scripts
/F/ - initialization of stream journal
/F/ - initialization of publishing
/F/ - initialization of connections
/E/ .stream.p.init[]
.stream.p.init:{[]
  if[not `i in key .stream;.stream.i:(`symbol$())!(`long$())];
  .stream.p.srcSubscriptionOn:1b;
  .stream.date:.sl.eodSyncedDate[];

  .event.at[`stream;`.stream.p.initConnections;();`;`info`info`error; "initializing connections"];
  .event.at[`stream;`.stream.p.initPlugin;`;`;`info`info`error; ".stream.plug.init callback"];
  .event.at[`stream;`.stream.p.initJrn;.stream.date;`;`info`info`error; "[initializing] or [opening and replaying] journal file"];
  .event.at[`stream;`.stream.p.openConnections;();`;`info`info`error; "opening connections"];
  .tmr.start[`.stream.plug.ts;.stream.cfg.tsInterval;`.stream.plug.ts];
  };

/------------------------------------------------------------------------------/
.stream.p.initPlugin:{[]
  .stream.plug.init[];
  };

/------------------------------------------------------------------------------/
.stream.p.initConnections:{[]
  //prepare for subscription
  .stream.srcServers:exec distinct server from .stream.cfg.srcTab where subType=`tickHF;
  .hnd.poAdd[;`.stream.p.TickHFPo] each .stream.srcServers;
  .stream.tickLFServers:exec distinct server from .stream.cfg.srcTab where subType=`tickLF;
  .hnd.poAdd[;`.stream.p.TickLFPo] each .stream.tickLFServers;
  };

/------------------------------------------------------------------------------/
.stream.p.TickHFPo:{[src]
  .sub.tickHF.subscribe[src;exec tab from .stream.cfg.srcTab where server=src;`];
  };

/------------------------------------------------------------------------------/
.stream.p.TickLFPo:{[src]
  .sub.initCallbacks`PROTOCOL_TICKLF;
  .sub.tickLF.subscribe[src;exec tab from .stream.cfg.srcTab where server=src;`];
  };

/------------------------------------------------------------------------------/
.stream.p.openConnections:{[]
  //open connections
  if[count .stream.srcServers;
    if[.stream.p.srcSubscriptionOn;
      .hnd.hopen[.stream.srcServers;.stream.cfg.timeout;`eager];
      ];
    ];
    
  if[count .stream.tickLFServers;
    if[.stream.p.srcSubscriptionOn;
      .hnd.hopen[.stream.tickLFServers;.stream.cfg.timeout;`eager];
      ];
    ];

  .hnd.hopen[.stream.cfg.serverAux;.stream.cfg.timeout;`lazy];
  };

/------------------------------------------------------------------------------/
/F/Initialization of publishing, compatible with classic tick from kx (and tickHF)
/F/ - data model will be set to global namespace using provided table names
/F/ - `a attribute will be set on sym column
/F/ - .u.w will be set
/P/ model:LIST[PAIR(SYMBOL;MODEL)] - list of pairs (tableName;dataModel) that should be published, previous values will be overwritten
.stream.initPub:{[model]
  if[count missingSym:model[;0] where not `sym in/: cols each model[;1];
    .log.error[`stream] "missing sym column in tables ", .Q.s1 missingSym;
    '`missingSymCol
    ];
  {x set y} ./: model;         //use the same table names as source data model
  @[;`sym;`g#]each model[;0];
  .u.w:.u.t!(count .u.t::(),model[;0])#();
  .cb.add[`.z.pc;`.u.pc];
  };

/------------------------------------------------------------------------------/
/F/Initialization of journal for derived data stream
/F/ if journal was already open, it will be closed and re-opened
/P/ date:DATE - date of the journal
.stream.p.initJrn:{[date]
  //init journal
  if[not `jrnH in key .stream.p;.stream.p.jrnH:0N];
  if[`jrn in key .stream.p; @[hclose;.stream.p.jrnH;::]];
  .u.L:.stream.p.jrn:`$string[.stream.cfg.journal],string[date];
  if[()~key .stream.p.jrn;
    .stream.p.jrn set (); 
    ];
  .u.i:-11!(-2;.stream.p.jrn);
  .stream.p.jrnH:hopen .stream.p.jrn;
  };

/------------------------------------------------------------------------------/
/                              end of day                                      /
/------------------------------------------------------------------------------/
/F/ due to clash of .u.end name as library name and callback name it has to be renamed
.u.endPublish:.u.end;

/------------------------------------------------------------------------------/
/F/ End-Of-Day (eod) callback from subscribed server (e.g. tick)
/F/  - invoke final <.stream.plug.ts[]> callback before eod
/F/  - invoke <.stream.plug.eod[]> callback
/F/  - switch journal file for derived data
/F/  - republish end of day message (<.u.end>) to subscribers (if stream is working as publisher)
/P/ date:DATE - eod date (in most cases current date)
/E/ date:.z.d
.u.end:{[date]
  if[date<.stream.date;
    .log.info[`stream] "Eod process was called already. Further eod activities won't be performed";
    :();
    ];
  .stream.date+:1;
  
  .log.info[`stream] "end of day ", string[date];
  .event.at[`stream;`.stream.plug.ts;date+24:00:00.000000;`;`info`info`error; "final .stream.plug.ts callback before eod"];
  .event.at[`stream;`.stream.plug.eod; date;`;`info`info`error; ".stream.plug.eod callback"];
  if[`w in key .u;
    .event.at[`stream;`.u.endPublish; date;`;`info`info`error; "publish eod to subscribers"];
    ];
  .event.at[`stream;`.stream.p.initJrn; date+1;`;`info`info`error; "rollover of journal file"];
  .stream.i:(`symbol$())!(`long$());
  };

/------------------------------------------------------------------------------/
/                              publishing                                      /
/------------------------------------------------------------------------------/
/F/ publish derived data stream
/F/  - store the data in the journal for derived data
/F/  - increase .u.i counter
/F/  - publish the data to the subscribers using <u.q> library
/P/ tab:SYMBOL - published table name
/P/ data:TABLE - table with published update
.stream.pub:{[tab;data]
  if[0=count data;:()];
  //store data in journal [optional by configuration]
  .stream.p.jrnH enlist (`jUpd;tab;value flip data);
  .u.i+:1;
  //publish data
  .u.pub[tab;data];
  };

/------------------------------------------------------------------------------/
/                               modes                                          /
/------------------------------------------------------------------------------/
/F/ initialize plugin definition mode, currently supported modes
/F/  - lowLevel - all low level callbacks must be defined by the plugin
/F/  - cache - data cached on upd, calculation is done in timer callback
/P/ mode:ENUM[`lowLevel`cache] - plugin definition mode 
/E/ .stream.initMode[`cache]
.stream.initMode:{[mode]
  .stream.mode:mode;
  .log.info[`stream] "Plugin definition mode:", string[mode];
  if[mode ~ `lowLevel;
    :()
    ];
  if[mode ~ `cache;
    .stream.p.initCache[];
    :();
    ];
  .log.error[`stream] "mode not supported:", string[mode];
  };

/------------------------------------------------------------------------------/
/                               cache                                          /
/------------------------------------------------------------------------------/
.stream.p.jUpd:{[t;d]
  if[t in .stream.cfg.model[;0];
    if[.stream.skip[t]<.stream.i[t]+:count first d;
      .stream.cacheNames[t] insert d;
      if[(first first d)>.stream.lastTs+.stream.cfg.tsInterval;
        .stream.lastTs:(first first d);
        .stream.plug.ts[.stream.date+.stream.lastTs];
        ];
      ];
    ];
  };


/------------------------------------------------------------------------------/
.stream.p.upd:{[t;d]
  .stream.i[t]+:count d;
  .stream.cacheNames[t] insert d;
  };

/------------------------------------------------------------------------------/
.stream.p.initCache:{[]
  .stream.cacheNames:{x!` sv/:`.cache,/:x}exec tab from .stream.cfg.srcTab where subType=`tickHF;
  {.stream.cacheNames[x] set y} ./:.stream.cfg.model where .stream.cfg.model[;0] in exec tab from .stream.cfg.srcTab where subType=`tickHF;
  `sub set .stream.p.sub;
  };


/------------------------------------------------------------------------------/
/F/ State of the plugin can be periodically saved. In case process is disrupted (e.g. restarted) and then connection is restored
/F/ - plugin needs to return to its most recent state prior to the disruption based on the data taken from the last savepoint
/F/ - journal's data will be replayed from the point where the last savepoint was called until the time connection was restored
/P/ savepointData - should contain all data required to recover after restart
.stream.savepoint:{[savepointData]
  //save .stream.i and savepointData
  (`$string[.stream.cfg.savepointFile],string[.stream.date]) set (.stream.i;savepointData);
  };

/F/ Initialization of subscription callback
/F/ - initialize .stream.skip basing on data from savepoint file
/F/ - initialize .stream.lastTs with midnight
/F/ - invoke .stream.plug.sub callback using data from savepoint file

.stream.p.sub:{[x;y]
  savepointFile:(`$string[.stream.cfg.savepointFile],string[.stream.date]);
  savepoint:$[not ()~key savepointFile;get savepointFile;(()!`long$();(::))];
  .stream.skip:savepoint[0];
  `upd  set .stream.p.upd;
  `jUpd set .stream.p.jUpd;
  .log.info[`stream] "Recovery using savepoint: First ", .Q.s1[.stream.skip], " messages will be skipped during the journal replay.";
  .stream.lastTs:00:00:00.000;
  {[x] .stream.i[x]:0j;delete from .stream.cacheNames[x]} each exec tab from .stream.cfg.srcTab where subType=`tickHF, server=x;
  .event.dot[`stream;`.stream.plug.sub;(x;y;savepoint[1]);`;`info`info`error; ".stream.plug.sub callback"];
  };

/==============================================================================/
/F/ script startup function
.sl.main:{[flags]
  srcTab:.cr.getCfgPivot[`THIS;`table`sysTable;`srcTickLF`srcTickHF];
  .stream.cfg.srcTab:(select tab:sectionVal, server:srcTickHF, subType:`tickHF from srcTab where srcTickHF<>`),(select tab:sectionVal, server:srcTickLF, subType:`tickLF from srcTab where srcTickLF<>`);
  if[0=count src:exec distinct server from .stream.cfg.srcTab where subType=`tickHF;
    .log.error[`stream] "Data source server should be specified (srcTickHF field in dataflow.cfg)";
    :()
    ];
  if[count multiSource:select server by tab from .stream.cfg.srcTab where 1<(count;server) fby tab;
    .log.error[`stream] each exec "Forbidden multiple sources for table "(,)/:string[tab](,)'":"(,)/:.Q.s1'[server] from multiSource;
    :()
    ];
  .stream.cfg.model:.cr.getModel[`THIS];

  .stream.cfg.timeout:       .cr.getCfgField[`THIS;`group;`cfg.timeout];
  .stream.cfg.tsInterval:    .cr.getCfgField[`THIS;`group;`cfg.tsInterval];
  .stream.cfg.serverAux:     .cr.getCfgField[`THIS;`group;`cfg.serverAux];
  .stream.cfg.journal:       .cr.getCfgField[`THIS;`group;`cfg.journal];
  .stream.cfg.savepointFile: .cr.getCfgField[`THIS;`group;`cfg.savepointFile];

  .sl.libCmd[];

  .stream.p.init[];
  };

/------------------------------------------------------------------------------/
/F/ By default subscription to the source server is made in po (port open) callback, directly after connection to the source server is opened.
/F/ This behaviour can be changed by switching the initial subscription off. Responsibility for subscription invocation is then shifted to the plugin developer.
.stream.srcSubscriptionOff:{[]
  .log.debug[`stream] ".stream.srcSubscriptionOff[]: subscription to the source server deactivated. Plugin component will have to initialize it.";
  .stream.p.srcSubscriptionOn:0b;
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`stream;`.sl.main;`];

/------------------------------------------------------------------------------/
\

.cr.getCfgPivot[`THIS;`group;(),`cfg.timeout1]
.cr.getCfgTab[`THIS;`group;`cfg.timeout1]
