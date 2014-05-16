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

/A/ DEVnet: Rafal Sytek
/V/ 3.0
/D/ 2011.06.17

/S/ Protected evaluation library:
/S/ Library provides API for invoking functions in protected evaluation
/S/ The library is loaded automatically in qsl/sl.q (<sl.q>) library

/S/ Features:
/S/ - handling both anonymous and non-anonymous functions
/S/ - signal handler can be defined by user
/S/ - can be turned on and off during runtime
/S/ - extended log messaging (e.g. function name, args etc.)

//--------------------------------- Globals ----------------------------------//
/G/ global variable that allows to set protected evaluation on (1b) and off (0b) [BOOLEAN]
.pe.enabled:1b;
//--------------------------------- Interface ----------------------------------//
/F/ dynamically turns protected evaluation on during runtime
/E/ .pe.enable[]
.pe.enable:{[]
  .pe.at:.pe.p.orig.at;
  .pe.atLog:.pe.p.orig.atLog;
  .pe.dot:.pe.p.orig.dot;
  .pe.dotLog:.pe.p.orig.dotLog;
  .pe.enabled:1b;
  };

/F/ dynamically turns protected evaluation off during runtime
/E/ .pe.disable[]
.pe.disable:{[]
  .pe.at:    {[func; arg; errH]                  func @ arg};
  .pe.atLog: {[module;funcName; arg; defVal; logLevel]  funcName @ arg};  
  .pe.dot:   {[func; args; errH]                 func . args}; 
  .pe.dotLog:{[module;funcName; args; defVal; logLevel] funcName . args};
  .pe.enabled:0b;
  };

/F/ functions with no or one argument
/P/ func - function (e.g. foo1 - *no backtick!*, or body of the function: 
/P/ {[ ] :2+3}, or in general any anonymous function)
/P/ arg:ATOM - empty list if function takes no arguments or an atom
/P/ errH:ANY - error handler, expression or function that takes a signal as 
/P/ an input that will be returned by the .pe.at
.pe.at:{[func;arg;errH]
  @[func; arg; errH]
  };

/F/ functions with no or one argument
/F/ with built-in logging
/P/ module:SYMBOL - name of the module
/P/ funcName:SYMBOL - function name (e.g. `foo1)
/P/ arg:ATOM - empty list if function takes no arguments or an atom
/P/ defVal:ANY - default value to be returned in case of the error
/P/ logLevel:SYMBOL - `error, `fatal, `warn 
.pe.atLog:{[module;funcName;arg;defVal;logLevel]
  errH:{[m;l;f;a;d;x]
    .log[l][m] $[10h=type f;f;string f], " received ", (.Q.s1 a), ", failed with [", x, "]";
    d}[module;logLevel;funcName;arg;defVal];
  @[value funcName;arg;errH]
  };

/F/ functions with at least two arguments
/P/ func - function (e.g. foo1 - *no backtick!*, or body of the function: {[ ] :2+3}, 
/P/ or in general any anonymous function)
/P/ args:LIST - list of the arguments
/P/ errH:ANY - error handler, expression or function that takes a signal as an input 
/P/ that will be returned by the .pe.dot
.pe.dot:{[func;args;errH]
  .[func; args; errH]
  };

/F/ functions with at least two arguments
/F/ with built-in logging
/P/ module:SYMBOL - name of the module
/P/ funcName:SYMBOL - function name (e.g. `foo1)
/P/ args:LIST - list of the arguments
/P/ defVal:ANY - default value to be returned in case of the error
/P/ logLevel:SYMBOL - `error, `fatal `warn 
.pe.dotLog:{[module;funcName;args;defVal;logLevel]
  errH:{[m;l;f;a;d;x]
    .log[l][m] $[10h=type f;f;string f], " received ", (.Q.s1 a), ", failed with [", x, "]";
    d}[module;logLevel;funcName;args;defVal];
  .[value funcName;args;errH]
  };

/------------- Private functions ----------------------------------------------/ 
/F/ initialize protected evaluation
/P/ enabled:Bool - true if protected evaluation is enabled
/E/ .pe.init[1b]
.pe.init:{[enabled]
  $[enabled; .pe.enable[]; .pe.disable[]];
  };
  
if[not `p in key .pe; 
  .pe.p.orig.at:.pe.at;
  .pe.p.orig.atLog:.pe.atLog;
  .pe.p.orig.dot:.pe.dot;
  .pe.p.orig.dotLog:.pe.dotLog;
  ];
