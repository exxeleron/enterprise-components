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

// Functional tests of the rdb/replay component
// See README.md for details

//----------------------------------------------------------------------------//
.testReplay.testSuite:"replay functional tests";

.testReplay.setUp:{
  .test.start[`t1.hdbMock];
  .test.mock[`hdb; .test.h[`t1.hdbMock]];
  };

.testReplay.tearDown:{
  .test.stop procNames:`t1.hdbMock;
  .test.clearProcDir `t1.hdbMock`t1.tick1`t1.tick2`t1.tickLF;
  };

//----------------------------------------------------------------------------//
.testReplay.genFxRates:{[cnt;process]
  data:(`time$til cnt; cnt#`aaa`bbb;`float$til cnt;til cnt);
  path:`$string[.cr.getCfgField[process;`group;`dataPath]],"/",string[process],string[.z.d];
  path set ();
  h:hopen path;
  h enlist (`jUpd;`fxRates;data);
  hclose h;
  };

.testReplay.genQuote:{[cnt;process]
  data:(`time$til cnt; cnt#`aaa`bbb;`float$til cnt;til cnt;`float$til cnt;til cnt;cnt?("flagA";"flagB"));
  path:`$string[.cr.getCfgField[process;`group;`dataPath]],"/",string[process],string[.z.d];
  path set ();
  h:hopen path;
  h enlist (`jUpd;`quote;data);
  hclose h;
  };

.testReplay.genUniverse:{[cnt;process]
  data:(`time$til cnt;cnt#`aaa`bbb;cnt?`underA`underB);
  path:`$string[.cr.getCfgField[process;`group;`dataPath]],"/universe/",string[.z.d],".universe";
  path set ();
  h:hopen path;
  h enlist (`.tickLF.jUpd;`universe;data);
  hclose h;
  };

//----------------------------------------------------------------------------//
//                      startup rdb state                                     //
//----------------------------------------------------------------------------//
.testReplay.test.scenario1_recover_data_from_tickHF_tickLF_and_discard_non_tick_processes:{[]
  .testReplay.genQuote[10;`t1.tick1];
  .testReplay.genQuote[10;`t1.tick2];
  .testReplay.genUniverse[10;`t1.tickLF];
  system "yak start t1.replay -a \"-date ",string[.z.d], " -rdb t1.rdb1\"";
  .hnd.hopen[`t1.replay;100i;`eager];
  .test.mock[`replay; .test.h[`t1.replay]];
  .os.sleep[1000];
  logs:system "yak log t1.replay";
  .assert.match["two warnings that tables from non tick process will be excluded from data replay";
    count "WARN" in/:  " "vs/:logs where logs like "*quoteMrvs*";
    2];
  .assert.match["errors not occur during data recover";any logs like "ERROR*";0b];
  .assert.match["run before eod callback loaded from custom rdb library";replay[".mock.trace`$\".rdb.plug.beforeEod[`beforeEod]\""]`args;enlist .z.d];
  .assert.match["store tables on disk";key `$string[.cr.getCfgField[`t1.hdbMock;`group;`dataPath]],"/",string .z.d;`quote`universe];
  .assert.match["tickLF is successfully stored and available in hdb ";hdb"count select from universe where date=.z.d";10];
  .assert.match["tickHF is successfully stored and available in hdb ";hdb"count select from quote where date=.z.d";10];
  system "yak stop t1.replay";
  };

.testReplay.test.scenario2_recover_data_from_tickHF_tickLF_that_are_configured_in_different_order:{[]
  .testReplay.genFxRates[10;`t1.tick2];
  .testReplay.genQuote[10;`t1.tick1];
  .testReplay.genUniverse[10;`t1.tickLF];
  system "yak start t1.replay -a \"-date ",string[.z.d], " -rdb t1.rdb2\"";
  .hnd.hopen[`t1.replay;100i;`eager];
  .test.mock[`replay; .test.h[`t1.replay]];
  .os.sleep[1000];
  logs:system "yak log t1.replay";
  .assert.match["errors not occur during data recover";any logs like "ERROR*";0b];
  system "yak stop t1.replay";
  .assert.match["store tables on disk";key `$string[.cr.getCfgField[`t1.hdbMock;`group;`dataPath]],"/",string .z.d;`fxRates`universe];
  .assert.match["tickLF table is successfully stored and available in hdb ";10; hdb"count select from universe where date=.z.d"];
  .assert.match["tickHF is successfully stored and available in hdb ";10; hdb"count select from fxRates where date=.z.d"];
  };
   
//----------------------------------------------------------------------------//



