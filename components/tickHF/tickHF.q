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
/L/ 
/L/ Based on the code from Kx:
/L/ http://code.kx.com/wsvn/code/kx/kdb%2Btick/tick.q

/S/ Tick High Frequency component:
/S/ This version is extended by DEVnet to match DEVnet system structure and provides
/S/ - logging using DEVnet components
/S/ - in cases when time is not sent in the first column by data provider, current time can be added automatically in both modes: zero-latency and aggregation mode
/S/ - support for handling ticks that arrived after midnight but which are still 'belonging' to the previous day (called later as "late ticks")
/S/ Notes:
/S/ - in order to properly process late ticks, eodDelay in system.cfg has to be setup, for example to handle ticks 10 seconds after midnight:
/S/ (start code)
/S/ eodDelay = 00:00:10.000 -  (TIME format)
/S/ (end)
/S/ - this will delay end-of-day for 10 seconds; during this period ticks that belong to the previous day will be published normally and ticks for the next day will be cached in memory
/S/ - after this period end-of-day callback will be broadcast and cached ticks will be published to all subscribers
/S/ - in order to use this feature late and next day ticks are recognized *only by the time in first column* delivered by the data provider
/S/ eodDelay is a global variable and will affect all components that have build-in end-of-day procedure: tickLF (<tickLF.q>), rdb (<rdb.q>), stream (<stream.q>), eodMng (<eodMng.q>) and hdb queries that are using interface functions from <query.q>

/S/ Tick modes:
/S/ Tick can work in two modes
/S/ - zero-latency - this is the default mode, messages are published as soon as possible
/S/ - aggregation mode - messages are cached and published on timer; in order to run tickHF in aggregation mode in system.cfg please setup
/S/ (start code)
/S/ cfg.aggrInterval = 100 - (INT format)
/S/ (end)
/S/ 
/S/ Globals:
/S/ tickHF uses following global variables
/S/ .u.w - dictionary of tables->(handle;syms)
/S/ .u.i - message count
/S/ .u.t - table names
/S/ .u.L - tp log filename, e.g. `:./sym2008.09.11
/S/ .u.l - handle to tp log file
/S/ .u.d - date
/S/ 
/S/ API for pushing data through tickHF:
/S/ - .u.upd is defined during initialization and the only data format supported by <.u.upd> function is a list of lists
/S/ (start code)
/S/ .u.upd[table name:SYMBOL;data:LIST GENERAL]               - definition
/S/ .u.upd[`trade;(enlist .z.t; enlist `sym1;enlist 1.0)]     - usage example
/S/ (end)
/S/ - *note* - can't use -u because of the client end-of-day
/S/ - all described functions are defined in .u namespace (i.e .u.tick)


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
/F/ Information about subscription protocols supported by the tickHF component.
/F/ This definition overwrites default implementation from qsl/sl library.
/F/ This function is used by qsl/sub library to choose proper subscription protocol.
/R/ SYMBOL: returns list of protocol names that are supported by the server - `PROTOCOL_TICKHF
.sl.getSubProtocols:{[] enlist `PROTOCOL_TICKHF};

/------------------------------------------------------------------------------/
\d .u
/F/ Function opens/creates the journal file for specified date and initializes <.u.i> with proper value
/P/ x - date
/R/ journal handle
ld:{
  if[not type key L::`$(-10_string L),string x;
    .[L;();:;()]
    ];
  j::i::-11!(-2;L);
  h:hopen L;
  .log.info[`tickHF] "Loading journal file:`",string[L],", handle:",string[h], ", entries:", string[i];
  :h;
  };

/F/ Function opens/creates the journal file for the next date and initializes <.u.nextday.i> with proper value; used for handling late ticks
/P/ x - date
/R/ journal handle
nextday.ld:{
  if[not type key nextday.L::`$(-10_string nextday.L),string x;
    .[nextday.L;();:;()]
    ];
  nextday.j::nextday.i::-11!(-2;nextday.L);
  h:hopen nextday.L;
  .log.info[`tickHF] "Loading journal file:`",string[nextday.L],", handle:",string[h], ", entries:", string[nextday.i];
  :h;
  };

/F/ TickHF initialization function
/P/ x - path to directory with journal
/P/ y - journal prefix
tick:{
  .log.info[`tickHF] "Initializing tickHF process for active day ",string .sl.eodSyncedDate[];
  init[];
  .tickHF.p.checkModel[t];
  d::.sl.eodSyncedDate[];
  if[l::count x[1];L::`$":",x[1],"/",x[0],10#".";l::ld d];
  };


/F/ TickHF initialization function in case of ticks capture after EOD 
/P/ x - path to directory with journal
/P/ y - journal prefix
nextday.tick:{
  .log.info[`tickHF] "Initializing tickHF process for the next day ",string nextday.d;
  // from this i late ticks are counted
  late.i:.u.i;
  .tickHF.p.checkModel[value nextday.names];
  if[nextday.l::count x[1];nextday.L::`$":",x[1],"/",x[0],10#".";nextday.l::nextday.ld nextday.d];
  };

/F/ end of day, publishing end of day trigger to subscriber (using <.u.end[]>) and journal switch (<.u.ld[]>)
/P/ x - date
endofday:{
  end d;
  d+:1;
  if[l;
    hclose l;
    l::ld d;
    ];
  };

/F/ end of day in mode for handling late ticks, publishing end of day trigger to subscriber (using <.u.end[]>) and journal switch (<.u.ld[]>);
/F/ data for configured time will be cached in memory
/P/ x - date
activeday.endofday:{
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

/F/ end of day in mode for handling late ticks, initialize journal for the next day
/P/ x - date
nextday.endofday:{
  .u.nextday.d+:1;
  nextday.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)];
  };

/F/ timer function
/P/ x - current timestamp  
ts:{
  if[d<"d"$x;
    if[d<-1+"d"$x;system"t 0";'"more than one day?"];
    endofday[]
    ];
  };

/F/ timer function for handling late ticks
/P/ x - current timestamp  
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
  .tickHF.ts::{
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
  .tickHF.ts::{ts .sl.zz[]};
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
.sl.main:{[flags]
  (set) ./:                        model:.cr.getModel[`THIS];
  .tickHF.cfg.dataPath:            1_string .cr.getCfgField[`THIS;`group;`cfg.dataPath];
  .tickHF.cfg.jrnPrefix:           .cr.getCfgField[`THIS;`group;`cfg.jrnPrefix];
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


