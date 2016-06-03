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
/D/ 2012.02.01

/S/ Event library:
/-/ This library provides API that allows execution of q functions as events.
/-/ The library is loaded automatically in qsl/sl.q (<sl.q>) library

/-/ Benefits of using events:
/-/ Executing function as event results in following benefits
/-/  - function is executed using protected evaluation
/-/  - detailed information about event state is logged using .log.xxx interface - levels can be defined via event API; information is logged using dictionary format (key=value pairs)
/-/  - information about event state is transferred to the monitor server using event files
/-/  - detailed information about event is persisted in event files (the same information as event log message)
/-/  - function execution time is measured

/-/ When to use events:
/-/ - events should be used to execute important system actions (.e.g. process initialization, journal replay, eod process, etc.)
/-/ *Notes:*
/-/ - due to non-zero cost of executing a function as event, events should *not be used* if highest possible performance is required; (e.g. for actions executed on timer or on upd callback)
/-/ - events should be used only if function arguments are of a reasonable size as the arguments will be dumped to an event file

/-/ Event states:
/-/ Execution of selected function is enclosed into set of predefined states
/-/ EVENT_STARTED - event was started
/-/ EVENT_PROGRESS - event is still being executed, <.event.progress> function was used to indicate how much of event work was already done and estimation of time required to finish the execution
/-/ EVENT_COMPLETED - event was completed successfully, i.e. no signal was generated in the executed function
/-/ EVENT_FAILED - event failed - executed function produced a signal

/-/ Event files:
/-/ Information about executed events is persisted in event files. There are four different types of event files
/-/ 1. - Written *before* event execution (EVENT_STARTED) with file name format :
/-/ (start code)
/-/ [componentId].yyyy.mm.ddDhh.mm.ss.xxxxxxxxx.[module]_e1_begin.event
/-/ (end)
/-/ 2. - Written *during* event execution using function <.event.progress[]> (EVENT_PROGRESS) with file name format :
/-/ (start code)
/-/ [componentId].yyyy.mm.ddDhh.mm.ss.xxxxxxxxx.[module]_e2_progress.event
/-/ (end)
/-/ 3. - Written *after successful execution* of the event (EVENT_COMPLETED) with file name format :
/-/ (start code)
/-/ [componentId].yyyy.mm.ddDhh.mm.ss.xxxxxxxxx.[module]_e3_end.event
/-/ (end)
/-/ 4. - Written *after failure* of event (EVENT_FAILED) with file name format :
/-/ (start code)
/-/ [componentId].yyyy.mm.ddDhh.mm.ss.xxxxxxxxx.[module]_e3_signal.event
/-/ (end)

/-/ Event files are written in kdb+ format, therefore these should be examined using q. Each event file contains q dictionary with following fields
/-/ *EVENT_STARTED (e1_begin.event file)*
/-/ -- status:SYMBOL - status of the event = EVENT_STARTED
/-/ -- descr:STRING - description of the event
/-/ -- funcName:SYMBOL - function name which will be executed
/-/ -- arg:ANY - arguments that will be passed to the function (funcName)
/-/ -- defVal:ANY - default value returned in case of event failure
/-/ -- tsId:TIMESTAMP - timestamp identificator of the event, together with componentId it should be used to match event begin with event progress and end files
/-/ -- module:SYMBOL - module name
/-/ -- level:SYMBOL - level of the message (based on levels parameter from the interface function)
/-/ -- ts:TIMESTAMP - timestamp of the file creation
/-/ -- componentId:SYMBOL - componentId of process that generated event

/-/ *EVENT_PROGRESS (e2_progress.event file)*
/-/ -- status:SYMBOL - status of the event = EVENT_STARTED
/-/ -- descr:STRING - description of the event
/-/ -- funcName:SYMBOL - function name which will be executed
/-/ -- progress:INT - progress of event completion in %
/-/ -- timeLeft:TIME - estimated time for event completion in milliseconds
/-/ -- tsId:TIMESTAMP - timestamp identificator of the event, together with componentId it should be used to match event begin with event progress and end files
/-/ -- module:SYMBOL - module name
/-/ -- level:SYMBOL - level of the message (based on levels parameter from the interface function)
/-/ -- ts:TIMESTAMP - timestamp of the file creation
/-/ -- componentId:SYMBOL - componentId of process that generated event

