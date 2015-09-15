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

// Functional tests of the hdbWriter component
// See README.md for details

//----------------------------------------------------------------------------//
.testHdbWriter.testSuite:"hdbWriter functional tests";

.testHdbWriter.setUp:{
  .test.start[`t0.hdbw`t0.hdbMock];
  .test.mock[`hdbw; .test.h[`t0.hdbw]];
  .test.mock[`hdbwp; .test.hp[`t0.hdbw]];
  .test.mock[`hdb; .test.h[`t0.hdbMock]];
  };

.testHdbWriter.tearDown:{
  .test.stop `t0.hdbw`t0.hdbMock;
  .test.clearProcDir `t0.hdbw`t0.hdbMock;
  };

//----------------------------------------------------------------------------//
.testHdbWriter.genTrade:{[cnt;day]
  ([]date:day; time:`time$til cnt; sym:cnt#`aaa`bbb;price:`float$til cnt; size:til cnt)
  };

.testHdbWriter.genQuote:{[cnt;day]
  ([]date:day; time:`time$til cnt; sym:cnt#`aaa`bbb;bid:`float$til cnt; bidSize:til cnt;ask:`float$til cnt; askSize:til cnt; flag:cnt?("flagA";"flagB"))
  };

//----------------------------------------------------------------------------//
//                               test hdbWriter                               //
//----------------------------------------------------------------------------//
.testHdbWriter.test.smokeTest_insertTradeDay:{[]
  tradeChunk:.testHdbWriter.genTrade[10;2014.01.01];
  iRes:hdbw(`.hdbw.insert;`trade;tradeChunk);
  iRes:hdbw(`.hdbw.insert;`trade;tradeChunk);
  oRes:hdbw(`.hdbw.organize;`ALL;`ALL);
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);
  .assert.match["hdb contains loaded trade table"; `date`time xasc hdb"select from trade"; `date`time xasc tradeChunk,tradeChunk];
  };

//----------------------------------------------------------------------------//
.testHdbWriter.test.initialState:{[]
  .assert.match["hdbWriter contains 0 global tables"; hdbw"tables[]"; `symbol$()];
  .assert.match["hdbWriter current dir = tmpHdb directory"; .os.slash hdbw"\\cd"; .os.slash  1_-1_string hdbw(`.hdbw.cfg.tmpHdbPath)];
  };

//----------------------------------------------------------------------------//
.testHdbWriter.test.scenario1_insertOrganizeFinalizeTrade:{[]
  // ----- .hdbw.insert[] ----- //
  //preparing data chunk for thrade table
  tradeChunk:.testHdbWriter.genTrade[10;2014.01.01];
  iRes:hdbw(`.hdbw.insert;`trade;tradeChunk);
  // ----- assertions after .hdbw.insert[] ----- //
  tmpHdbPath:hdbw(`.hdbw.cfg.tmpHdbPath);
  .assert.match["tmpHdb/ contains date partition-dir"; key tmpHdbPath; enlist[`2014.01.01]];
  .assert.match["tmpHdb/2014.01.01/ contains trade partition-dir"; key ` sv tmpHdbPath, `2014.01.01`; enlist[`trade]];
  .assert.match["tmpHdb/2014.01.01/trade/ contains column files"; key ` sv tmpHdbPath, `2014.01.01`trade`; `.d`price`size`sym`time];
  .assert.match["hdbWriter contains loaded partitioned trade table"; hdbw"tables[]"; enlist[`trade]];
  .assert.match["hdbWriter contains loaded partitioned trade table"; hdbw".Q.pt"; enlist[`trade]];
  .assert.match["hdbWriter current dir = tmpHdb directory"; .os.slash hdbw"\\cd"; .os.slash  1_-1_string tmpHdbPath];
  .assert.match["trade table in hdbWriter contains exactly the data published via .hdbw.insert command"; hdbw"select from trade"; tradeChunk];
  .assert.match["no attribute `p in trade table"; hdbw"exec c!a from meta trade"; `date`time`sym`price`size!`````];
  .assert.match["no data published to the hdb yet"; hdb"tables[]"; `symbol$()];

  // ----- .hdbw.organize[] ----- //
  oRes:hdbw(`.hdbw.organize;`ALL;`ALL);
  // ----- assertions after .hdbw.organize[] ----- //
  .assert.match["attribute `p on sym column in trade table after .hdbw.organize[]"; hdbw"exec c!a from meta trade"; `date`time`sym`price`size!```p``];
  .assert.match["trade table in hdbWriter contains exactly the data published via .hdbw.insert command (apart of sorting)"; 
    `date`time xasc hdbw"select from trade"; `date`time xasc tradeChunk];
  .assert.match["no data published to the hdb yet"; hdb"tables[]"; `symbol$()];
  .assert.match[".hdb.fillMissingTabs not yet executed on hdb"; count hdb".mock.trace[`.hdb.fillMissingTabs]"; 0];
  .assert.match[".hdb.reload not yet executed on hdb"; count hdb".mock.trace[`.hdb.reload]"; 0];

  // ----- .hdbw.finalize[] ----- //
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);

  // ----- assertions after .hdbw.finalize[] ----- //
  .assert.match[".hdb.fillMissingTabs executed once on hdb"; count hdb".mock.trace[`.hdb.fillMissingTabs]"; 1];
  .assert.match[".hdb.reload executed once on hdb"; count hdb".mock.trace[`.hdb.reload]"; 1];
  .assert.match["trade table in hdb contains exactly the data published via .hdbw.insert command (apart of sorting)"; 
    `date`time xasc hdb"select from trade"; `date`time xasc tradeChunk];
  .assert.match["hdbWriter doesn't have any tables loaded as all data was moved to the hdb"; hdbw"tables[]"; `symbol$()];
  archive:hdbw".hdbw.cfg.archivePath";
  .assert.match["hdbWriter archive is empty as initial hdb was empty"; key .Q.dd[archive;first key archive]; `symbol$()];
  };

