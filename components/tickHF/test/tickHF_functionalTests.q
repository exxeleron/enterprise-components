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

// Functional tests of the tickHF component
// See README.md for details

.testTickHF.testSuite:"tickHF functional tests";

.testTickHF.setUp:{
  };

.testTickHF.tearDown:{
  .test.stop `t0.tickHF`t1.tickHF`t0.rdb`t1.rdb;
  .test.clearProcDir `t0.tickHF`t1.tickHF`t0.rdb`t1.rdb;
  };

//----------------------------------------------------------------------------//
.testTickHF.genQuote:{[cnt]
  ([]time:`time$til cnt; sym:cnt#`aaa`bbb;bid:`float$til cnt; bidSize:til cnt;ask:`float$til cnt; askSize:til cnt; flag:cnt?("flagA";"flagB"))
  };

//----------------------------------------------------------------------------//
//                               test tickHF                                  //
//----------------------------------------------------------------------------//
.testTickHF.test.tickHF_start_with_ok_journal:{[]
  // insert data to journal
  data:.testTickHF.genQuote 5;
  jrn:.Q.dd[.cr.getCfgField[`t0.tickHF;`group;`dataPath];`$"t0.tickHF",string[.z.d]];
  .[jrn;();:;()];
  h:hopen jrn;
  h enlist (`jUpd;`quote;value flip data);
  // run tick
  .test.start[`t0.tickHF];
  // sub from rdb
  .test.start[`t0.rdb];
  .assert.match["rdb contains loaded quote table";rdb"select from quote"; `date`time xasc tradeChunk,tradeChunk];
  };

.testTickHF.test.tickHF_start_with_bad_journal_abort:{[]
  
  };

.testTickHF.test.tickHF_start_with_bad_journal_archive:{[]
  
  };

.testTickHF.test.tickHF_start_with_bad_journal_truncate:{[]
  
  };

.testTickHF.test.tickHF_late_ticks_start_with_ok_journal:{[]
  
  };

.testTickHF.test.tickHF_late_ticks_start_with_bad_journal_abort:{[]
  
  };

.testTickHF.test.tickHF_late_ticks_start_with_bad_journal_archive:{[]
  
  };

.testTickHF.test.tickHF_late_ticks_start_with_bad_journal_truncate:{[]
  
  };