/-/ *EVENT_COMPLETED (e3_end.event file)*
/-/ -- status:SYMBOL - status of the event = EVENT_COMPLETED
/-/ -- descr:STRING - description of the event
/-/ -- funcName:SYMBOL - function name which will be executed
/-/ -- resType:SHORT - type of variable returned by event function
/-/ -- resCnt:INT - count of elements in variable returned by event function
/-/ -- tsId:TIMESTAMP - timestamp identificator of the event, together with componentId it should be used to match event begin with event progress and end files
/-/ -- module:SYMBOL - module name
/-/ -- level:SYMBOL - level of the message (based on levels parameter from the interface function)
/-/ -- ts:TIMESTAMP - timestamp of the file creation
/-/ -- componentId:SYMBOL - componentId of process that generated event

/-/ *EVENT_FAILED (e3_signal.event file)*
/-/ -- status:SYMBOL - status of the event = EVENT_FAILED
/-/ -- descr:STRING - description of the event
/-/ -- funcName:SYMBOL - function name which will be executed
/-/ -- signal:STRING - signal thrown by executed event function
/-/ -- tsId:TIMESTAMP - timestamp identificator of the event, together with componentId it should be used to match event begin with event progress and end files
/-/ -- module:SYMBOL - module name
/-/ -- level:SYMBOL - level of the message (based on levels parameter from the interface function)
/-/ -- ts:TIMESTAMP - timestamp of the file creation
/-/ -- logDiff:DICT - number of warning, error and fatal log messages generated during event function execution
/-/ -- componentId:SYMBOL - componentId of process that generated event

/-/ Error handling responsibility:
/-/ Event library catches signals generated within executed user functions and event ends in the EVENT_FAILED state.
/-/ Following errors are propagated as signal (and *do not* have final state EVENT_FAILED) :
/-/ - non-existing function
/-/ - function body instead of function name
/-/ - invalid number of arguments to function (too few or too many)
/-/ - wrong function parameter type (e.g. single value in case of .pe.dot)
/-/ Those cases should be handled by the programmer.

//---------------------------------------------------------------------------//
.event.p.init:{[]
  if[`initialized in key .event.p; 
    .log.debug[`event] "already initialized";
    :()
    ];
  .event.p.initialized:1b;

  .event.p.monitorEventDumpPath:"";

  eventPath:ssr[getenv[`EC_EVENT_PATH];"\\";"/"];
  if[not eventPath~"";
    .log.debug "Logging with data transfer to the monitor server";
    .event.dot:.event.p.execWithMonitDump[`dot];
    .event.at:.event.p.execWithMonitDump[`at];
    .event.progress:.event.p.progressWithMonitDump;
    .event.p.monitorEventDumpPath:eventPath,"/monitor_transfer/events/";
    ];

  /G/ Flag used for detection of signals within events.
  .event.p.sig:0b;
  .event.p.active:(enlist (`))!(enlist()!());
  };

//---------------------------------------------------------------------------//
.event.p.fileBase:{[tsId;logModule]
  ts:string[tsId];ts[13 16]:".";
  fileBase:string[.sl.componentId],".",ts,".",string[logModule],"_";
  fileBase
  };

//---------------------------------------------------------------------------//
.event.p.progress:{[logModule;funcName;progress;timeLeft;descr]
  tsId:.event.p.active[funcName;logModule];
  if[0=count tsId; .log.warn[logModule] "event progress: no matching event for func ", string[funcName], " module ", string[logModule]];
  .log.info[logModule] evMsg:`status`descr`funcName`progress`timeLeft`tsId!(`EVENT_PROGRESS;descr;funcName;progress;timeLeft;tsId);
  };

//---------------------------------------------------------------------------//
.event.p.progressWithMonitDump:{[logModule;funcName;progress;timeLeft;descr]
  tsId:.event.p.active[funcName;logModule];
  if[0=count tsId; .log.warn[logModule] "event progress: no matching event for func ", string[funcName], " module ", string[logModule]];
  .log.info[logModule] evMsg:`status`descr`funcName`progress`timeLeft`tsId!(`EVENT_PROGRESS;descr;funcName;progress;timeLeft;tsId);

  //generate event file
  fileBase:.event.p.fileBase[tsId:.sl.zp[];logModule];
  (hsym`$.event.p.monitorEventDumpPath,fileBase,"e2_progress.event")set evMsg, `module`level`ts`componentId!(logModule;`info;.sl.zp[];.sl.componentId);
  };