//----------------------------------------------------------------------------//
.testHdbWriter.test.scenario2_appendTradeToParitionWithData:{[]
  tradeChunk:.testHdbWriter.genTrade[10;2014.01.01];
  // ----- .hdbw.insert[] ----- //
  iRes:hdbw(`.hdbw.insert;`trade;tradeChunk);
  iRes:hdbw(`.hdbw.insert;`trade;tradeChunk);
  iRes:hdbw(`.hdbw.insert;`trade;tradeChunk);
  oRes:hdbw(`.hdbw.organize;`ALL;`ALL);
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);

  //assert content of the hdb and hdbw
  initialData:`date`time xasc tradeChunk,tradeChunk,tradeChunk;
  .assert.match["trade table in hdb contains exactly the data published via .hdbw.insert command (apart of sorting)"; `date`time xasc hdb"select from trade"; initialData];
  .assert.match["hdbWriter doesn't have any tables loaded as all data was moved to the hdb"; hdbw"tables[]"; `symbol$()];

  iRes:hdbw(`.hdbw.insert;`trade;tradeChunk);
  oRes:hdbw(`.hdbw.organize;`ALL;`ALL);
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);

  //assert content of the hdb and hdbw and of the archive
  .assert.match["trade table in hdb contains exactly the data published via .hdbw.insert command (apart of sorting)"; 
    `date`time xasc hdb"select from trade"; `date`time xasc initialData,tradeChunk];
  .assert.match["hdbWriter doesn't have any tables loaded as all data was moved to the hdb"; hdbw"tables[]"; `symbol$()];

  archivePath:{` sv x,(last key x),`2014.01.01`trade}hdbw".hdbw.cfg.archivePath";
  .assert.match["hdbWriter archive contains the data from before the last .hdbw.finalize call"; 
    `time xasc select time, price, size from archivePath; `time xasc select time, price, size from initialData];
  };

//----------------------------------------------------------------------------//
.testHdbWriter.test.scenario3_insertMultipleTradeDays:{[]
  tradeChunk:raze .testHdbWriter.genTrade[10;] each 2014.01.01 + til 10;
  hdbw(`.hdbw.insert;`trade;tradeChunk);
  oRes:hdbw(`.hdbw.organize;`ALL;`ALL);
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);
  .assert.match["trade table in hdb contains exactly the data published via .hdbw.insert command (apart of sorting)"; 
    `date`time xasc hdb"select from trade"; `date`time xasc tradeChunk];
  .assert.match["hdbWriter doesn't have any tables loaded as all data was moved to the hdb"; hdbw"tables[]"; `symbol$()];
  };

//----------------------------------------------------------------------------//
.testHdbWriter.test.scenario4_insertInterleavedTradeAndQuote:{[]
  tradeChunk:.testHdbWriter.genTrade[10;2014.01.01];
  hdbw(`.hdbw.insert;`trade;tradeChunk);
  quoteChunk:.testHdbWriter.genQuote[10;2014.01.01];
  hdbw(`.hdbw.insert;`quote;quoteChunk);
  tradeChunk2:.testHdbWriter.genTrade[10;2014.01.02];
  hdbw(`.hdbw.insert;`trade;tradeChunk2);

  oRes:hdbw(`.hdbw.organize;`ALL;`ALL);
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);

  .assert.match["trade table in hdb contains exactly the data published via .hdbw.insert command (apart of sorting)"; 
    `date`time xasc hdb"select from trade"; `date`time xasc tradeChunk,tradeChunk2];
  .assert.match["quote table in hdb contains exactly the data published via .hdbw.insert command (apart of sorting)"; 
    `date`time xasc hdb"select from quote"; `date`time xasc quoteChunk];
  .assert.match["hdbWriter doesn't have any tables loaded as all data was moved to the hdb"; hdbw"tables[]"; `symbol$()];
  };

//----------------------------------------------------------------------------//
.testHdbWriter.test.scenario5_insertTradeAsListOfCols:{[]
  tradeChunk:.testHdbWriter.genTrade[10;2014.01.01];
  iRes:hdbw(`.hdbw.insert;`trade;value flip tradeChunk);
  iRes:hdbw(`.hdbw.insert;`trade;value flip tradeChunk);
  oRes:hdbw(`.hdbw.organize;`ALL;`ALL);
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);
  .assert.match["hdb contains loaded trade table"; `date`time xasc hdb"select from trade"; `date`time xasc tradeChunk,tradeChunk];
  };


