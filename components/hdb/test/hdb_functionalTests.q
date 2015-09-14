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

// Functional tests of the hdb component
// See README.md for details

//----------------------------------------------------------------------------//
.testHdb.testSuite:"hdb functional tests";

.testHdb.setUp:{
  .test.start[`t0.hdb];
  .test.mock[`hdb; .test.h[`t0.hdb]];

  .cr.loadCfg[`t0.hdb];  //load hdb specific configuration fields
  .test.mock[`hdbPath;.cr.getCfgField[`t0.hdb;`group;`cfg.hdbPath]]; //extract hdbPath
  };

.testHdb.tearDown:{
  .test.stop `t0.hdb;
  .test.clearProcDir `t0.hdb;
  };

//----------------------------------------------------------------------------//
.testHdb.genTrade:{[cnt]
  ([]time:`time$til cnt; sym:cnt#`aaa`bbb;price:`float$til cnt; size:til cnt)
  };

.testHdb.genQuote:{[cnt]
  ([] time:`time$til cnt; sym:cnt#`aaa`bbb;bid:`float$til cnt; bidSize:til cnt;ask:`float$til cnt; askSize:til cnt; flag:cnt?("flagA";"flagB"))
  };

//----------------------------------------------------------------------------//
//                      startup hdb state                                     //
//----------------------------------------------------------------------------//
.testHdb.test.emptyHdb:{[]
  .assert.match["no tables in the hdb process";hdb"tables[]";`symbol$()];
  .assert.matchModel[".hdb.status[] has correct datamodel";hdb".hdb.status[]";([]tab:`symbol$();format:();rowsCnt:();err:();columns:())];
  .assert.match[".hdb.status[] is empty";hdb"count .hdb.status[]";0];
  .assert.match[".hdb.cfg.hdbPath field is set to cfg.hdbPath directory";hdb".hdb.cfg.hdbPath";hdbPath];
  .assert.match["current directory is set to cfg.hdbPath directory";hsym`$ssr[hdb"\\cd";"\\";"/"],"/";hdbPath];
  .assert.match["current directory is empty";key hdbPath;`symbol$()];

  .assert.match[".hdb.statusByPar[] has correct datamodel and is empty";hdb".hdb.statusByPar[]";([]parDir:`symbol$())];

  hdb".hdb.fillMissingTabs[]";
  .assert.match[".hdb.fillMissingTabs[] didn't change status";hdb"count .hdb.status[]";0];

  hdb".hdb.reload[]";
  .assert.match[".hdb.relaad[] didn't change status";hdb"count .hdb.status[]";0];
  };

