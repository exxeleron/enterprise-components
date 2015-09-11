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
/D/ 2012.02.01

/S/ Event library:
/S/ This library provides API that allows execution of q functions as events.
/S/ The library is loaded automatically in qsl/sl.q (<sl.q>) library

/S/ Benefits of using events:
/S/ Executing function as event results in following benefits
/S/  - function is executed using protected evaluation
/S/  - detailed information about event state is logged using .log.xxx interface - levels can be defined via event API; information is logged using dictionary format (key=value pairs)
/S/  - information about event state is transferred to the monitor server using event files
/S/  - detailed information about event is persisted in event files (the same information as event log message)
/S/  - function execution time is measured

/S/ When to use events:
/S/ - events should be used to execute important system actions (.e.g. process initialization, journal replay, eod process, etc.)
/S/ *Notes:*
/S/ - due to non-zero cost of executing a function as event, events should *not be used* if highest possible performance is required; (e.g. for actions executed on timer or on upd callback)
/S/ - events should be used only if function arguments are of a reasonable size as the arguments will be dumped to an event file

/S/ Event states:
/S/ Execution of selected function is enclosed into set of predefined states
/S/ EVENT_STARTED - event was started
/S/ EVENT_PROGRESS - event is still being executed, <.event.progress> function was used to indicate how much of event work was already done and estimation of time required to finish the execution
/S/ EVENT_COMPLETED - event was completed successfully, i.e. no signal was generated in the executed function
/S/ EVENT_FAILED - event failed - executed function produced a signal

/S/ Event files:
/S/ Information about executed events is persisted in event files. There are four different types of event files
/S/ 1. - Written *before* event execution (EVENT_STARTED) with file name format :
/S/ (start code)
/S/ [componentId].yyyy.mm.ddDhh.mm.ss.xxxxxxxxx.[module]_e1_begin.event
/S/ (end)
/S/ 2. - Written *during* event execution using function <.event.progress[]> (EVENT_PROGRESS) with file name format :
/S/ (start code)
/S/ [componentId].yyyy.mm.ddDhh.mm.ss.xxxxxxxxx.[module]_e2_progress.event
/S/ (end)
/S/ 3. - Written *after successful execution* of the event (EVENT_COMPLETED) with file name format :
/S/ (start code)
/S/ [componentId].yyyy.mm.ddDhh.mm.ss.xxxxxxxxx.[module]_e3_end.event
/S/ (end)
/S/ 4. - Written *after failure* of event (EVENT_FAILED) with file name format :
/S/ (start code)
/S/ [componentId].yyyy.mm.ddDhh.mm.ss.xxxxxxxxx.[module]_e3_signal.event
/S/ (end)

/S/ Event files are written in kdb+ format, therefore these should be examined using q. Each event file contains q dictionary with following fields
/S/ *EVENT_STARTED (e1_begin.event file)*
/S/ -- status:SYMBOL - status of the event = EVENT_STARTED
/S/ -- descr:STRING - description of the event
/S/ -- funcName:SYMBOL - function name which will be executed
/S/ -- arg:ANY - arguments that will be passed to the function (funcName)
/S/ -- defVal:ANY - default value returned in case of event failure
/S/ -- tsId:TIMESTAMP - timestamp identificator of the event, together with componentId it should be used to match event begin with event progress and end files
/S/ -- module:SYMBOL - module name
/S/ -- level:SYMBOL - level of the message (based on levels parameter from the interface function)
/S/ -- ts:TIMESTAMP - timestamp of the file creation
/S/ -- componentId:SYMBOL - componentId of process that generated event

/S/ *EVENT_PROGRESS (e2_progress.event file)*
/S/ -- status:SYMBOL - status of the event = EVENT_STARTED
/S/ -- descr:STRING - description of the event
/S/ -- funcName:SYMBOL - function name which will be executed
/S/ -- progress:INT - progress of event completion in %
/S/ -- timeLeft:TIME - estimated time for event completion in milliseconds
/S/ -- tsId:TIMESTAMP - timestamp identificator of the event, together with componentId it should be used to match event begin with event progress and end files
/S/ -- module:SYMBOL - module name
/S/ -- level:SYMBOL - level of the message (based on levels parameter from the interface function)
/S/ -- ts:TIMESTAMP - timestamp of the file creation
/S/ -- componentId:SYMBOL - componentId of process that generated event

