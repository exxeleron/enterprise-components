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

/A/ DEVnet: Joanna Wdowiak
/V/ 3.0

// Functional tests of the rdb component
// See README.md for details

//----------------------------------------------------------------------------//
.testRdb.testSuite:"rdb functional tests";

.testRdb.setUp:{
  .test.start[`t0.tickMock`t0.rdb`t0.hdbMock];
  .test.mock[`tick; .test.h[`t0.tickMock]];
  .test.mock[`rdb; .test.h[`t0.rdb]];
  .test.mock[`hdb; .test.h[`t0.hdbMock]];
  };

.testRdb.tearDown:{
  .test.stop procNames:`t0.tickMock`t0.rdb`t0.hdbMock;
  .test.clearProcDir `t0.tickMock`t0.rdb`t0.hdbMock;
  };

//----------------------------------------------------------------------------//
.testRdb.genTrade:{[cnt]
  ([]time:`time$til cnt; sym:cnt#`aaa`bbb;price:`float$til cnt; size:til cnt)
  };

.testRdb.genQuote:{[cnt]
  ([] time:`time$til cnt; sym:cnt#`aaa`bbb;bid:`float$til cnt; bidSize:til cnt;ask:`float$til cnt; askSize:til cnt; flag:cnt?("flagA";"flagB"))
  };

//----------------------------------------------------------------------------//
//                      startup rdb state                                     //
//----------------------------------------------------------------------------//
.testRdb.test.rdb_subscription_while_tick_is_running:{[]
  .assert.match["subscription status is changed to open";rdb".sub.status[]`srcConn";`open`open];
  .assert.match["subscribed tables appear in global namespace in rdb";rdb"tables[]";`quote`trade];
  .assert.match["data model has `g attribute on sym column";rdb"attr each (trade;quote)@\\:`sym";`g`g];
  // generate data that will be pushed through mock tick
  tick(`.tickm.upd;`trade;.testRdb.genTrade[5]);
  .assert.remoteWaitUntilTrue["store received data in memory";`t0.rdb;"5=count select from trade";10;2000];
  .assert.match["data model has `g attribute on sym column";rdb"attr each (trade;quote)@\\:`sym";`g`g];
  };

.testRdb.test.rdb_re_subscription:{[]
  tick(`.tickm.upd;`trade;.testRdb.genTrade[2]);
   // insert data
   //stop tick
  .test.stop `t0.tickMock;
   // check sub.status
  .assert.match["subscription status is changed to lost";rdb".sub.status[]`srcConn";`lost`lost]; 
  .assert.contains["turn on reconnection on port open callback";raze value flip rdb"key .cb.status[]";`.hnd.po.t0_tickMock]; 
  // run tick
  .test.start[`t0.tickMock];
  .assert.remoteWaitUntilTrue["rdb is subscribed to tick";`t0.tickMock;"0<count .tickm.w";10;2000];
  .assert.match["subscription status is changed to open";rdb".sub.status[]`srcConn";`open`open];
  .assert.match["store received data in memory";rdb"count select from trade";2];
  .assert.match["data model has `g attribute on sym column";rdb"attr each (trade;quote)@\\:`sym";`g`g];
  // insert new data
  tick(`.tickm.upd;`trade;.testRdb.genTrade[5]);
  .assert.remoteWaitUntilTrue["store received data in memory";`t0.rdb;"count[select from trade]=7";10;2000];
  };

.testRdb.test.rdb_performs_eod:{[]
  tick(`.tickm.upd;`trade;.testRdb.genTrade[10]);
  tick(`.tickm.upd;`quote;.testRdb.genQuote[10]);
  tick(`.tickm.end;.z.d);
  .assert.match["switch to next day";rdb".rdb.date";.z.d+1];
  .assert.contains["perform before eod callback";rdb".mock.trace[`$\".rdb.plug.beforeEod[`beforeEod]\"][`args]";.z.d]; 
  .assert.contains["perform afterEod eod callback";rdb".mock.trace[`$\".rdb.plug.afterEod[`afterEod]\"][`args]";.z.d];
  .cr.loadCfg[`t0.hdbMock];
  hdbPath:.cr.getCfgField[`t0.hdbMock;`group;`cfg.hdbPath];
  .assert.match["store data on the disk";key hdbPath;(`$string .z.d;`sym)];
  .assert.match["realod hdb";hdb".mock.trace[`.hdb.reload][`w]>0";enlist 1b];
  .assert.match["quote table available on hdb";hdb"count select from quote where date=last date";10];
  .assert.match["trade table available on hdb";hdb"count select from trade where date=last date";10];
  .assert.match["clear configured tables from memory";rdb"count quote";0];
  .assert.match["leave configured tables in memory";rdb"count trade";10];
  };
   
//----------------------------------------------------------------------------//
