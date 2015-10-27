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

/A/ DEVnet: Piotr-Szawlis
/V/ 3.0


//----------------------------------------------------------------------------//


.tutorial.listDirectory:{[path]
  key `$":",path
  };

.tutorial.listProcesses:{[serice]
  ("SSSS"; enlist",") 0: system "yak -d, . "
  };

//common setup function that creates root directory for the system
//links etc folder to directory of the lesson defined in lessonNumber
//mocks user and password for the connection with components
.tutorial.p.setUp:{[lessonNumber;user;pass;d]
  .test.mock[`lesson;  raze "Lesson",lessonNumber];
  `oldSysPath`oldYakOpts`oldYakPath`oldEtcPath .test.mock' getenv `EC_SYS_PATH`YAK_OPTS`YAK_PATH`EC_ETC_PATH;
  .test.mock[`newSysPath; oldSysPath, "/bin/ec/test/tutorialTest/rootPath"];
  .os.mkdir newSysPath;
  .os.mklink[oldSysPath, "/bin";newBinPath:newSysPath, "/bin"]
  .test.mock[`newEtcPath; newSysPath,  "/etc"];
  `EC_SYS_PATH setenv newSysPath;
  newYakOpts1: "-c ", newEtcPath, "/system.cfg";
  newYakOpts2: "-s ", newSysPath, "/data/yak/yak.status";
  newYakOpts3: "-l ", newSysPath, "/log/yak/yak.log";
  newYakOpts: newYakOpts1, " ", newYakOpts2, " ", newYakOpts3;
  `YAK_OPTS setenv newYakOpts;
  newYakPath: newBinPath, "/yak";
  `YAK_PATH setenv newYakPath;
  `EC_ETC_PATH setenv newEtcPath;
  .os.mklink[oldSysPath, "/bin/ec/tutorial/", lesson, "/etc";newEtcPath];
  if[`admin.refreshUFiles  in (`uid xcol .tutorial.listProcesses[])`uid; system "yak console admin.refreshUFiles"];
  .test.mock[`user;  $[user ~ "";":";user]];
  .test.mock[`pass;  $[pass ~ "";":";pass]];
  };

//common tear down function
//removes rootPath directory and stop all components running
.tutorial.p.tearDown:{
  .test.stop exec server from .hnd.status where state = `open;
  .os.rmdir[newSysPath];
  `EC_SYS_PATH`YAK_OPTS`YAK_PATH`EC_ETC_PATH setenv' (oldSysPath;oldYakOpts;oldYakPath;oldEtcPath);
  };  

.testLesson01.testSuite:"Lesson1 tests";   
.testLesson01.setUp:.tutorial.p.setUp["01";"";""];
.testLesson01.tearDown:.tutorial.p.tearDown;

