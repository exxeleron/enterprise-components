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

/S/ Mocking library

//----------------------------------------------------------------------------//
/F/ Mocks variable. Previous value will be stored on the stack.
/P/ varName:SYMBOL - variable name
/P/ varValue:ANY   - new variable value
/R/ no return value
/E/ .mock.var[.hdb.tables;`trade`quote]
.mock.var:{[varName;varValue]
  .mock.p.push[varName;varValue];
  };

//----------------------------------------------------------------------------//
/F/ Mock function. Function calls will be placed into .mock.trace dictionary. 
/-/ Previous value will be stored on the stack
/P/ func:SYMBOL | STRING - function name
/P/ argCnt:INT           - number of function argument, arguments will be named a0, a1, a2, etc
/P/ resCode:STRING       - additional code used at the end of the function - result from the code will be a result from function
/R/ no return value
/E/ .mock.func[.hdb.status; 1; ":([]table:`trade`quote;format:`PARTITIONED;err:`)"]
.mock.func:{[func;argCnt;resCode]
  if[-11h~type func;func:string[func]];
  .mock.p.push[`.mock.trace;.mock.trace,(enlist[`$func]!enlist[([]ts:`timestamp$();w:`int$();args:())])];
  args:";"sv "a",/:string til argCnt;
  .mock.var[`$func;value "{[",args,"] .mock.trace[`$\"",func,"\"],:([]ts:.z.p;w:.z.w;args:enlist(",args,"));",resCode,"}"];
  };

//---------------------------------------------------------------------------//
/G/ Trace of function calls done using mocks created with .mock.func[].
/-/ key   - function name
/-/ value - table with function calls ([]timestamp, .z.w of the caller, arguments).
/-/       -- ts:TIMESTAMP - timestamp of the call
/-/       -- w:INT        - handle of the caller (.z.w)
/-/       -- args:LIST    - list of the arguments
.mock.trace:(`symbol$())!();

//----------------------------------------------------------------------------//
//                              implementation                                //
//----------------------------------------------------------------------------//
/G/ varname -> varVal list
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