/S/ *EVENT_COMPLETED (e3_end.event file)*
/S/ -- status:SYMBOL - status of the event = EVENT_COMPLETED
/S/ -- descr:STRING - description of the event
/S/ -- funcName:SYMBOL - function name which will be executed
/S/ -- resType:SHORT - type of variable returned by event function
/S/ -- resCnt:INT - count of elements in variable returned by event function
/S/ -- tsId:TIMESTAMP - timestamp identificator of the event, together with componentId it should be used to match event begin with event progress and end files
/S/ -- module:SYMBOL - module name
/S/ -- level:SYMBOL - level of the message (based on levels parameter from the interface function)
/S/ -- ts:TIMESTAMP - timestamp of the file creation
/S/ -- componentId:SYMBOL - componentId of process that generated event

/S/ *EVENT_FAILED (e3_signal.event file)*
/S/ -- status:SYMBOL - status of the event = EVENT_FAILED
/S/ -- descr:STRING - description of the event
/S/ -- funcName:SYMBOL - function name which will be executed
/S/ -- signal:STRING - signal thrown by executed event function
/S/ -- tsId:TIMESTAMP - timestamp identificator of the event, together with componentId it should be used to match event begin with event progress and end files
/S/ -- module:SYMBOL - module name
/S/ -- level:SYMBOL - level of the message (based on levels parameter from the interface function)
/S/ -- ts:TIMESTAMP - timestamp of the file creation
/S/ -- logDiff:DICT - number of warning, error and fatal log messages generated during event function execution
/S/ -- componentId:SYMBOL - componentId of process that generated event

/S/ Error handling responsibility:
/S/ Event library catches signals generated within executed user functions and event ends in the EVENT_FAILED state.
/S/ Following errors are propagated as signal (and *do not* have final state EVENT_FAILED) :
/S/ - non-existing function
/S/ - function body instead of function name
/S/ - invalid number of arguments to function (too few or too many)
/S/ - wrong function parameter type (e.g. single value in case of .pe.dot)
/S/ Those cases should be handled by the programmer.

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


/F/ base for .event.at and .event.dot functions
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


//---------------------------------------------------------------------------//
/F/ log event for function with two or more arguments; the following actions are taken:
/F/  - function is executed using protected evaluation
/F/  - event is logged using .log logging interface, log levels are set according to "levels" argument
/F/  - event information is persisted in event files; those are used by the monitor server
/F/  - number of logged errors and warnings that happens during function execution is counted and stored in event file
/F/  - function execution time is measured
/P/ module:SYMBOL - name of the module, used for logging
/P/ funcName:SYMBOL - function name (e.g. `foo1)
/P/ args:LIST - list of arguments
/P/ defVal:ANY - default value to be returned in case of the error
/P/ levels:LIST[SYMBOL] - log levels for start/complete/failed event
/P/ desc:STRING - event description  
/R/ value returned by executed function or a default value in case of func failure.
/E/.event.dot[`rdb; `.q.ssr; ("text";"x";"s"); `failed; `info`info`error; "eod process for ", string .z.d+1]
.event.dot:.event.p.exec[`dot];

//---------------------------------------------------------------------------//
/F/ log event for function with zero or one argument; the following actions are taken:
/F/  - function is executed using protected evaluation
/F/  - event is logged using .log logging interface, log levels is set according to the "levels" argument
/F/  - event information is persisted in event files; those are used by monitor server
/F/  - number of logged errors and warnings that happens during function execution is counted and stored in event file
/F/  - function execution time is measured
/P/ module:SYMBOL - name of the module, used for logging
/P/ funcName:SYMBOL - function name (e.g. `foo1)
/P/ args:LIST - list of the arguments
/P/ defVal:ANY - default value to be returned in case of the error
/P/ levels:LIST SYMBOL - three log levels for start/complete/failed event (e.g. levels=`info`info`error will cause logging start and completed events as info messages and failure event as error message)
/P/ desc:STRING - event description  
/R/ value returned by executed function or a default value in case of func failure
/E/.event.at[`rdb; `.log.p.dictToStr;(enlist `a)!(enlist `b); `failed; `info`info`error; "report generation for ", string .z.d]
/E/.event.at[`rdb; `.log.p.dictToStr;"wrongInput"; `failed; `info`info`error; "report generation for ", string .z.d]
.event.at:.event.p.exec[`at];

//---------------------------------------------------------------------------//
/F/ function dedicated for long events; allows notifications about event state; the following actions are taken:
/F/  - event progress is logged
/F/  - event progress is persisted in event files; hose are used by the monitor server
/P/ logModule:SYMBOL - name of the module, used for logging
/P/ funcName:SYMBOL - function name of the main event
/P/ progress:INT - progress indicator - integer between 0 and 100
/P/ timeLeft:TIME - estimated time left for the event completion
/P/ desc:STRING - description used for log message
/E/.event.progress[`rdb; `.event.p.init; 25; 00:00:01.012; "replayed 100213 messages"]
.event.progress:.event.p.progress;

//---------------------------------------------------------------------------//
.event.p.init[];
