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

/A/ DEVnet: Slawomir Kolodynski
/V/ 3.0

/S/ Timer library:
/S/ .tmr.status contains table of active timers
/S/ -- tick:INT - the number of timer ticks since the last run
/S/ -- period:INT - the period between runs in timer ticks
/S/ -- periodms:INT - the period between runs in milliseconds
/S/ -- fun:SYMBOL - the function to be run
/S/ -- funid:SYMBOL - the timer identifier


/F/ runs a function every number of timer ticks provided per parameter
/P/ func:SYMBOL - name of a function that takes exactly one parameter; the timestamp from .z.p or .z.P 
/P/ (depending on the EC_TIMESTAMP_MODE configuration variable) is passed to that function
/P/ per:INT - the period between runs in ms
/P/ id:SYMBOL - timer id, assigned by the user; if such already exists, the previous is overwritten
/R/ :INT - number of timers defined (including this one)
.tmr.start:{[func;per;id]
  //(-1) (string .z.p)," *** tmrdebug ","starting timer for function ",(string func)," period ",(string per)," id ",string id;
  .log.info[`tmr] "starting timer for function ",(string func)," period ",(string per)," id ",string id;
  //.dbg.status:.tmr.status;
  if[0~count .tmr.status; // adding first timer
    if[per<1; .log.warn[`tmr] "Timer period must be positive, .tmr.start call ignored.";:0];
    // backup existing timer setup
    .tmr.p.t:system "t";
    .pe.at[{[].tmr.p.zts:.z.ts};();{[].tmr.p.zts:{}}]; // .z.ts may not exist
    `.tmr.status insert (0;1;per;func;id);
    if[not .tmr.p.zts~{};.log.warn[`tmr] "timer library will replace current timer setup, use .tmr.reset to recover"];
    .z.ts:.tmr.run;
    if[(per<100) and per>3;
      .log.warn[`tmr] "Setting timer period to ",(string per)," may affect system performance"
      ];
    if[(per<4) and (string .z.o) like "l*";
      .log.warn[`tmr] "Timer period ",(string per)," is smaller than the standard Linux timer period, check your CONFIG_HZ if this has a chance to work"
      ];
    system "t ",string per;
    .tmr.p.tt:2000000j*system "t"; // period in nanoseconds
    //(-1) "*** tmrdebug ","added first callback, system timer ",(string system "t")," ms ";
    .log.info[`tmr] "added first callback, system timer ",(string system "t")," ms ";
    :1;
    ];
  // some timers are defined
  .tmr.sanityCheck[];
  if[per<1; .log.warn[`tmr] "Timer period must be positive, .tmr.start call ignored.";:count .tmr.status];
  //if[id in .tmr.status`funid;'`$"Replicated id in timer table"];
  // overwrite if this funid exists
  if[id in .tmr.status`funid;delete from `.tmr.status where funid=id];
  factor:`int$(system "t")%newt:.tmr.p.gcd per,.tmr.status`periodms;
  if[1<factor; // we need to increase frequency
  update period:period*factor from `.tmr.status; 
  update tick:(tick*factor) + `int$(.sl.zp[]-.tmr.p.lastTick)%(newt*1000000) from `.tmr.status; 
  .tmr.p.lastTick:.sl.zp[]; // to prevent detecting missing ticks
  if[newt<100;
    .log.warn[`tmr] "Setting timer period to ",(string newt)," may affect system performance"
    ];
  if[(newt<4) and (string .z.o) like "l*";
    .log.warn[`tmr] "Timer period ",(string newt)," is smaller than the standard Linux timer period, check your CONFIG_HZ if this has a chance to work"
    ];
  system "t ",string newt;
  .log.info[`tmr] "timer frequency increased by a factor of ",(string factor);
  ];
  `.tmr.status insert (per-1;`int$per%system "t";per;func;id);
  system "t ",string system "t"; // we want always to trigger a tick when new callback
  .tmr.p.tt:2000000j*system "t"; //doubled new period in nanoseconds
  //(-1) (string .z.p)," *** tmrdebug ","added callback, system timer ",(string system "t")," ms ";
  .log.info[`tmr] "added callback, system timer ",(string system "t")," ms ";
  :count .tmr.status;
  };


/F/ removes a function (timer callback) from the list to be run; other callbacks are not affected.
/P/ id:SYMBOL - id of the timer to be removed
/R/ :INT - number of remaining timers
.tmr.stop:{[id]
  //(-1) (string .z.p)," *** tmrdebug ","stopping timer id:",(string id)," callbacks:",("," sv string each .tmr.status`fun)," tick: ",("," sv string each .tmr.status`tick);
  .log.debug[`tmr] "callbacks before stopping: ",("," sv string each .tmr.status`fun)," tick: ",("," sv string each .tmr.status`tick);
  if[0~c:count .tmr.status;  // no timer to stop
    .log.info[`tmr] "attempt to stop timer that has not been started";:0
    ];
  .tmr.sanityCheck[];
  delete from `.tmr.status where funid=id;
  if[0~c:count .tmr.status;
    .log.info[`tmr] "timer id: ",(string id)," stopped, this was the last timer";
    .tmr.reset[];
    :0];
  .tmr.p.cleanup:.tmr.p.recalcGcd;
  //(-1) (string .z.p)," *** tmrdebug ","timer stopped, callbacks:",("," sv string each .tmr.status`fun)," tick: ",("," sv string each .tmr.status`tick);
  .log.info[`tmr] "timer id: ",(string id)," stopped";
  .log.debug[`tmr] "callbacks:",("," sv string each .tmr.status`fun)," tick: ",("," sv string each .tmr.status`tick);
  :c
  };

/F/ changes the frequency of given timer
/P/ per:INT - new timer period in ms
/P/ id:SYMBOL - timer identifier
/R/ Int - previous period in ms
.tmr.change:{[per;id]
  .log.info[`tmr] "changing timer id",(string id)," to period ",string per;
  if[not id in .tmr.status`funid;
    .log.info[`tmr] "attempt to change timer that has not been started";
    :0;
    ];
  func:(exec fun from .tmr.status where funid=id)[0];
  oldper:(exec period from .tmr.status where funid=id)[0];
  .tmr.stop[id];
  .tmr.start[func;per;id];
  :oldper;
  };

/F/ removes all timer callbacks
.tmr.reset:{[]
  .log.info[`tmr] "recovering original configuration: timer period ",string .tmr.p.t;
  .z.ts:.tmr.p.zts;
  system "t ", string .tmr.p.t;
  .tmr.p.cleanup:{};
  delete from `.tmr.status;
  };

/F/ runs the specified function around specified time (10 s accuracy)
/P/ t:TIME - the time the function is to run the first time 
/P/ fun:SYMBOL - the name of the function
/P/ id:SYMBOL - the id of this job
.tmr.runAt:{[t;func;id]
  //(-1) "scheduling ",(string func)," to run at ",string t;
  .log.info[`tmr] "scheduling ",(string func)," to run at ",string t;
  .tmr.p.lastRun[id]:$[t<.sl.zt[];.sl.zd[];2000.01.01];
  // create a wrapper to run
  f:(`$".tmr.p.runAtFun",(string id)) set .tmr.p.runAt[t;func;id];
  .tmr.start[f;10000i;id];
  };

/F/ checks for known invariants in case someone resets the q timer or .z.ts by hand; errors are logged, but no other action is taken (no signals)
/R/ message about the state of timer
.tmr.sanityCheck:{[]
  if[not .z.ts~.tmr.run;
    .log.error[`tmr] msg:".z.ts different than expected, modified outside the library?";
    :msg;
    ];
  if[.tmr.p.zts~.tmr.run;
    .log.warn[`tmr] "backed up timer callback same as library timer callback";
    ];
  if[0~count .tmr.status;:"no callbacks defined, timer not in use"];
  if[not .tmr.p.tt~2000000j*system "t";
    .log.error[`tmr] msg:"system timer ",(string system "t")," different than expected ",string `int$.tmr.p.tt%2000000;
    :msg;
    ];
  :"";
  };

//------------------- private --------------------------------------------------
/F/ runs a timer function on the timer tick; if some tick have been missed because the 
/F/ process was busy, each missed function is executed once
.tmr.run:{[]
  //.log.info[`tmr] ".tmr.run";
  //.dbg.status:.tmr.status;
  if[(td:.sl.zp[]-.tmr.p.lastTick)>.tmr.p.tt; // missed timer beat
    .log.debug[`tmr] "missed ticks lastTick:",(string .tmr.p.lastTick)," 2*tick period: ",(string .tmr.p.tt)," system t: ",(string system "t");
    .tmr.p.lastTick:.sl.zp[]-td mod stn:(system "t")*1000000; // last expected tick
    missed:floor td%stn;
    .log.debug[`tmr]  "callbacks:",("," sv string each .tmr.status`fun)," tick: ",("," sv string each .tmr.status`tick)," missed ",(string missed);
    // get functions that should have been run
    torun:exec fun from .tmr.status where (periodms*1000000)<td+tick*stn;
    // correct the tick counters
    update tick:(tick+missed) mod period from `.tmr.status;
    .log.debug[`tmr] "functions to run: ",("," sv string each torun)," updated ticks: ","," sv string each .tmr.status`tick;
    // run all the functions that should have been run
    torun .pe.atLog[`tmr;;;0b;`error]\: .sl.zp[];
    :()
    ];
  .tmr.p.lastTick:.sl.zp[];
  update tick:(tick+1) mod period from `.tmr.status;
  (exec fun from .tmr.status where 0=tick) .pe.atLog[`tmr;;;0b;`error]' .sl.zp[];
  .tmr.p.cleanup[];
  };
/F/ Calculates a greatest common divisor by doing simple optimizations and then
/F/ calling the brute force method
/P/ x:LIST[INT] - a nonempty list of positive integers.    
.tmr.p.gcd:{[x]
  if[0~ count x;.log.error[`tmr] "attempt to calculate a gcd of empty list";'`$"Invalid argument"];
  if[1~count x;:x[0]];
  if[all 0=x mod\: 1000i;:1000i*.tmr.p.gcdBrute `int$x%1000i];
  if[all 0=x mod\: 100i;:100i*.tmr.p.gcdBrute `int$x%100i];
  :.tmr.p.gcdBrute x
  };

/F/ Calculates greatest common divisor by a brute force method
/P/ x:LIST[INT] - a nonempty list of positive integers. The nonemptiness is not checked
/R/ :INT - the greatest common divisor of x
.tmr.p.gcdBrute:{[x] d last where (d:(1+ til min x)) {[x;y] all 0=y mod/: x}\: x};

/F/ calculates greatest common divisor of a list of positive integers using
/F/ Euclidean algorithm and associativity of gcd. Faster than .tmr.p.gcd, but
/F/ not used as it may give 'stack
/P/ x:LIST[INT] - a nonempty list of positive integers. The nonemptiness is not checked
.tmr.p.gcdEuc:{[x]
  if[1<count x;
    if[x[0]~x[1];:.tmr.p.gcd x[1],2_x];
    :.tmr.p.gcdEuc ((max 2#x)-min 2#x),(min 2#x),2_x
    ];
  :x[0];
  };


/F/ Calculates gcd of all periods in the status tables and sets the timer.
/F/ This should only be done when all functions are at tick 0, hence the check
.tmr.p.recalcGcd:{
  if[(0<count .tmr.status) and  all 0=.tmr.status`tick;
    .log.debug[`tmr] "cleanup, callbacks:",("," sv string each .tmr.status`fun)," tick: ",("," sv string each .tmr.status`tick), " period: ", ("," sv string each .tmr.status`period);
    factor:(newt:.tmr.p.gcd .tmr.status`periodms)%system "t";
    update tick:`int$tick%factor,period:`int$period%factor from `.tmr.status;
    system "t ",string newt;
    .tmr.p.tt:2000000j*system "t";
    .log.info[`tmr] "system timer period reset to ",string system "t";
    .tmr.p.cleanup:{};
    ];
  };

/F/ a wrapper for function that needs to run at some time every day
/P/ t:TIME - time at which the function is supposed to run
/P/ func:SYMBOL - name of the function to run
/P/ id:SYMBOL - id of the timer
/P/ zp:TIMESTAMP - timestamp passed to the function
.tmr.p.runAt:{[t;func;id;zp]
  if[(.sl.zd[]>.tmr.p.lastRun[id]) and (`time$zp)>t;
    //(-1) (string .z.p)," running scheduled function ",(string func);
    .log.debug[`tmr] "running scheduled function ",(string func);
    .tmr.p.lastRun[id]:.sl.zd[]; // here so that if func signals,it is not tried again in 10 s
    func[zp];
    ];
  };

// last time tick way in the future to avoid triggering missed ticks processing
.tmr.p.lastTick:`timestamp$2020.01.01T00:00:00.0

/F/ function that simplifies the status table recalculating GCD of periods, 
/F/ initially noop, set to .tmr.p.recalcGcd when removing a timer callback
.tmr.p.cleanup:{};

// global for counting remaining runs of a function
//if[not `runs in key `.tmr.p;.tmr.p.runs:()!()];

/G/ global for functions run at specified time, indicates the date of last run
if[not `lastRun in key `.tmr.p;.tmr.p.lastRun:()!()];

// set up
if[not `status in key .tmr;.tmr.status:([] tick:`int$();period:`int$();periodms:`int$();fun:`$();funid:`$())];