//---------------------------------------------------------------------------//
//funcName:`monadic
//`logModule`funcName`arg`defVal`levels`descr set'(`module;{x+y};1 2;`def;`debug`info`warn;"minor task")
//`logModule`funcName`arg`defVal`levels`descr set' (`module;{x+y};1 2;`def;`debug`info`warn;"minor task")
//`mode`logModule`funcName`arg`defVal`levels`descr set' (`dot;`module;`dyadic;1;`def;`debug`info`warn;"minor task")
//`mode`logModule`funcName`arg`defVal`levels`descr set' (`dot;`module;`$"dyadic[1]";2;`def;`debug`info`warn;"minor task")
//`mode`logModule`funcName`arg`defVal`levels`descr set' (`dot;`module;`dyadic;(`1;2.0;3j);`def;`debug`info`warn;"minor task")
.event.p.exec:{[mode;logModule; funcName; arg; defVal; levels; descr]
  .log[levels 0][logModule] evMsg:`status`descr`funcName`arg`defVal`tsId!(`EVENT_STARTED;descr;funcName;arg;defVal;tsId:.sl.zp[]);
  .event.p.active[funcName;logModule]:tsId;
  res:.pe[mode][value funcName;arg;{.event.p.sig:1b;.event.lastsig:x}];
  if[104h=type res;if[(arg~1_value res)and(value[funcName]~first value res);.event.lastsig:"too little arguments";.event.p.sig:1b]];
  if[.event.p.sig;
    .event.p.sig:0b;
    .log[levels 2][logModule] evMsg:`status`descr`funcName`signal`tsId!(`EVENT_FAILED;descr;funcName;.event.lastsig;tsId);
    :defVal;
    ];
  .log[levels 1][logModule] `status`descr`funcName`resType`resCnt`tsId!(`EVENT_COMPLETED;descr;funcName;type res; count res;tsId);
  .event.p.active[funcName;logModule]:0Np;
  :res;
  };


/F/ Base for .event.at and .event.dot functions.
.event.p.execWithMonitDump:{[mode;logModule; funcName; arg; defVal; levels; descr]
  .log[levels 0][logModule] evMsg:`status`descr`funcName`arg`defVal`tsId!(`EVENT_STARTED;descr;funcName;arg;defVal;tsId:.sl.zp[]);
  fileBase:.event.p.fileBase[tsId:.sl.zp[];logModule];
  (hsym`$.event.p.monitorEventDumpPath,fileBase,"e1_begin.event")set evMsg, `module`level`ts`componentId!(logModule;levels 0;.sl.zp[];.sl.componentId);
  .event.p.active[funcName;logModule]:tsId;
  logStatus:.log.status;
    res:.pe[mode][value funcName;arg;{.event.p.sig:1b;.event.lastsig:x}];
    if[104h=type res;if[(arg~1_value res)and(value[funcName]~first value res);.event.lastsig:"too little arguments";.event.p.sig:1b]];
  if[.event.p.sig;
    .event.p.sig:0b;
    logDiff:.log.status-logStatus;
    .log[levels 2][logModule] evMsg:`status`descr`funcName`signal`tsId!(`EVENT_FAILED;descr;funcName;.event.lastsig;tsId);
    (monitorfile:hsym`$.event.p.monitorEventDumpPath,fileBase,"e3_signal.event")set evMsg, `module`level`ts`logDiff`componentId!(logModule;levels 2;.sl.zp[];logDiff;.sl.componentId);
    :defVal;
    ];
  .log[levels 1][logModule] evMsg:`status`descr`funcName`resType`resCnt`tsId!(`EVENT_COMPLETED;descr;funcName;type res; count res;tsId);
  (hsym`$.event.p.monitorEventDumpPath,fileBase,"e3_end.event")set evMsg, `module`level`ts`componentId!(logModule;levels 1;.sl.zp[];.sl.componentId);
  :res;
  };

//----------------------------------------------------------------------------//
/F/ Executes function with two or more arguments as EVENT - in protected evaluation and with extended logging.
/-/ The following actions are taken:
/-/  - function is executed using protected evaluation
/-/  - event is logged using .log logging interface, log levels are set according to "levels" argument
/-/  - event information is persisted in event files; those are used by the monitor server
/-/  - number of logged errors and warnings that happens during function execution is counted and stored in event file
/-/  - function execution time is measured
/P/ logModule:SYMBOL    - name of the module, used for logging
/P/ funcName:SYMBOL     - function name (e.g. `foo1)
/P/ arg:LIST            - list of arguments
/P/ defVal:ANY          - default value to be returned in case of the error
/P/ levels:LIST SYMBOL  - log levels for start/complete/failed event
/P/ descr:STRING        - event description  
/R/ value returned by executed function or a default value in case of func failure.
/E/ .event.dot[`rdb; `.q.ssr; ("text";"x";"s"); "--"; `info`info`error; "search and replace"]
/-/     - prints following `info log before ssr[] execution:
/-/       INFO  2015.11.17 22:03:36.991 rdb   - | status=`EVENT_STARTED| descr="search and replace"| funcName=`.q.ssr| arg=("text";"x";"s")| defVal="--"| tsId=2015.11.17D22:03:36.990961000
/-/     - executes ssr["text";"x";"s"] (replace all "x" with "s" in the "text" string)
/-/     - prints following `info log after ssr[] execution:
/-/       INFO  2015.11.17 22:03:36.996 rdb   - | status=`EVENT_COMPLETED| descr="search and replace"| funcName=`.q.ssr| resType=10h| resCnt=4| tsId=2015.11.17D22:03:36.991358000
/-/     - call returns "test"
/E/ .event.dot[`rdb; `.q.ssr; ("text";121;"s"); "--"; `info`info`error; "search and replace"]
/-/     - prints following `info log before ssr[] execution:
/-/     INFO  2015.11.17 22:06:08.564 rdb   - | status=`EVENT_STARTED| descr="search and replace"| funcName=`.q.ssr| arg=("text";121;"s")| defVal="--"| tsId=2015.11.17D22:06:08.564140000
/-/     - executes ssr["text";121;"s"] (tries replace all 121 with "s" in the "text" string)
/-/     - prints following `error log after ssr[] execution:
/-/     ERROR 2015.11.17 22:06:08.569 rdb   - | status=`EVENT_FAILED| descr="search and replace"| funcName=`.q.ssr| signal="type"| tsId=2015.11.17D22:06:08.564579000
/-/     - call returns "--"
.event.dot:.event.p.exec[`dot];

//----------------------------------------------------------------------------//
/F/ Executes function with zero or one argument as EVENT - in protected evaluation and with extended logging.
/-/ The following actions are taken:
/-/  - function is executed using protected evaluation
/-/  - event is logged using .log logging interface, log levels is set according to the "levels" argument
/-/  - event information is persisted in event files; those are used by monitor server
/-/  - number of logged errors and warnings that happens during function execution is counted and stored in event file
/-/  - function execution time is measured
/P/ logModule:SYMBOL   - name of the module, used for logging
/P/ funcName:SYMBOL    - function name (e.g. `foo1)
/P/ arg:LIST           - list of the arguments
/P/ defVal:ANY         - default value to be returned in case of the error
/P/ levels:LIST SYMBOL - three log levels for start/complete/failed event (e.g. levels=`info`info`error will cause logging start and completed events as info messages and failure event as error message)
/P/ descr:STRING       - event description  
/R/ value returned by executed function or a default value in case of func failure
/E/ .event.at[`rdb; `.q.neg; 121; 0N; `debug`info`error; "make negation"]
/-/     - prints following `debug log before neg[] execution:
/-/       DEBUG 2015.11.17 19:53:30.324 rdb   - | status=`EVENT_STARTED| descr="make negation"| funcName=`.q.neg| arg=121| defVal=0N| tsId=2015.11.17D19:53:30.323362000
/-/     - executes neg[121]
/-/     - prints following `info log after neg[] execution:
/-/       INFO  2015.11.17 19:53:30.330 rdb   - | status=`EVENT_COMPLETED| descr="make negation"| funcName=`.q.neg| resType=-7h| resCnt=1| tsId=2015.11.17D19:53:30.324485000
/-/     - call returns -121
/E/ .event.at[`rdb; `.q.neg; `abc; 0N; `debug`info`error; "make negation"]
/-/     - prints following `debug log before neg[] execution:
/-/       DEBUG 2015.11.17 19:54:41.460 rdb   - | status=`EVENT_STARTED| descr="make negation"| funcName=`.q.neg| arg=`abc| defVal=0N| tsId=2015.11.17D19:54:41.460508000
/-/     - executes neg[`abc]
/-/     - prints following `error log after neg[] execution:
/-/       ERROR 2015.11.17 19:54:41.466 rdb   - | status=`EVENT_FAILED| descr="make negation"| funcName=`.q.neg| signal="type"| tsId=2015.11.17D19:54:41.460948000
/-/     - call returns 0N
.event.at:.event.p.exec[`at];

