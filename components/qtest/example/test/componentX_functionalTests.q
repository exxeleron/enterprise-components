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

/A/ DEVnet: componentX tests author
/V/ 3.0

// Functional tests of the componentX component

//----------------------------------------------------------------------------//
//                                libraries                                   //
//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`componentX_functionalTests];
.sl.lib["qsl/os"];

//----------------------------------------------------------------------------//
//                                 tests                                      //
//----------------------------------------------------------------------------//
.componentXTest.testSuite:"componentX functional tests";
//----------------------------------------------------------------------------//
.componentXTest.setUp:{
  .test.start[`t0.componentX`t0.hdbMock];
  };

.componentXTest.tearDown:{
  .test.stop[`t0.componentX`t0.hdbMock];
  };

//----------------------------------------------------------------------------//
//helper function
.componentXTest.genTrade:{[cnt;day]
  ([]date:day; time:`time$til cnt; sym:cnt#`aaa`bbb;price:`float$til cnt; size:til cnt)
  };

//----------------------------------------------------------------------------//
.componentXTest.test.call_getCols:{[]
  // Arrange
  tradeChunk:.componentXTest.genTrade[10;2014.01.01];
  
  // Act
  res:.test.h[`t0.componentX](`.componentX.getCols;tradeChunk);
  
  // Assert
  .assert.match["return list of columns"; res; cols tradeChunk];
  };

//----------------------------------------------------------------------------//
.componentXTest.test.failWith_NonTableArg:{[]
  .assert.remoteFail["support only table"; `t0.componentX; (`.componentX.getCols;5); `$"expecting type 98h"];
  };
  
//----------------------------------------------------------------------------//
/
.test.report[]