//----------------------------------------------------------------------------//
//                    invalid commands order                                  //
//----------------------------------------------------------------------------//
.testHdbWriter.test.invalidOrder_finalizeWithoutOrganize:{[]
  tradeChunk:.testHdbWriter.genTrade[10;2014.01.01];
  iRes:hdbw(`.hdbw.insert;`trade;tradeChunk);

  //error during finalization
  .assert.remoteFail["finalize[] without organize[]"; `t0.hdbw;(`.hdbw.finalize;`ALL;`ALL);
    `$"not all tmpHdb partitions are sorted, make sure to call .hdbw.organize[] before using .hdbw.finalize[]"];
  };

.testHdbWriter.test.invalidOrder_organizeWithoutData:{[]
  oRes:hdbw(`.hdbw.organize;`ALL;`ALL);
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);
  //expect no result in the hdb but also no err
  .assert.match["hdb doesn't have any tables loaded as no data was inserted"; hdb"tables[]"; `symbol$()];
  .assert.match["hdbWriter doesn't have any tables loaded as no data was inserted"; hdbw"tables[]"; `symbol$()];
  };

.testHdbWriter.test.invalidOrder_finalizeWithoutData:{[]
  fRes:hdbw(`.hdbw.finalize;`ALL;`ALL);
  //expect no result in the hdb but also no err
  .assert.match["hdb doesn't have any tables loaded as no data was inserted"; hdb"tables[]"; `symbol$()];
  .assert.match["hdbWriter doesn't have any tables loaded as no data was inserted"; hdbw"tables[]"; `symbol$()];
  };

//----------------------------------------------------------------------------//
//                    invalid .hdbw.insert[] arguments                        //
//----------------------------------------------------------------------------//
.testHdbWriter.test.invalidArgs_insertWithInvalidTabName:{[]
  tradeChunk:.testHdbWriter.genTrade[10;2014.01.01];
  .assert.remoteFail["invalid type of tabName"; `t0.hdbw; (`.hdbw.insert;"trade";tradeChunk); `$"invalid tabName type (10h), should be SYMBOL type (-11h)"];
  .assert.remoteFail["unknown tabName"; `t0.hdbw; (`.hdbw.insert;`tradeX;tradeChunk); `$"unknown tabName `tradeX, should be one of `quote`trade"];
  };

//----------------------------------------------------------------------------//
.testHdbWriter.test.invalidArgs_insertWithNonTabFormat:{[]
  tradeChunk:.testHdbWriter.genTrade[10;2014.01.01];
  .assert.remoteFail["data as keyed table"; `t0.hdbw; (`.hdbw.insert;`trade;1!tradeChunk); `$"invalid data type (99h), should be TABLE type (98h) or LIST (0h)"];
  };

//----------------------------------------------------------------------------//
.testHdbWriter.test.invalidArgs_insertWithInvalidModel:{[]
  properChunk:.testHdbWriter.genTrade[10;2014.01.01];

  .assert.remoteFail["too many cols"; `t0.hdbw; (`.hdbw.insert;`trade;update src:`rtr, srcTs:.z.p from properChunk);
    `$"model: col5 \"src(SYMBOL)\" is unexpected, expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  .assert.remoteFail["missing cols"; `t0.hdbw; (`.hdbw.insert;`trade;delete size from properChunk);
    `$"model: col4 \"size(LONG)\" is missing, expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  .assert.remoteFail["invalid cols types"; `t0.hdbw; (`.hdbw.insert;`trade;update time:.z.p, `int$price from properChunk);
    `$"model: col1 \"time(TIMESTAMP)\" should be \"time(TIME)\", expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];

  .assert.remoteFail["invalid cols order"; `t0.hdbw; (`.hdbw.insert;`trade;`date`time`sym`size`price xcols properChunk);
    `$"model: col3 \"size(LONG)\" should be \"price(FLOAT)\", expected model - date(DATE),time(TIME),sym(SYMBOL),price(FLOAT),size(LONG)"];
  };

//----------------------------------------------------------------------------//
//TODO: testcases:
//user reconfigures hdbw while having some data which is not finished
// organize/finalize called when the tmpHdb is empty
// hdb content variations - one or multiple tables, one or multiple partitions
// input - tables which already exists, new tables, new partitions, existing partitions
/
.test.report[]