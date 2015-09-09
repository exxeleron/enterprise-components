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

/A/ DEVnet: Pawel Hudak
/V/ 3.0

// Functional tests of the qsl/tabs library

//Executing tests (assuming ec is deployed in the bin direcotory):
// - prepare env on linux:
//   KdbSystemDir> source bin/ec/libraries/qsl/test/tabs/etc/env.sh
// - prepare env on windows:
//   KdbSystemDir> bin\ec\libraries\qsl\test\tabs\etc\env.bat
// - start tests:
//   KdbSystemDir> yak start t.run
// - check progress:
//   KdbSystemDir> yak log t.run
// - inspect results:
//   inspect .test.report[] on the t.run once the tests are completed

//----------------------------------------------------------------------------//
//                                libraries                                   //
//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`qslTabs_functionalTests];
.sl.lib["qsl/os"];

//----------------------------------------------------------------------------//
//                           qsl/tabs test                                    //
//----------------------------------------------------------------------------//
.testQslTabs.testSuite:"qsl/tabs functional tests";

//----------------------------------------------------------------------------//
.testQslTabs.setUp:{
  .test.start`t.tabs;
  };

//----------------------------------------------------------------------------//
.testQslTabs.tearDown:{
  .test.stop`t.tabs;
  };

//----------------------------------------------------------------------------//
.testQslTabs.genTrade:{[cnt;day]
  ([]date:day; time:`time$til cnt; sym:cnt#`aaa`bbb;price:`float$til cnt; size:til cnt)
  };

.testQslTabs.genQuote:{[cnt;day]
  ([]date:day; time:`time$til cnt; sym:cnt#`aaa`bbb;bid:`float$til cnt; bidSize:til cnt;ask:`float$til cnt; askSize:til cnt; flag:cnt?("flagA";"flagB"))
  };

//----------------------------------------------------------------------------//
//                            valid data                                      //
//----------------------------------------------------------------------------//
.testQslTabs.test.validateCorrectTradeTab:{[]
  properChunk:.testQslTabs.genTrade[10;2014.01.01];

  res:.test.h[`t.tabs](`.tabs.validate;0#properChunk;properChunk);
  .assert.match[".tabs.validate returns properChunk"; res; properChunk];
  };

//----------------------------------------------------------------------------//
.testQslTabs.test.validateCorrectQuoteTab:{[]
  properChunk:.testQslTabs.genQuote[10;2014.01.01];

  res:.test.h[`t.tabs](`.tabs.validate;1#properChunk;properChunk);
  .assert.match[".tabs.validate returns properChunk"; res; properChunk];
  };

//----------------------------------------------------------------------------//
.testQslTabs.test.validateCorrectTradeColList:{[]
  properChunk:.testQslTabs.genTrade[10;2014.01.01];

  res:.test.h[`t.tabs](`.tabs.validate;0#properChunk;value flip properChunk);
  .assert.match[".tabs.validate returns properChunk as table"; res; properChunk];
  };

//----------------------------------------------------------------------------//
//                          invalid data                                      //
//----------------------------------------------------------------------------//
.testQslTabs.test.validateUnsupportedType:{[]
  properChunk:.testQslTabs.genTrade[10;2014.01.01];
  types:(.Q.t except "gs ")$\:"0";
  .assert.remoteFail'["invalid type ",/:string type each types; `t.tabs; (`.tabs.validate;0#properChunk),/:types; `$"table should be of type 98h or 0h"];
  };

//----------------------------------------------------------------------------//
.testQslTabs.test.validateInvalidModelTable:{[]
  properChunk:.testQslTabs.genTrade[10;2014.01.01];

  .assert.remoteFail["too many cols"; `t.tabs;(`.tabs.validate;0#properChunk;update src:`rtr, srcTs:.z.p from properChunk);
    `$"model: col5 \"src(SYMBOL)\" is unexpected, expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  .assert.remoteFail["missing cols"; `t.tabs;(`.tabs.validate;0#properChunk;delete size from properChunk);
    `$"model: col4 \"size(LONG)\" is missing, expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  .assert.remoteFail["invalid col types"; `t.tabs;(`.tabs.validate;0#properChunk;update time:.z.p, `int$price from properChunk);
    `$"model: col1 \"time(TIMESTAMP)\" should be \"time(TIME)\", expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  .assert.remoteFail["invalid col order"; `t.tabs;(`.tabs.validate;0#properChunk;`date`time`sym`size`price xcols properChunk);
    `$"model: col3 \"size(LONG)\" should be \"price(FLOAT)\", expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];
  };

//----------------------------------------------------------------------------//
.testQslTabs.test.validateInvalidColList:{[]
  properChunk:.testQslTabs.genTrade[10;2014.01.01];

  .assert.remoteFail["too many cols"; `t.tabs;(`.tabs.validate;0#properChunk;value flip update src:`rtr, srcTs:.z.p from properChunk);
    `$"model: col5 \"col5(SYMBOL)\" is unexpected, expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  .assert.remoteFail["missing cols"; `t.tabs;(`.tabs.validate;0#properChunk;value flip delete size from properChunk);
    `$"model: col4 \"size(LONG)\" is missing, expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  .assert.remoteFail["invalid col types"; `t.tabs;(`.tabs.validate;0#properChunk;value flip update time:.z.p, `int$price from properChunk);
    `$"model: col1 \"time(TIMESTAMP)\" should be \"time(TIME)\", expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  //note: invalid cols order can be only recognized if the types are wrong - see previous assert (as in this test case data is sent without column names)
  };

//----------------------------------------------------------------------------//
//.test.getInterfaceList`.tabs

//TODO: 
// validate with empty table
// validate with keyed table
// validate with non-table format