//----------------------------------------------------------------------------//
.testHdb.test.onePartitionedTab:{[]
  //write single trade partition
  .Q.par[hdbPath;2015.01.01;`$"trade/"] set .Q.en[hdbPath] tradeChunk:.testHdb.genTrade[10];
  .assert.match["data already exists on disk";key hdbPath;`2015.01.01`sym];
  .assert.match["still no table visible before invoking .hdb.reload[]";hdb"tables[]";`symbol$()];
  //reload hdb process
  hdb".hdb.reload[]";
  .assert.match["table visible in the hdb after invoking .hdb.reload[]";hdb"tables[]";enlist`trade];
  .assert.match["trade table contains stored records with added date column";hdb"select from trade";`date xcols update date:2015.01.01 from tradeChunk];
  .assert.match[".hdb.status[] contains trade table entry";hdb".hdb.status[]";([]tab:enlist`trade;format:`PARTITIONED;rowsCnt:10;err:`;columns:enlist`date`time`sym`price`size)];
  .assert.match[".hdb.statusByPar[] contains 2015.01.01 entry";hdb".hdb.statusByPar[]";([]date:enlist 2015.01.01;parDir:`:.;trade:10)];
  };

//----------------------------------------------------------------------------//
.testHdb.test.fillingEmptyPartitions:{[]
  //write one trade and one quote partition
  .Q.par[hdbPath;2015.01.01;`$"trade/"] set .Q.en[hdbPath] tradeChunk:.testHdb.genTrade[10];
  .Q.par[hdbPath;2015.01.02;`$"quote/"] set .Q.en[hdbPath] quoteChunk:.testHdb.genQuote[10];
  .assert.match["hdbPath contains two partitions";key hdbPath;`2015.01.01`2015.01.02`sym];
  .assert.match["2015.01.01 contains only trade partition";key .Q.dd[hdbPath;`2015.01.01];enlist`trade];
  .assert.match["2015.01.02 contains only quote partition";key .Q.dd[hdbPath;`2015.01.02];enlist`quote];
  .assert.match["no table visible in hdb before invoking .hdb.reload[]";hdb"tables[]";`symbol$()];

  //reload hdb process without invoking .hdb.fillMissingTabs[]
  hdb".hdb.reload[]";
  .assert.match["only quote visible before invoking .hdb.fillMissingTabs[]";hdb"tables[]";enlist`quote];
  .assert.remoteFail["unable to trade table due to missing empty partition";`t0.hdb;"select from quote";"./2015.01.01/quote/time: The system cannot find the path specified."];

  //invoke .hdb.fillMissingTabs[]
  hdb".hdb.fillMissingTabs[]";
  .assert.match["2015.01.01 contains now both quote and trade partitions";key .Q.dd[hdbPath;`2015.01.01];`quote`trade];
  .assert.match["2015.01.02 contains now both quote and trade partitions";key .Q.dd[hdbPath;`2015.01.02];`quote`trade];
  .assert.match["still only quote visible before invoking .hdb.reload[]";hdb"tables[]";enlist`quote];
  .assert.match["quote query already working";hdb"select from quote";`date xcols update date:2015.01.02 from quoteChunk];

  //reload hdb after .hdb.fillMissingTabs[]
  hdb".hdb.reload[]";
  .assert.match["now both trade and quote visible";hdb"tables[]";`quote`trade];
  .assert.match["quote query stil working";hdb"select from quote";`date xcols update date:2015.01.02 from quoteChunk];
  .assert.match["trade qurey also working";hdb"select from trade";`date xcols update date:2015.01.01 from tradeChunk];

  .assert.match[".hdb.status[] contains trade table entry";hdb".hdb.status[]";([]tab:`quote`trade;format:`PARTITIONED;rowsCnt:10;err:`;columns:(`date,cols[quoteChunk];`date,cols[tradeChunk]))];
  .assert.match[".hdb.statusByPar[] contains 2015.01.01 and 2015.01.01 entries";hdb".hdb.statusByPar[]";([]date:2015.01.01 2015.01.02;parDir:`:.;quote:0 10;trade:10 0)];
  };

//----------------------------------------------------------------------------//
.testHdb.test.dataVolumeHourly:{[]
  .Q.par[hdbPath;2015.01.01;`$"trade/"] set .Q.en[hdbPath] tradeChunk:.testHdb.genTrade[10];
  .Q.par[hdbPath;2015.01.02;`$"quote/"] set .Q.en[hdbPath] quoteChunk:.testHdb.genQuote[10];
  hdb".hdb.fillMissingTabs[]";
  hdb".hdb.reload[]";
  //execute hourly statistics
  stats:hdb".hdb.dataVolumeHourly[`trade;2015.01.01]";
  .assert.matchModel[".hdb.dataVolumeHourly[] returns correct model";stats;([]hdbDate:`date$();hour:`time$();table:`symbol$();totalRowsCnt:`long$();minRowsPerSec:`long$();avgRowsPerSec:`long$();medRowsPerSec:`long$();maxRowsPerSec:`long$();dailyMedRowsPerSec:`long$())];
  .assert.match["all rows are for day 2015.01.01";distinct stats`hdbDate;enlist 2015.01.01];
  .assert.match["hours are covering entire day";stats`hour;01:00:00.000*til 24];
  .assert.match["all rows are for `trade table";distinct stats`table;enlist `trade];  
  .assert.match["sum of totalRowsCnt is correct";exec sum totalRowsCnt from stats;10j];  

  //.hdb.dataVolumeHourly[] with missing date
  emptyStats:hdb".hdb.dataVolumeHourly[`trade;2010.01.02]";
  .assert.matchModel[".hdb.dataVolumeHourly[] returns correct model";emptyStats;([]hdbDate:`date$();hour:`time$();table:`symbol$();totalRowsCnt:`long$();minRowsPerSec:`long$();avgRowsPerSec:`long$();medRowsPerSec:`long$();maxRowsPerSec:`long$();dailyMedRowsPerSec:`long$())];
  .assert.match["all rows are for day 2010.01.02";distinct emptyStats`hdbDate;enlist 2010.01.02];
  .assert.match["hours are covering entire day";emptyStats`hour;01:00:00.000*til 24];
  .assert.match["all rows are for `trade table";distinct emptyStats`table;enlist `trade];  
  .assert.match["sum of totalRowsCnt is correct";exec sum totalRowsCnt from emptyStats;0j];  
  };

//----------------------------------------------------------------------------//
.testHdb.test.dataVolumeHourly_invalidArgs:{[]
  .Q.par[hdbPath;2015.01.01;`$"trade/"] set .Q.en[hdbPath] tradeChunk:.testHdb.genTrade[10];
  hdb".hdb.reload[]";
  .assert.remoteFail["signal in case of unknown table name";`t0.hdb;(`.hdb.dataVolumeHourly;`tradeXX;2010.01.01);"tradeXX"];
  .assert.remoteFail["signal in case of unknown table name";`t0.hdb;(`.hdb.dataVolumeHourly;"trade";2010.01.01);`$"invalid tab type (10h), should be SYMBOL type (-11h)"];
  .assert.remoteFail["signal in case of unknown table name";`t0.hdb;(`.hdb.dataVolumeHourly;`trade;2010.01m);`$"invalid day type (-13h), should be DATE type (-14h)"];
  };

//----------------------------------------------------------------------------//
.testHdb.test.twoPartitionedTabs_missingPartition:{[]
  //write one trade and one quote partition (different dates)
  (pathA:.Q.par[hdbPath;2015.01.01;`$"trade/"]) set .Q.en[hdbPath] tradeChunk:.testHdb.genTrade[10];
  (pathB:.Q.par[hdbPath;2015.01.02;`$"quote/"]) set .Q.en[hdbPath] quoteChunk:.testHdb.genQuote[10];
  .assert.match["all column-files in 2015.01.01/trade/ dir";key pathA;`.d`price`size`sym`time];
  .assert.match["all column-files in 2015.01.02/quote/ dir";asc key pathB;asc cols[quoteChunk],`.d,(`$"flag#")];
  hdb".hdb.reload[]";
  .assert.match[".hdb.status[] discovers missing quote partition";hdb"exec first err from .hdb.status[] where tab=`quote";`$"./2015.01.01/quote: The system cannot find the path specified."];
  .assert.match[".hdb.status[] does not discover missing trade partition as table list is based on the most recent par, i.e. 2015.01.02";hdb"exec first err from .hdb.status[] where tab=`trade";`];
  };
 
//----------------------------------------------------------------------------//
/
.test.report[][`testCasesFailed]
.test.report[][`assertsFailed]
