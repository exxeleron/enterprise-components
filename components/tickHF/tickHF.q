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
/-/ 
/-/ Based on the code from Kx:
/-/ http://code.kx.com/wsvn/code/kx/kdb%2Btick/tick.q

/S/ Tick High Frequency component:
/-/ This version is extended by DEVnet to match DEVnet system structure and provides
/-/ - logging using DEVnet components
/-/ - in cases when time is not sent in the first column by data provider, current time can be added automatically in both modes: zero-latency and aggregation mode
/-/ - support for handling ticks that arrived after midnight but which are still 'belonging' to the previous day (called later as "late ticks")
/-/ Notes:
/-/ - in order to properly process late ticks, eodDelay in system.cfg has to be setup, for example to handle ticks 10 seconds after midnight:
/-/ (start code)
/-/ eodDelay = 00:00:10.000 -  (TIME format)
/-/ (end)
/-/ - this will delay end-of-day for 10 seconds; during this period ticks that belong to the previous day will be published normally and ticks for the next day will be cached in memory
/-/ - after this period end-of-day callback will be broadcast and cached ticks will be published to all subscribers
/-/ - in order to use this feature late and next day ticks are recognized *only by the time in first column* delivered by the data provider
/-/ eodDelay is a global variable and will affect all components that have build-in end-of-day procedure: tickLF (<tickLF.q>), rdb (<rdb.q>), stream (<stream.q>), eodMng (<eodMng.q>) and hdb queries that are using interface functions from <query.q>
/-/
/-/ Tick modes:
/-/ Tick can work in two modes
/-/ - zero-latency - this is the default mode, messages are published as soon as possible
/-/ - aggregation mode - messages are cached and published on timer; in order to run tickHF in aggregation mode in system.cfg please setup
/-/ (start code)
/-/ cfg.aggrInterval = 100 - (INT format)
/-/ (end)
/-/ 
/-/ Globals:
/-/ tickHF uses following global variables
/-/ .u.w - dictionary of tables->(handle;syms)
/-/ .u.i - message count
/-/ .u.t - table names
/-/ .u.L - tp log filename, e.g. `:./sym2008.09.11
/-/ .u.l - handle to tp log file
/-/ .u.d - date
/-/ 
/-/ API for pushing data through tickHF:
/-/ - .u.upd is defined during initialization and the only data format supported by <.u.upd> function is a list of lists
/-/ (start code)
/-/ .u.upd[table name:SYMBOL;data:LIST GENERAL]               - definition
/-/ .u.upd[`trade;(enlist .z.t; enlist `sym1;enlist 1.0)]     - usage example
/-/ (end)
/-/ - *note* - can't use -u because of the client end-of-day
/-/ - all described functions are defined in .u namespace (i.e .u.tick)


/2011.02.10 i->i,j to avoid duplicate data if subscription whilst data in buffer
/2008.09.09 .k -> .q, 2.4
/2008.02.03 tick/r.k allow no log
/2007.09.03 check one day flip
/2006.10.18 check type?
/2006.07.24 pub then log
/2006.02.09 fix(2005.11.28) .z.ts end-of-day
/2006.01.05 @[;`sym;`g#] in tick.k load
/2005.12.21 tick/r.k reset `g#sym
/2005.12.11 feed can send .u.endofday
/2005.11.28 zero-end-of-day
/2005.10.28 allow`time on incoming
/2005.10.10 zero latency
/------------------------------------------------------------------------------/

system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`tickHF];

/------------------------------------------------------------------------------/
.sl.lib[`$"qsl/u"];
.sl.lib[`$"qsl/timer"];
.sl.lib["cfgRdr/cfgRdr"];

/------------------------------------------------------------------------------/
/F/ Returns information about subscription protocols supported by the tickHF component.
/-/ This definition overwrites default implementation from qsl/sl library.
/-/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server - `PROTOCOL_TICKHF
/E/  .sl.getSubProtocols[]
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKHF};

/------------------------------------------------------------------------------/
\d .u
/F/ Opens (and creates if missing) the journal file for specified date and initializes <.u.i> with proper value.
/P/ x:DATE - date
/R/ :INT - journal file handle
/E/ .u.ld 2014.01.01
ld:{[x]
  if[not type key L::`$(-10_string L),string x;
    .[L;();:;()]
    ];
  j::i::-11!(-2;L);
  h:hopen L;
  .log.info[`tickHF] "Loading journal file:`",string[L],", handle:",string[h], ", entries:", string[i];
  :h;
  };

