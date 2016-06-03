/L/ Copyright (c) 2011-2015 Exxeleron GmbH
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

/A/ DEVnet: John Doe
/V/ 3.0

/S/ Short library description.
//                                                   ignored comment
/S/ Longer description of features:
/S/ - featureA
/S/ - featureB
//                                                   ignored comment

//----------------------------------------------------------------------------//
//                             global variables                               //
//----------------------------------------------------------------------------//
/G/ Short description of .mockFunc.globalA.
.mockFunc.globalA:1 2 3;

//----------------------------------------------------------------------------//
/G/ Short description of .mockFunc.globalB.
/G/ Plus some additional deatails.
.mockFunc.globalB:`B;

//----------------------------------------------------------------------------//
//                      function with explicit arguments                      //
//----------------------------------------------------------------------------//
/F/ Function with one argument.
/P/ arg:SYMBOL - symbol argument
/R/ SYMBOL - return value
/E/ .mockFunc.oneArg[`arg1]
.mockFunc.oneArg:{[arg]
  :arg
  };

//----------------------------------------------------------------------------//
//                                                   ignored comment
/F/ Another function with one argument.
//                                                   ignored comment
/F/ Longer descrition with e.g. feature list:
//                                                   ignored comment
/F/ - feature 1
//                                                   ignored comment
/F/ - feature 2
//                                                   ignored comment
/P/ arg:SYMBOL - symbol argument
//                                                   ignored comment
/P/    and some additional detailed information about the arg
//                                                   ignored comment
/R/ SYMBOL - return value
//                                                   ignored comment
/R/    and some additional detailed information about return value
//                                                   ignored comment
/E/ .mockFunc.oneArgB[`arg1]
//                                                   ignored comment
/E/ .mockFunc.oneArgB[`arg2]
//                                                   ignored comment
.mockFunc.oneArgB:{[arg]
  :arg
  };
// ignored comment

//----------------------------------------------------------------------------//
/F/ Function with three arguments
/P/ arg1:SYMBOL - first argument
/P/ arg2:LIST INT - second argument, complex type
/P/ arg3:TABLE([]a:INT;b:LONG;c:SYMBOL) - third argument in form of a table
/R/ SYMBOL - return value
/E/ .mockFunc.multiArg[`arg1;1 2 3;([]a:1 2i;b:11 12j;c:`a`b)]
.mockFunc.multiArg:{[arg1;arg2;arg3]
  :arg
  };

//----------------------------------------------------------------------------//
//                      function with no arguments                            //
//----------------------------------------------------------------------------//
/F/ Function without any arguments.
/R/ SYMBOL - return value
/E/ .mockFunc.noArguments[]
.mockFunc.noArguments:{[]
  :`arg
  };

//----------------------------------------------------------------------------//
//                      functions with implicit arguments                     //
//----------------------------------------------------------------------------//
/F/ Function with implicit argument x.
/P/ x:SYMBOL - implicit argument x
/R/ SYMBOL - return value
/E/ .mockFunc.implicitArg[`a]
.mockFunc.implicitArg:{
  :x
  };

//----------------------------------------------------------------------------//
/F/ Function with implicit arguments x, y and z.
/P/ x:INT - implicit argument x
/P/ y:INT - implicit argument y
/P/ z:INT - implicit argument z
/R/ INT - return value
/E/ .mockFunc.implicitArg[`a]
.mockFunc.implicitArgs:{
  :x+y+z
  };

//----------------------------------------------------------------------------//
//                  functions with incomplete documentation                   //
//----------------------------------------------------------------------------//
.mockFunc.noDocumentation:{[arg]
  :arg
  };

//----------------------------------------------------------------------------//
/F/ Function with the general description only, withoug arg desc.
.mockFunc.justFuncDesc:{[arg]
  :arg
  };

//----------------------------------------------------------------------------//
/P/ arg:INT - only the argument description.
.mockFunc.justArgDesc:{[arg]
  :arg
  };

//----------------------------------------------------------------------------//
/R/ INT - only the return value description.
.mockFunc.justReturnDesc:{[arg]
  :arg
  };

//----------------------------------------------------------------------------//
/E/ .mockFunc.justExampleDoc[12]
.mockFunc.justExampleDoc:{[arg]
  :arg
  };

//----------------------------------------------------------------------------//
//                functions with not an explicit definition                   //
//----------------------------------------------------------------------------//
/F/ Function defined as projection.
.mockFunc.fromProjection:.mockFunc.multiArg[`arg1];

//----------------------------------------------------------------------------//
/F/ Copy of another function.
.mockFunc.fromProjection:.mockFunc.oneArg;

//----------------------------------------------------------------------------//
/