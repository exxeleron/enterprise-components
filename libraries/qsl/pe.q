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

/A/ DEVnet: Rafal Sytek
/V/ 3.0
/D/ 2011.06.17

/S/ Protected evaluation library:
/-/ Library provides API for invoking functions in protected evaluation
/-/ The library is loaded automatically in qsl/sl.q (<sl.q>) library

/-/ Features:
/-/ - handling both anonymous and non-anonymous functions
/-/ - signal handler can be defined by user
/-/ - can be turned on and off during runtime
/-/ - extended log messaging (e.g. function name, args etc.)

//--------------------------------- Globals ----------------------------------//
/G/ Global variable that allows to set protected evaluation on (1b) and off (0b) [BOOLEAN].
.pe.enabled:1b;

//----------------------------------------------------------------------------//
//                          interface functions                               //
//----------------------------------------------------------------------------//
/F/ Dynamically turns protected evaluation on during runtime.
/R/ no return value
/E/ .pe.enable[]
.pe.enable:{[]
  .pe.at:.pe.p.orig.at;
  .pe.atLog:.pe.p.orig.atLog;
  .pe.dot:.pe.p.orig.dot;
  .pe.dotLog:.pe.p.orig.dotLog;
  .pe.enabled:1b;
  };

/F/ Dynamically turns protected evaluation off during runtime.
/R/ no return value
/E/ .pe.disable[]
.pe.disable:{[]
  .pe.at:    {[func; arg; errH]                  func @ arg};
  .pe.atLog: {[module;funcName; arg; defVal; logLevel]  funcName @ arg};  
  .pe.dot:   {[func; args; errH]                 func . args}; 
  .pe.dotLog:{[module;funcName; args; defVal; logLevel] funcName . args};
  .pe.enabled:0b;
  };

//----------------------------------------------------------------------------//
/F/ Executes function with zero or one argument in protected evaluation.
/P/ func:FUNCTION - function (e.g. foo1 - *no backtick!*, or body of the function
/-/                  {[ ] 2+3}, or in general any anonymous function)
/P/ arg:ATOM - empty list if function takes no arguments or an atom
/P/ errH:ANY - error handler, expression or function that takes a signal as 
/-/            an input that will be returned by the .pe.at
/R/ ANY - result of the function evaluation,
/-/       in case of evaluation failure - returns output from the errH
/E/ .pe.at[neg; 121; {0N!"signal:",x; 0N}]
/-/     - executes neg[121]
/-/     - call returns -121
/E/ .pe.at[neg; `abc; {0N!"signal:'",x; 0N}]
/-/     - executes neg[`abc]
/-/     - prints "signal:'type" on standard output
/-/     - call returns 0N
.pe.at:{[func;arg;errH]
  @[func; arg; errH]
  };

/F/ Executes function with zero or one argument in protected evaluation, with built-in failure logging and returing default value.
/P/ module:SYMBOL   - name of the module
/P/ funcName:SYMBOL - function name (e.g. `foo1)
/P/ arg:ATOM        - empty list if function takes no arguments or an atom
/P/ defVal:ANY      - default value to be returned in case of the error
/P/ logLevel:SYMBOL - `error, `fatal, `warn 
/R/ ANY - result of the function evaluation,
/-/       in case of evaluation failure - returns defVal
/E/ .pe.atLog[`example;`.q.neg; 121; 0N; `error]
/-/     - executes neg[121]
/-/     - call returns -121
/E/ .pe.atLog[`example;`.q.neg; `abc; 0N; `error]
/-/     - executes neg[`abc]
/-/     - prints error log message:
/-/       ERROR 2015.11.17 12:30:31.678 exampl- .q.neg received `abc, failed with [type]
/-/     - call returns 0N
.pe.atLog:{[module;funcName;arg;defVal;logLevel]
  errH:{[m;l;f;a;d;x]
    .log[l][m] $[10h=type f;f;string f], " received ", (.Q.s1 a), ", failed with [", x, "]";
    d}[module;logLevel;funcName;arg;defVal];
  @[value funcName;arg;errH]
  };

//----------------------------------------------------------------------------//
/F/ Executes function with at least two arguments in protected evaluation.
/P/ func:FUNCTION - function (e.g. foo1 - *no backtick!*, or body of the function: {[ ] 2+3}, 
/-/                 or in general any anonymous function)
/P/ args:LIST - list of the arguments
/P/ errH:ANY  - error handler, expression or function that takes a signal as an input 
/-/             that will be returned by the .pe.dot
/R/ ANY - result of the function evaluation,
/-/       in case of evaluation failure - returns output from the errH
/E/ .pe.dot[ssr; ("text";"x";"s"); {0N!"signal:",x; "--"}]
/-/     - executes ssr["text";"x";"s"] (replace all "x" with "s" in the "text" string)
/-/     - call returns "test"
/E/ .pe.dot[ssr; ("text";121;"s"); {0N!"signal:'",x; "--"}]
/-/     - executes ssr["text";121;"s"] (tries replace all 121 with "s" in the "text" string)
/-/     - prints "signal:'type" on standard output
/-/     - call returns "--"
.pe.dot:{[func;args;errH]
  .[func; args; errH]
  };

/F/ Executes function with at least two arguments in protected evaluation, with built-in failure logging and returing default value.
/P/ module:SYMBOL   - name of the module
/P/ funcName:SYMBOL - function name (e.g. `foo1)
/P/ args:LIST       - list of the arguments
/P/ defVal:ANY      - default value to be returned in case of the error
/P/ logLevel:SYMBOL - `error `fatal or `warn 
/R/ ANY - result of the function evaluation,
/-/       in case of evaluation failure - returns defVal
/E/ .pe.dotLog[`example; `.q.ssr; ("text";"x";"s"); "--"; `error]
/-/     - executes ssr["text";"x";"s"] (replace all "x" with "s" in the "text" string)
/-/     - call returns "test"
/E/ .pe.dotLog[`example; `.q.ssr; ("text";121;"s"); "--"; `error]
/-/     - executes ssr["text";121;"s"] (tries replace all 121 with "s" in the "text" string)
/-/     - prints error log message:
/-/       ERROR 2015.11.17 12:37:43.757 exampl- .q.ssr received ("text";121;"s"), failed with [type]
/-/     - call returns "--"
.pe.dotLog:{[module;funcName;args;defVal;logLevel]
  errH:{[m;l;f;a;d;x]
    .log[l][m] $[10h=type f;f;string f], " received ", (.Q.s1 a), ", failed with [", x, "]";
    d}[module;logLevel;funcName;args;defVal];
  .[value funcName;args;errH]
  };

//----------------------------------------------------------------------------//
/F/ Initialize protected evaluation module. Automatically invoked in .sl.init[] on process startup.
/P/ enabled:BOOLEAN - true if protected evaluation is enabled
/R/ no return value
/E/ .pe.init[1b]
.pe.init:{[enabled]
  $[enabled; .pe.enable[]; .pe.disable[]];
  };
  
//----------------------------------------------------------------------------//
if[not `p in key .pe; 
  .pe.p.orig.at:.pe.at;
  .pe.p.orig.atLog:.pe.atLog;
  .pe.p.orig.dot:.pe.dot;
  .pe.p.orig.dotLog:.pe.dotLog;
  ];