.testLesson01.test.testLesson1:{
  connSymbols: `$(":localhost:",/: (string 17009 +til 3)) ,\: ":",user,":", pass;
  .test.start `core.gen`core.tick`core.rdb!connSymbols; 
  systemDir: .tutorial.listDirectory[getenv `EC_SYS_PATH];
  .assert.containsAll["bin and etc directories are created";systemDir;`bin`etc];
  .assert.containsAll["data and log directories are created";systemDir;`data`log];
  runningProcesses:exec uid from (`uid xcol .tutorial.listProcesses[]) where status = `RUNNING;
  .assert.containsAll["all processes running";runningProcesses;`core.gen`core.tick`core.gen];
  logDir:.tutorial.listDirectory[(getenv `EC_SYS_PATH), "/log"];
  .assert.containsAll["log directories created";logDir;`core.gen`core.tick`core.gen];
  dataDir: .tutorial.listDirectory[(getenv `EC_SYS_PATH), "/data"];
  .assert.containsAll["data directories created";dataDir;`core.gen`core.tick`core.gen];
  .assert.moreEq["log core.rdb";1;count  system "yak log core.rdb"];
  .assert.moreEq["log core.tick";1;count  system "yak log core.tick"];
  .assert.moreEq["log core.gen";1;count  system "yak log core.gen"];
  dataTickDir: .tutorial.listDirectory[(getenv `EC_SYS_PATH), "/data/core.tick"];
  .assert.true["create the journal file"; (string first dataTickDir) like "core.tick*"];
  .assert.remoteWaitUntilTrue["nonempty trade table on rdb";`core.rdb;"0 < count trade";100;1000];  
  };

.testLesson02:.testLesson01;
.testLesson02.testSuite:"Lesson2 tests";  
.testLesson02.setUp:.tutorial.p.setUp["02";"";""];

.testLesson02.test.testLesson2:{
  connSymbols: `$(":localhost:",/: (string 17009 +til 3)) ,\: ":", user,":", pass;
  .test.start `core.gen`core.tick`core.rdb!connSymbols; 
   .test.mock[`hrdb; .test.h[`core.rdb]];
  tradeTable:hrdb"tables[]";
  .assert.match["two tables exist";hrdb"tables[]"; `quote`trade];
  subStatus: ([] tab: `quote`trade; name: `quote`trade; src: 2#`core.tick; subProtocol: 2#`PROTOCOL_TICKHF; srcConn: 2#`open);
  .assert.match["sub status table model";delete rowsCnt from hrdb ".sub.status[]"; subStatus];
  .assert.moreEq["trade table not empty";1;hrdb "count trade"];
  .assert.moreEq["quote table not empty";1;hrdb "count quote"];
  lastTradeRows:hrdb"-3#trade";
  .assert.remoteWaitUntilTrue["trade table updating";`core.rdb;({not x ~ -3#trade};tradeTable);100;1000]; 
  };
  
.testLesson03:.testLesson02;
.testLesson03.testSuite:"Lesson3 tests";  
.testLesson03.setUp:.tutorial.p.setUp["03";"";""];

.testLesson03.test.testLesson3:{
  connSymbols: `$(":localhost:",/: (string 17009 +til 4)) ,\: ":", user,":", pass;
  .test.start `core.gen`core.tick`core.rdb`core.hdb!connSymbols; 
  .test.mock[`htick; .test.h[`core.tick]];
  .test.mock[`hhdb; .test.h[`core.hdb]];
   htick ".u.end[.z.d]";
  .assert.remoteWaitUntilEqual["quote and trade table on hdb";`core.hdb;"tables[]";`quote`trade;100;1000]; 
  hdbStatus: ([] tab: `quote`trade; format: 2#`PARTITIONED; columns:(`date`sym`time`bid`bidSize`ask`askSize;`date`sym`time`price`size));
  .assert.match["hdb status table model";select tab, format, columns from hhdb ".hdb.status[]"; hdbStatus];
  .assert.moreEq["non empty trade table with current date on hdb";1;first (hhdb "select count i by date from quote").z.d];
  .assert.moreEq["non empty trade table with current date on hdb";1;first (hhdb "select count i by date from trade").z.d];
  logDir:.tutorial.listDirectory[(getenv `EC_SYS_PATH), "/log"];
  .assert.contains["hdb log directory created";logDir;`core.hdb];
  dataDir: .tutorial.listDirectory[(getenv `EC_SYS_PATH), "/data"];
  .assert.contains["hdb directory created";logDir;`core.hdb];
  };

.testLesson04:.testLesson03;
.testLesson04.testSuite:"Lesson4 tests";  
.testLesson04.setUp:.tutorial.p.setUp["04";"";""];

.testLesson04.test.testLesson4:{
  connSymbols: `$(":localhost:",/: (string 17009 + ((til 4),41))) ,\: ":",user,":", pass;
  .test.start `core.gen`core.tick`core.rdb`core.hdb`access.ap!connSymbols; 
  .test.mock[`hacc; .test.h[`access.ap]];
  .test.mock[`htick; .test.h[`core.tick]];
  htick".u.end[.z.d]";
  .assert.matchModel["table returned by .example.tradeStats";hacc ".example.tradeStats[]";([hh:`int$()] cnt: `long$())];
  emptyTaQ:([] time:`time$(); sym:`symbol$(); price:`float$(); size:`long$(); bid:`float$(); bidSize:`long$(); ask:`float$(); askSize:`long$());
  .assert.matchModel["table returned by .example.tradeAndQuote";hacc ".example.tradeAndQuote[]";emptyTaQ];
  .assert.matchModel["table returned by .example.currentPrices";hacc ".example.currentPrices[]";([sym:`symbol$()] price: `float$())];
  .assert.matchModel["table returned by .example.vwap";hacc ".example.vwap[]";([sym:`symbol$()] vwap: `float$())];
  .assert.matchModel["table returned by .example.functionalVwap";hacc ".example.functionalVwap[]";([sym:`symbol$()] vwap: `float$())];
  .assert.matchModel["table returned by .example.dailyVwap";hacc ".example.dailyVwap[]";([sym:`symbol$(); date:`date$()] vwap: `float$())];
  .assert.matchModel["table returned by .example.lastPrice10MinutesBar";hacc ".example.lastPrice10MinutesBar[]";([minute:`minute$()] price: `float$())];
  .assert.matchModel["table returned by .example.functionalLastPriceNMinutesBar";hacc ".example.functionalLastPriceNMinutesBar[30j; `instr0]";([sym: `symbol$();minute:`minute$()] price: `float$())];
  emptyBBO:delete price, size from emptyTaQ;
  .assert.matchModel["table returned by .example.bigBuyOrders";hacc ".example.bigBuyOrders[]";emptyBBO];
  emptyOHLC:([date:`date$(); sym:`symbol$(); time:`second$()] open:`float$(); high:`float$(); low:`float$(); close:`float$(); size:`long$(); vwap:`float$());
  .assert.matchModel["table returned by .example.ohlcVwap";hacc ".example.ohlcVwap[`instr1;.z.d; 08:00:00; 20:00:00; 600]";emptyOHLC];
  };

.testLesson05:.testLesson04;
.testLesson05.testSuite:"Lesson5 tests";  
.testLesson05.setUp:.tutorial.p.setUp["05";"tu";"0xbabbbbbdabbc"];

.testLesson05.test.testLesson5:{
  connSymbols: `$(":localhost:",/: (string 17009 + ((til 4),41))) ,\: ":",user,":", pass;
  .test.start `core.gen`core.tick`core.rdb`core.hdb`access.ap!connSymbols; 
  .hnd.hopen[enlist[`strict.demo]!enlist[`$"::17050:demo:0xaaaba3a1bbbdabbc"];100i;`eager];
  .test.mock[`hacc; .test.h[`access.ap]];
  .test.mock[`haccflex; .hnd.h[`strict.demo]]; 
  .assert.matchModel["table returned by .example.tradeStats";haccflex ".example.tradeStats[]";([hh:`int$()] cnt: `long$())];
  .assert.matchModel["table returned by .example.tradeStats";haccflex ".example.tradeStats[1+1]";([hh:`int$()] cnt: `long$())];
  .assert.matchModel["table returned by .example.tradeStats";haccflex ".example.tradeStats[{sum x}[1 1]]";([hh:`int$()] cnt: `long$())];
  .assert.remoteFail["table returned by .example.tradeStats";`strict.demo; ".example.tradeStats[{delete from .hnd.status}`]";"access denied"];
  hacc".hnd.hopen[enlist[`strict.demo]!enlist[`$\"::17011:demo:0xaaaba3a1bbbdabbc\"];100i;`eager]";
  .assert.match["connection opened on acces point";hacc".hnd.status[`strict.demo]`state";`open];
  .assert.matchModel["check connection on rdb"; hacc"key .hnd.h[`strict.demo] (`.hnd.status;::)";flip (enlist `server)!enlist ``core.hdb`core.tick];
  .assert.remoteFail["not allowed to pass from .hnd namespaces";`access.ap;".hnd.h[`strict.demo] (key;`.hnd.status)";`$"unsupported query type for check level: STRICT, query: (!:;`.hnd.status)"];
  .assert.remoteFail["not allowed to pass from .hnd namespaces";`access.ap;".hnd.h[`strict.demo] \"1+1\"";`$"unsupported query type for check level: STRICT, query: \"1+1\""];
  .hnd.hclose[`strict.demo];
  };

