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

// qtest runner

//Executing tests (assuming ec is deployed in the bin direcotory):
// - prepare env on linux:
//   KdbSystemDir> source bin/ec/components/hdbWriter/test/etc/env.sh
// - prepare env on windows:
//   KdbSystemDir> bin\ec\components\hdbWriter\test\etc\env.bat
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
.sl.init[`qtestRunner];
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/os"];
.sl.lib["qtest"];
.cr.loadCfg[`THIS];

//----------------------------------------------------------------------------//
.test.trace:enlist (::);

//----------------------------------------------------------------------------//
.qtest.runAll:{[testNamespaces]
   rep:.test.run each testNamespaces;
  .test.p.printErrors each exec testCase from .test.res where result<>`SUCCESS;

  //JUnit export
  if[not `: ~ .test.cfg.JUnitExportPath;
    .log.info[`qtest] "Exporting report in JUnit-xml format to file: ", string[JUnitExport];
    hsym[JUnitExport] 0: "\n" vs .test.toXml .test.res;
    ];

  .test.cfg.exportFile set .test.report[];

  if[.test.cfg.quitAfterRun;
    exit count rep[`testCasesFailed]
    ];
  };

.qtest.loadTestFiles:{[files]
  {system"l ",1_string x} each files;
  };

//----------------------------------------------------------------------------//
//                         remote assertions                                  //
//----------------------------------------------------------------------------//
/F/ Assertion fails if executed expression throws a signal matching to expectedSig
/P/ msg:STRING - assert description
/P/ serverName:SYMBOL - name of the remote server
/P/ expression:LIST
/P/ expectedSig:SYMBOL OR STRING - expected signal content
.assert.remoteFail:{[msg;serverName;expression;expectedSig]
  actual:.test.p.fail[serverName]expression;
  res:(first[actual]~`SIGNAL) and (last[actual] ~ $[10h=type expectedSig;`$expectedSig;expectedSig]);
  :.assert.p.insert[`$msg;`REMOTE_SIGNAL;last res;`;`SIGNAL,expectedSig;actual];
  };
  
//----------------------------------------------------------------------------//
/E/ .assert.remoteWaitUntilTrue["wait untill hdb is true";`t.hdb;"0b";10;10000]
.assert.remoteWaitUntilTrue:{[msg;serverName;expression;checkPeriodMs;maxWaitMs]
  firstTry:.z.t;  iter:0;  info:`;
  while[(info~`) and (not 1b ~ res:.test.p.fail[serverName;expression]);
    iter+:1;
    if[`SIGNAL~first res; 
      info:`$"signal <'",string[last res],"> on #",string[iter]," executions (",string[`int$(.z.t-firstTry)%1000]," sec) of expression <",.Q.s1[expression],"> on remote process ",string[serverName];
      ];
    if[maxWaitMs<waitTime:.z.t-firstTry;
      info:`$"timeout after ",string[iter]," executions (",string[`int$waitTime%1000]," sec) of expression <",.Q.s1[expression],"> on remote process ",string[serverName];
      ];
    .os.sleep checkPeriodMs;
    ];
  :.assert.p.insert[`$msg;`REMOTE_WAIT_UNTIL_TRUE;1b ~ res;info;1b;res];
  };

//----------------------------------------------------------------------------//
/E/ .assert.remoteWaitUntilEqual["wait untill 2+2=4";`t.rdb;(+;2;2);4;10;10000]
.assert.remoteWaitUntilEqual:{[msg;serverName;expression;expected;checkPeriodMs;maxWaitMs]
  firstTry:.z.t;  iter:0;  info:`;
  while[(info~`) and (not match:expected ~ res:.test.p.fail[serverName;expression]);
    iter+:1;
    if[`SIGNAL~first res; 
      info:`$"signal <'",string[last res],"> on #",string[iter]," executions (",string[`int$(.z.t-firstTry)%1000]," sec) of expression <",.Q.s1[expression],"> on remote process ",string[serverName];
      ];
    if[maxWaitMs<waitTime:.z.t-firstTry;
      info:`$"timeout after ",string[iter]," executions (",string[`int$waitTime%1000]," sec) of expression <",.Q.s1[expression],"> on remote process ",string[serverName];
      ];
    .os.sleep checkPeriodMs;
    ];
  :.assert.p.insert[`$msg;`REMOTE_WAIT_UNTIL_EQUAL;match;info;expected;res];
  };

//----------------------------------------------------------------------------//
//                              remote execution                              //
//----------------------------------------------------------------------------//
.test.start:{[proc]
  procNames:(),$[99h = type proc; key proc;proc];
  startCmd:.test.cfg.processManager," start ";
  system startCmd," " sv string procNames;
  .hnd.hopen[proc;5000i;`eager];
  };


//----------------------------------------------------------------------------//
//procNames:`t.run`t.mon
.test.stop:{[procNames]
  procNames:(),procNames;
  stopCmd:.test.cfg.processManager," stop ";
  system stopCmd," " sv string procNames;
  .hnd.hclose[procNames];
  };  

//----------------------------------------------------------------------------//
.test.clearProcDir:{[procNames]
  {.os.rmdir 1_string .cr.getCfgField[x;`group;`dataPath]} each procNames;
  };
  
//----------------------------------------------------------------------------//
.test.h:{[componentId;tree]
//  `componentId`tree set' (componentId;tree);
  ptree:$[10h=type tree;parse tree;tree];
  .test.lastSig:(::);
  res:.[{.hnd.h[x]y};(componentId;tree);{.test.lastSig:x;`$x}];
  if[-11h=type first ptree;.test.lastFunc:distinct .test.lastFunc,first ptree];
  .test.trace,:enlist ptree;
  if[not .test.lastSig~(::);'.test.lastSig];
  res
  };

