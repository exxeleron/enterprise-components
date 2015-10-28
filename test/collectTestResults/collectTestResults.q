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

/S/ Collect qtest result from multiple qtestRunner instances

//----------------------------------------------------------------------------//
//                                libraries                                   //
//----------------------------------------------------------------------------//
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`qtestRunner];
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/os"];
.cr.loadCfg[`THIS];

/------------------------------------------------------------------------------/
.test.collect:{[]
  testDirs:.Q.dd[.test.cfg.rootTestDataDir]each  key[.test.cfg.rootTestDataDir];
  resultFiles:raze {.Q.dd[x] each `$(f where (f:string key x) like (string[.test.cfg.testRunner]), "*"),\: "/",string[.test.cfg.exportFile]} each testDirs;
  .test.totalResult:get each resultFiles;

  suiteFail:exec distinct testSuite from .test.report[][`testCases] where not result=`SUCCESS;
  suiteTotal:exec distinct testSuite from .test.report[][`testCases];
  tcFail:count .test.report[]`testCasesFailed;
  tcTotal:count .test.report[]`testCases;
  fail:0<>count suiteFail;

  .test.p.printErrors each .test.report[]`testCasesFailed;

  msg:"==========================> Test Execution ",$[fail;"FAILED";"COMPLETED"]," with:";
  msg,:" Test suites: ",string[count[suiteTotal]-count[suiteFail]],"/",string[count suiteTotal];
  msg,: ", Test cases: ",string[tcTotal-tcFail],"/",string[tcTotal];
  $[fail;.log.error[`test];.log.info[`test]] msg;
  };

//----------------------------------------------------------------------------//
//tc:first .test.report[]`testCases
.test.p.printErrors:{[tc]
  if[`SUCCESS<>tc`result; .log.error[`test] "------------> testCase ", string[tc`testCase], " FAILED, more info via: \".test.printTest`", string[tc`testCase],"\""];
  if[`<>tc`setUpErr;.log.error[`test] `testCase`setUpErr!(tc`testCase;tc`setUpErr)];
  if[`<>tc`testCaseErr;.log.error[`test] `testCase`testCaseErr!(tc`testCase;tc`testCaseErr)];
  if[tc`assertFailed;
    ta:select testCase, assert, assertType, failureInfo, expected, actual from .test.report[][`asserts] where testCase=tc`testCase, result=`FAILURE;
	.log.error[`test] each ta;
    ];
  if[`<>tc`tearDownErr;.log.error[`test] `testCase`tearDownErr!(tc`testCase;tc`tearDownErr)];
  };

/------------------------------------------------------------------------------/
.test.report:{[]
  report:()!();
  report[`testCases]:raze .test.totalResult`testCases;
  report[`testCasesFailed]:raze .test.totalResult`testCasesFailed;
  report[`asserts]:raze .test.totalResult`asserts;
  report[`assertsFailed]:raze .test.totalResult`assertsFailed;
  report[`interfaceCoverage]:raze .test.totalResult`interfaceCoverage;
  report
  };

/==============================================================================/
.sl.main:{[flags]
  .test.cfg.rootTestDataDir:.cr.getCfgField[`THIS;`group;`cfg.rootTestDataDir];
  .test.cfg.testRunner:.cr.getCfgField[`THIS;`group;`cfg.testRunner];
  .test.cfg.exportFile:.cr.getCfgField[`THIS;`group;`cfg.exportFile];
  
  .test.collect[];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`qtest;`.sl.main;`];
/
.test.report[]
