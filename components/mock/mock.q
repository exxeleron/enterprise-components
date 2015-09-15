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

/S/ Mocking library

//----------------------------------------------------------------------------//
/F/ Mock variable. Previous value will be stored on the stack.
/P/ varName:SYMBOL - variable name
/P/ varValue:ANY - new variable value
.mock.var:{[varName;varValue]
  .mock.p.push[varName;varValue];
  };

//----------------------------------------------------------------------------//
/F/ Mock function. Function calls will be placed into .mock.trace dictionary. 
/F/ Previous value will be stored on the stack
/P/ func:SYMBOL or STRING    - function name
/P/ argCnt:INT     - number of function argument, arguments will be named a0, a1, a2, etc
/P/ resCode:STRING - additional code used at the end of the function - result from the code will be a result from function
.mock.func:{[func;argCnt;resCode]
  if[-11h~type func;func:string[func]];
  .mock.p.push[`.mock.trace;.mock.trace,(enlist[`$func]!enlist[([]ts:`timestamp$();w:`int$();args:())])];
  args:";"sv "a",/:string til argCnt;
  .mock.var[`$func;value "{[",args,"] .mock.trace[`$\"",func,"\"],:([]ts:.z.p;w:.z.w;args:enlist(",args,"));",resCode,"}"];
  };


//---------------------------------------------------------------------------//
/G/ Trace of function calls done using mocks created with .mock.func[]
/G/ key   - function name
/G/ value - table with function calls ([]timestamp, .z.w of the caller, arguments).
/G/        ts:TIMESTAMP - timestamp of the call
/G/        w:INT        - handle of the caller (.z.w)
/G/        args:LIST    - list of the arguments
.mock.trace:(`symbol$())!();

//----------------------------------------------------------------------------//
//                              implementation                                //
//----------------------------------------------------------------------------//
/F/ varname -> varVal list
.mock.p.stack:()!();

//----------------------------------------------------------------------------//
.mock.p.push:{[name;val]
  `name`val set'(name;val);
  .mock.p.stack[name],:enlist@[{(`VAL;value x)};name;enlist`EMPTY];
  treeFunc:(),parse string name;
  .[treeFunc 0;$[`~treeFunc 1;();treeFunc 1];:;val]
  };

//----------------------------------------------------------------------------//
.mock.p.pop:{[name]
  if[0=count .mock.p.stack[name];'"stack empty for ",.Q.s1[name]];
  val:last .mock.p.stack[name];
  .mock.p.stack[name]:-1 _ .mock.p.stack[name];
  if[`VAL~first val;name set last val];
  if[`EMPTY~first val;![`.;();0b;enlist name]]; //TODO: proper cleanup of namepsaces
  };

//----------------------------------------------------------------------------//