//----------------------------------------------------------------------------//
/F/ Reports progress of the function which is executed as EVENT - dedicated for long running functions.
/-/ .event.progress[] should be invoked within the code of the function which is executed as EVENT.
/-/ The following actions are taken:
/-/  - event progress is logged
/-/  - event progress is persisted in event files; hose are used by the monitor server
/P/ logModule:SYMBOL - name of the module, used for logging
/P/ funcName:SYMBOL  - function name of the main event
/P/ progress:INT     - progress indicator - integer between 0 and 100
/P/ timeLeft:TIME    - estimated time left for the event completion
/P/ descr:STRING     - description used for log message
/R/ no return value
/E/ .example.iterate:{[m] {[m;i].event.progress[`rdb;`.example.iterate;`int$100*i%m;`time$m-i;"loop"];i}[m] each til m };
/-/     - .example.iterate function reports its progress using .event.progress[]
/-/     - .example.iterate should be executed as event:
/-/       .event.at[`rdb; `.example.iterate; 3; (); `debug`info`error; "iterate "]
/-/     - prints following `debug log before .example.iterate[] execution:
/-/       DEBUG 2015.11.17 20:04:58.413 rdb   - | status=`EVENT_STARTED| descr="iterate "| funcName=`.example.iterate| arg=3| defVal=()| tsId=2015.11.17D20:04:58.412653000
/-/     - prints following set of `info log messages during .example.iterate[] execution:
/-/       INFO  2015.11.17 20:04:58.419 rdb   - | status=`EVENT_PROGRESS| descr="loop"| funcName=`.example.iterate| progress=0i| timeLeft=00:00:00.003| tsId=2015.11.17D20:04:58.413612000
/-/       INFO  2015.11.17 20:04:58.421 rdb   - | status=`EVENT_PROGRESS| descr="loop"| funcName=`.example.iterate| progress=33i| timeLeft=00:00:00.002| tsId=2015.11.17D20:04:58.413612000
/-/       INFO  2015.11.17 20:04:58.423 rdb   - | status=`EVENT_PROGRESS| descr="loop"| funcName=`.example.iterate| progress=67i| timeLeft=00:00:00.001| tsId=2015.11.17D20:04:58.413612000
/-/     - prints following `info log after .example.iterate[] execution:
/-/       INFO  2015.11.17 20:04:58.425 rdb   - | status=`EVENT_COMPLETED| descr="iterate "| funcName=`.example.iterate| resType=7h| resCnt=3| tsId=2015.11.17D20:04:58.413612000
/-/     - call returns 0 1 2
.event.progress:.event.p.progress;

//----------------------------------------------------------------------------//
.event.p.init[];