//----------------------------------------------------------------------------//
.test.p.fail:{[componentId;tree]
//  `componentId`tree set' (componentId;tree);
  ptree:$[10h=type tree;parse tree;tree];
  .test.lastSig:(::);
  res:.[{.hnd.h[x]y};(componentId;tree);{.test.lastSig:x;(`SIGNAL;`$x)}];
  if[-11h=type first ptree;.test.lastFunc:distinct .test.lastFunc,first ptree];
  .test.trace,:enlist ptree;
  res
  };

  
//----------------------------------------------------------------------------//
//                       printing tests                                       //
//----------------------------------------------------------------------------//
//.test.printTest[`.testJSON;`$"start stop selected processes"]
//testSuite:`.testJSON;
//testCase:`$"start stop selected processes"
//TODO: use .test.report[][`testCasesFailed]
//.test.printTest testCase:`.testJSON.test.memHistoryRequest
.test.printTest:{[tCase]
  testSuite:` sv 2#` vs tCase;
  testCaseRes:select from .test.report[][`testCases] where testCase=tCase;
  failedAsserts:select assert, assertType, failureInfo, expected, actual from .test.report[][`assertsFailed] where testCase=tCase;
  str:();
  str,:"\n//======== ",string[tCase]," ========//\n";
  str,:"\n" sv .Q.s2 last testCaseRes;
  str,: raze "\n//--------- failed assertion:\n",/:{"\n" sv .Q.s2 x}each failedAsserts;
  str,:"\n//----------------------- setUp ------------------------//\n";
  str,:string[testSuite],".setUp:",string[value[testSuite]`setUp],";";
  str,:"\n//----------------------- testCase ---------------------//\n";
  str,:string[tCase],":",string[value tCase],";";
  str,:"\n//----------------------- tearDown ---------------------//\n";
  str,:string[testSuite],".tearDown:",string[value[testSuite]`tearDown],";";
  str,:"\n//----------------------- runOneTest -------------------//\n";
  str,:".test.runOneTest`",string[tCase],"\n";
  `$str
  };

//----------------------------------------------------------------------------//
//                       helper functions for debugging                       //
//----------------------------------------------------------------------------//
// set remotely function args
//tree:`.hdbl.insert
//h:.hnd.h[`test.hdbLoader]
.test.hp:{[componentId;tree]
  if[10h=type tree;tree:parse tree];
  func:.hnd.h[componentId][first tree];
  if[100h=type func;
    .hnd.h[componentId]({x set' y};value[func][1];1 _ tree);
    ];
  };

//----------------------------------------------------------------------------//
.test.p.printErrors:{[tCase]
  tc:exec from .test.res where testCase=tCase;
  if[`SUCCESS<>tc`result; .log.error[`test] "------------> testCase ", string[tCase], " FAILED, more info via: \".test.printTest`", string[tCase],"\""];
  if[`<>tc`setUpErr;.log.error[`test] `testCase`setUpErr!(tCase;tc`setUpErr)];
  if[`<>tc`testCaseErr;.log.error[`test] `testCase`testCaseErr!(tCase;tc`testCaseErr)];
  if[tc`assertFailed;
    ta:select testCase, assert, assertType, failureInfo, expected, actual from .test.asserts where testCase=tCase, result=`FAILURE;
	.log.error[`test] each ta;
    ];
  if[`<>tc`tearDownErr;.log.error[`test] `testCase`tearDownErr!(tCase;tc`tearDownErr)];
  };

/==============================================================================/
.sl.main:{[flags]
  .test.cfg.zx:.Q.opt[.z.x];

  .test.cfg.testFiles:.cr.getCfgField[`THIS;`group;`testFiles];
  .test.cfg.testNamespaces:.cr.getCfgField[`THIS;`group;`testNamespaces];

  .test.cfg.JUnitExportPath:.cr.getCfgField[`THIS;`group;`JUnitExportPath];
  if[`JUnitExportPath in key .test.cfg.zx;.test.cfg.JUnitExportPath:.test.cfg.zx[`JUnitExportPath]];

  .test.cfg.quitAfterRun:.cr.getCfgField[`THIS;`group;`quitAfterRun];
  if[`quitAfterRun in key .test.cfg.zx;.test.cfg.quitAfterRun:1b];
  
  .test.cfg.exportFile:.cr.getCfgField[`THIS;`group;`exportFile];
  
  .test.cfg.processManager:.cr.getCfgField[`THIS;`group;`processManager];
  
  .test.p.logInfo:.log.info[`qtest];
  .test.p.logError:.log.error[`qtest];
  .test.appname:.sl.appname;
  
  .sl.libCmd[];

  .qtest.loadTestFiles .test.cfg.testFiles;

  if[`testCase in key .test.cfg.zx;
    testCase:.test.cfg.zx[`testCase];
    :.test.runOneTest testCase;
    ];

  :.qtest.runAll[`$.test.cfg.testNamespaces];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`qtest;`.sl.main;`];