/F/ Opens (and creates if missing) the journal file for the next date and initializes <.u.nextday.i> with proper value.
/-/  Version of .u.ld[] used for handling late ticks.
/P/ x:DATE - date
/R/ :INT - journal file handle
/E/ .u.nextday.ld 2014.01.01
nextday.ld:{
  if[not type key nextday.L::`$(-10_string nextday.L),string x;
    .[nextday.L;();:;()]
    ];
  nextday.j::nextday.i::-11!(-2;nextday.L);
  h:hopen nextday.L;
  .log.info[`tickHF] "Loading journal file:`",string[nextday.L],", handle:",string[h], ", entries:", string[nextday.i];
  :h;
  };

/F/ Initializes TickHF component.
/P/ x:PAIR - (path to directory with journal;journal prefix)
/R/ no return value
/E/ .u.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)]
tick:{[x]
  .log.info[`tickHF] "Initializing tickHF process for active day ",string .sl.eodSyncedDate[];
  init[];
  .tickHF.p.checkModel[t];
  d::.sl.eodSyncedDate[];
  if[l::count x[1];L::`$":",x[1],"/",x[0],10#".";l::ld d];
  };


/F/ Initializes TickHF component. Version of .u.tick[] used for handling late ticks.
/F/ TickHF initialization function in case of ticks capture after EOD 
/P/ x:PAIR - (path to directory with journal;journal prefix)
/R/ no return value
/E/ .u.nextday.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)]
nextday.tick:{[x]
  .log.info[`tickHF] "Initializing tickHF process for the next day ",string nextday.d;
  // from this i late ticks are counted
  late.i:.u.i;
  .tickHF.p.checkModel[value nextday.names];
  if[nextday.l::count x[1];nextday.L::`$":",x[1],"/",x[0],10#".";nextday.l::nextday.ld nextday.d];
  };

/F/ Triggers end of day procedure, publishes end of day trigger to subscriber (using <.u.end[]>) and switch journal to new day (<.u.ld[]>)
/R/ no return value
/E/ .u.endofday[]
endofday:{[]
  end d;
  d+:1;
  if[l;
    hclose l;
    l::ld d;
    ];
  };

/F/ Triggers end of day procedure, publishes end of day trigger to subscriber (using <.u.end[]>) and switch journal to new day (<.u.ld[]>)
/-/  Version of .u.endofday[] used for handling late ticks.
/-/  Data for configured time will be cached in memory.
/R/ no return value
/E/ .u.endofday[]
activeday.endofday:{[]
  end d;
  d+:1;
  if[l;hclose l];
  // switch next to active now
  .log.info[`tickHF]"Switch journal settings to the active one";
  i::nextday.i;
  j::nextday.j;
  l::nextday.l;
  L::nextday.L;
  nextday.l:0i;nextday.i:0;nextday.j:0; delete L from `.u.nextday;
  {x insert value y}'[key .u.nextday.names;value .u.nextday.names];
  @[`.cache;;@[;`sym;`g#]0#] each key .u.nextday.names;
  // pub here for zero latency mode
  if[null .tickHF.cfg.aggrInterval;
    pub'[t;value each t];
    @[`.;t;@[;`sym;`g#]0#];
    i::j;  
    ];
  };

/F/ Triggers end of day procedure, publishes end of day trigger to subscriber (using <.u.end[]>) and switch journal to new day (<.u.ld[]>)
/-/  Version of .u.endofday[] used for handling late ticks.
/-/  Data for configured time will be cached in memory.
/P/ x:DATE - date
/R/ no return value
/E/ .u.nextday.endofday[]
nextday.endofday:{
  .u.nextday.d+:1;
  nextday.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)];
  };

/F/ Timer function, triggers .u.endofday[] if the day switch is discovered.
/P/ x:TIME - current timestamp  
/R/ no return value
/E/ .u.ts .z.t
ts:{
  if[d<"d"$x;
    if[d<-1+"d"$x;system"t 0";'"more than one day?"];
    endofday[]
    ];
  };

/F/ Timer function for handling late ticks.
/P/ x:TIME - current timestamp  
/R/ no return value
/E/ .u.eodMode.ts .z.t
eodMode.ts:{
  if[d<"d"$x;
    if[d<-1+"d"$x;system"t 0";'"more than one day?"];
    if[.u.nextday.d<"d"$x;
      nextday.endofday[];
      .log.info[`tickHF]"Change upd to updEodDetectionMode";
      `.u.upd set updEodDetectionMode;
      ];
    if[x>.sl.eodDelay; 
      .log.info[`tickHF]"Start eod procedure";
      .log.info[`tickHF]"TickHF has processed number of late entries: ",string[i-late.i];
      .log.info[`tickHF]"TickHF has collected number of entries for the next day: ",string[nextday.j];
      activeday.endofday[];
      .log.info[`tickHF]"Change upd to updActiveDay";
      `.u.upd set updActiveDay;
      ];
    ];
  };



p.aggrMode:{[]
  .log.info[`tickHF]"Initialized tickHF in aggregation mode. Internal timer will be set to ",string[.tickHF.cfg.aggrInterval]," ms";
  .tickHF.ts:{[x]
    pub'[t;value each t];
    @[`.;t;@[;`sym;`g#]0#];
    i::j;
    ts .sl.zz[]
    };
  .tmr.start[`.tickHF.ts;.tickHF.cfg.aggrInterval;`.tickHF.ts];
  
  updActiveDay::{[t;x]
    if[not -19=type first first x;
      if[d<"d"$a:.sl.zz[];
        .tickHF.ts[]
        ];
      a:"t"$a;
      x:$[0>type first x;
        a,x;
        (enlist(count first x)#a),x]
      ];
    t insert x;
    if[l;
      l enlist (`jUpd;t;x);
      j+:1]
    };

  updEodDetectionMode::{[t;x]
    if[not -19=type first first x;
      if[d<"d"$a:.sl.zz[];
        .tickHF.ts[]
        ];
      a:"t"$a;
      x:$[0>type first x;
        a,x;
        (enlist(count first x)#a),x]
      ];
    if[first[x 0]<12:00:00.000;  //tick from today  -> to cache, no publishing yet
      nextday.names[t] insert x;
      if[nextday.l;
        nextday.l enlist (`jUpd;t;x);
        nextday.j+:1];
      :();
      ];
    // yesterday ticks 
    updActiveDay[t;x];
    };

  `.u.upd set updActiveDay;
  };

p.zeroLatencyMode:{[]
  .log.info[`tickHF]"Initialized tickHF in zero-latency mode. Internal timer will be set to 1000 ms";
  .tickHF.ts:{[x] ts .sl.zz[]};
  .tmr.start[`.tickHF.ts;1000i;`.tickHF.ts];
  updActiveDay::{[t;x]
    ts a:.sl.zz[];
    if[not -19=type first first x;
      a:"t"$a;
      x:$[0>type first x;
        a,x;
        (enlist(count first x)#a),x]
      ];
    f:key flip value t;
    pub[t;$[0>type first x;enlist f!x;flip f!x]];
    if[l;
      l enlist (`jUpd;t;x);
      i+:1
      ];
    };
  
  updEodDetectionMode::{[t;x]
    if[not -19=type first first x;
      if[d<"d"$a:.sl.zz[];
        .tickHF.ts[]
        ];
      a:"t"$a;
      x:$[0>type first x;
        a,x;
        (enlist(count first x)#a),x]
      ];
    if[first[x 0]<12:00:00.000;  //tick from today  -> to cache, no publishing yet
      nextday.names[t] insert x;
      if[nextday.l;
        nextday.l enlist (`jUpd;t;x);
        nextday.j+:1];
      :();
      ];
    // yesterday ticks 
    updActiveDay[t;x];
    };
  `.u.upd set updActiveDay;
  };


\d .
.tickHF.p.checkModel:{[tabs]
  if[not count tabs;:()];
  if[not min(`time`sym~2#key flip value@)each tabs;'`timesym];
  @[;`sym;`g#]each tabs;
  };

/==============================================================================/
/F/ Component initialization entry point.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]
  (set) ./:                        model:.cr.getModel[`THIS];
  /G/ TickHF datapath, loaded from system.cfg.
  .tickHF.cfg.dataPath:            1_string .cr.getCfgField[`THIS;`group;`cfg.dataPath];
  /G/ Journal name prefix, loaded from cfg.jrnPrefix field from system.cfg.
  .tickHF.cfg.jrnPrefix:           .cr.getCfgField[`THIS;`group;`cfg.jrnPrefix];
  /G/ Aggregation interval, loaded from cfg.aggrInterval field from system.cfg.
  .tickHF.cfg.aggrInterval:       .cr.getCfgField[`THIS;`group;`cfg.aggrInterval];
  // if null - zero mode
  $[null .tickHF.cfg.aggrInterval;.u.p.zeroLatencyMode[];.u.p.aggrMode[]];
  .sl.libCmd[];
  
  .u.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)];
  // This is invoked when when tickHF is in mode for handling late ticks and EOD was not yet triggered 
  if[.sl.zt[]<.sl.eodDelay; // eod delay zone
    .u.nextday.d:1+.u.d; //next day
    .u.nextday.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)];
    ];
  if[.sl.eodDelay>00:00:00.000; // delay eod mode is on (initialized tables for data caching)
    .log.info[`tickHF] "Tick is working in eod mode that is handling late ticks. Data till ", string[.sl.eodDelay] , " will be cached in memory";
    .u.nextday.names:model[;0]!` sv/:`.cache,/:model[;0];
    (set) ./:                    ((value .u.nextday.names)(;)'model[;1]);
    .tickHF.p.checkModel value .u.nextday.names;
    .u.nextday.d:.u.d;
    `.u.ts set .u.eodMode.ts;
    ];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`tickHF;`.sl.main;`];

/------------------------------------------------------------------------------/
\


//-------------------------- documentation only ------------------------------//
/F/ Executes eod trigger on day switch and in case of aggr-mode triggers data publishing.
/P/ x:TIME - current time
/R/ no return value
/E/ .tickHF.ts .z.t
.tickHF.ts:{[x]};

/F/ Entry point for the data producers. Used for data publishing.
/-/ Actual function plugged in under .u.upd name depends on the current tickHF mode.
/P/ t:SYMBOL - table name
/P/ x:LIST   - list of columns with new data
/R/ no return value
/E/ .u.upd[`trade;tradeData]
.u.upd:{[t;x]};

/F/ Version of .u.upd dedicated for standard operation in case of active "handling late ticks" mode.
/P/ t:SYMBOL - table name
/P/ x:LIST   - list of columns with new data
/R/ no return value
/E/ .u.updActiveDay[`trade;tradeData]
.u.updActiveDay:{[t;x]};

/F/ Version of .u.upd dedicated for eod-detecion period in case of active "handling late ticks" mode.
/-/ this mode is active several seconds/minutes after midnight and is dedicated for detecion of the actual eod.
/P/ t:SYMBOL - table name
/P/ x:LIST   - list of columns with new data
/R/ no return value
/E/ .u.updEodDetectionMode[`trade;tradeData]
.u.updEodDetectionMode:{[t;x]};

/G/ Dictionary with all active subscriptions per table/handle.
/-/ Contains tables->(handle;syms) mapping. Managed via .u.add[] and .u.sub[].
.u.w:;

/G/ Number of messages published and published since last eod. Used for journal replay.
.u.i:;

/G/ Number of messages journalled and published since last eod. Used for journal replay.
.u.j:;

/G/ List of tables publishable via tickHF.
.u.t:;

/G/ Current journal file full path.
.u.L:;

/G/ Handle to the current journal file
.u.l:;

/G/ Current day.
.u.d:;
