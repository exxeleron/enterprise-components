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

/S/ Test framework

/S/ Usage:
/S/ Example of testSuite is located in ec/libraries/qtest/example
/S/ See README.md for qtest usage details

//----------------------------------------------------------------------------//
//                             test results                                   //
//----------------------------------------------------------------------------//
.test.res:([]testSuite:`symbol$(); testCase:`symbol$();result:`symbol$();assertRun:`long$(); assertFailed:`long$(); setUpErr:`symbol$();testCaseErr:`symbol$();tearDownErr:`symbol$();startTs:`timestamp$(); duration:`timespan$(); functions:());

.test.appname:.z.f;

//----------------------------------------------------------------------------//
//                             assertions                                     //
//----------------------------------------------------------------------------//
.test.asserts:([]testSuite:`symbol$(); testCase:`symbol$(); assert:`symbol$(); assertType:`symbol$();result:`symbol$();failureInfo:`symbol$();expected:();actual:());
//initial insert to keep last two columns of generic type
`.test.asserts insert (`;`;`;`;`;`;(::);(::));

//----------------------------------------------------------------------------//
//.assert.match["12 is 12";12;"12"] 
//.assert.match["12 is 12";12;12.f] 
//.assert.match["12 is 12";12;12] 
//.assert.match["vector is correct";1 2 3;1 2] 
.assert.match:{[msg;actual;expected] 
  res:expected~actual;
  info:`;
  //get more detailed info about the differences
  if[not res;
    info:$[not type[actual]~type[expected];
      `$"expected type ", string[type expected], "h instead of ", string[type actual], "h";
      not count[actual]~count[expected];
      `$"expected #", string[count expected], " elements instead of #", string[count actual];
      type[actual]=98h;
      $[`~modelErr:.assert.p.matchModel[actual;expected];`$"data model matching, content different";modelErr];
      `];
    ];
  :.assert.p.insert[`$msg;`MATCH;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
/F/ Assertion fails if executed expression throws a signal matching to expectedSig
/P/ msg:STRING - assert description
/P/ expression:LIST
/P/ expectedSig:SYMBOL OR STRING - signal or 'like-stle' pattern that should match the signal
.assert.fail:{[msg;expression;expectedSig]
  actual:@[value;expression;{(`ASSERTION_SIGNAL_MARKER;x)}];
  if[res:first[actual]~`ASSERTION_SIGNAL_MARKER;
    res:last[actual] like $[10h=type expectedSig;expectedSig;string expectedSig];
	];
  :.assert.p.insert[`$msg;`FAIL;res;`;expectedSig;actual];
  };

//----------------------------------------------------------------------------//
.assert.true:{[msg;actual]
  res:1b~actual;
  info:$[-1h=type actual;`;`$"expected type -1h instead of ", string[type actual],"h"];
  :.assert.p.insert[`$msg;`TRUE;res;info;1b;actual];
  };

//----------------------------------------------------------------------------//
.assert.false:{[msg;actual]
  res:0b~actual;
  info:$[-1h=type actual;`;`$"expected type -1h instead of ", string[type actual],"h"];
  :.assert.p.insert[`$msg;`FALSE;res;info;0b;actual];
  };

//----------------------------------------------------------------------------//
.assert.type:{[msg;actual;expected]
  res:expected=type actual;
  info:$[-5h=type expected;`;`$"expected type must be specified as 'short type identifier' (type -5h), received type ", string[type expected],"h"];
  :.assert.p.insert[`$msg;`TYPE;res;info;expected;type actual];
  };

//----------------------------------------------------------------------------//
//expected:(`12;`23;`a;1);actual:1
.assert.contains:{[msg;actual;expected]
  areTypesPossible:(0h=type expected) | (abs[type actual]=abs[type expected]);
  if[not areTypesPossible;
    res:0b;  //no need to perform test and risk dirty type error
    info:`$"expected type ", string[type expected], "h instead of ", string[type actual], "h";
    ];
  if[areTypesPossible;
    res:expected in actual;
    info:`;
    ];
  :.assert.p.insert[`$msg;`CONTAINS;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
//expected:(`12;`23;`a;1);actual:1 2 3
.assert.containsAll:{[msg;actual;expected]
  areTypesPossible:(0h=type expected) | (abs[type actual]=abs[type expected]);
  if[not areTypesPossible;
    res:0b;  //no need to perform test and risk dirty type error
    info:`$"expected type ", string[type expected], "h instead of ", string[type actual], "h";
    ];
  if[areTypesPossible;
    res:all expected in actual;
    info:`;
    ];
  :.assert.p.insert[`$msg;`CONTAINS;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
//.assert.in["2 in range";1;1]
//.assert.in["2 in range";1;1 2]
//.assert.in["2 in range";"2";1 2]
.assert.in:{[msg;actual;expected]
  areTypesPossible:(0h=type expected) | (abs[type actual]=abs[type expected]);
  if[not areTypesPossible;
    res:0b;  //no need to perform test and risk dirty type error
    info:`$"expected type ", string[type expected], "h instead of ", string[type actual], "h";
    ];
  if[areTypesPossible;
    res:actual in expected;
    info:`;
    ];
  :.assert.p.insert[`$msg;`IN;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
//.assert.within["2 in range";1;1 5]
.assert.within:{[msg;actual;expected]
  areTypesPossible:(0h=type expected) | (abs[type actual]=abs[type expected]);
  if[not areTypesPossible;
    res:0b;  //no need to perform test and risk dirty type error
    info:`$"expected type ", string[type expected], "h instead of ", string[type actual], "h";
    ];
  if[areTypesPossible;
    res:actual within expected;
    info:`;
    ];
  :.assert.p.insert[`$msg;`WITHIN;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
//.assert.allIn["2 in range";2;1]
//.assert.allIn["2 in range";1;1 2]
//.assert.allIn["2 in range";1 2 3 4;1 2 3]
.assert.allIn:{[msg;actual;expected]
  areTypesPossible:(0h=type expected) | (abs[type actual]=abs[type expected]);
  if[not areTypesPossible;
    res:0b;  //no need to perform test and risk dirty type error
    info:`$"expected type ", string[type expected], "h instead of ", string[type actual], "h";
    ];
  if[areTypesPossible;
    res:all parRes:((),actual) in\: expected;
    notMatching:where not parRes;
    info:$[count[notMatching];`$string[count notMatching], " out of ", string[count actual], " elements are unexpected: ",.Q.s1 ((),actual) notMatching;`];
    ];
  :.assert.p.insert[`$msg;`ALL_IN;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
//.assert.allWithin["1 in range";1;1 2]
//.assert.allWithin["0 out of range";0;1 2]
//.assert.allWithin["values are within range";10 11 12 13;11 12]
.assert.allWithin:{[msg;actual;expected]
  info:$[not (0h=type expected) | (abs[type actual]=abs[type expected]);
    `$"expected type ", string[type expected], "h instead of ", string[type actual], "h";
     2<>count[expected];
     `$"expected entry should be a list of 2 instead of ", string[count expected], " elements";
     `];
  if[info~`;
    res:all parRes:((),actual) within\: expected;
    notMatching:where not parRes;
    info:$[count[notMatching];`$string[count notMatching], " out of ", string[count actual], " elements are not within range: ",.Q.s1 ((),actual) notMatching;`];
    ];
  :.assert.p.insert[`$msg;`ALL_WITHIN;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
.assert.lessEq:{[msg;actual;expected]
  output:.[<=;(actual;expected);::];
  info:$[output~"type";`$"invalid types for <= operator:",string[type actual],"h and ",string[type expected],"h";
    -1h=type output;`;
    `$"operator <= signal:'",output];
  res:info~`;
  :.assert.p.insert[`$msg;`LESS_EQ;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
.assert.moreEq:{[msg;actual;expected]
  output:.[>=;(actual;expected);::];
  info:$[output~"type";`$"invalid types for >= operator:",string[type actual],"h and ",string[type expected],"h";
    -1h=type output;`;
    `$"operator >= signal:'",output];
  res:info~`;
  :.assert.p.insert[`$msg;`MORE_EQ;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
//actual:1!subTabs`sysLogStatus; expected:([]time:(); sym:(); logFatal:`float$(); logError:`float$(); logWarn:`float$())
//.assert.matchModel["test model";([]colA:1 2 3);([]colA:`long$())]
//.assert.matchModel["test model";([]colA:1 2 3);([]colA:`int$())]
//.assert.matchModel["test model";([]colA:1 2 3);([]colB:`long$())]
//.assert.matchModel["test model";([]colA:1 2 3);([]colA:`long$(); colB:`int$())]
//.assert.matchModel["test model";([]colA:1 2 3; colB:1 2 3);([]colA:`long$())]
//.assert.matchModel["test model";([]colA:(1 2;3 4));([]colA:())]
//.assert.matchModel["test model";([]colA:("aaa";"bb"));([]colA:())]
//.assert.matchModel["test model";([]colA:`aaa`bb);([]colA:`symbol$())]
//.assert.matchModel["test model";([]colA:string `aaa`bb);([]colA:`symbol$())]
.assert.matchModel:{[msg;actual;expected]
  info:`;
  if[not type[actual] in 98 99h;
	info:`$"[actual] must be a table (98h or 99h), not ", string[type actual], "h";
    ];
  if[not type[expected] in 98 99h;
	info:`$"[expected] must be a table (98h or 99h), not ", string[type info], "h";
    ];
  if[info~`;
    info:.assert.p.matchModel[actual;expected];
    ];
  res:info~`;
  :.assert.p.insert[`$msg;`MATCH_MODEL;res;info;expected;actual];
  };

.assert.p.matchModel:{[actual;expected]
  am:.Q.ty each flip 0!actual;
  em:.Q.ty each flip 0!expected;
  if[count nulls:where em=" "; em[nulls]:am[nulls]];
  cnt:min[count[am],count[em]];
  if[not null id:first where not (cnt#key[am])=cnt#key[em];
    :`$"column ",string[id]," ",string[key[am][id]],"(\"",value[am][id],"\") is expected to be \"",string[key[em][id]],"(\"",value[em][id],"\")";
    ];
  if[not null id:first where not (cnt#value[am])=cnt#value[em];
    :`$"column ",string[id]," ",string[key[am][id]],"(\"",value[am][id],"\")\" is expected to be \"",string[key[em][id]],"(\"",value[em][id],"\")\"";
    ];
  if[cnt<count[am];
    :`$"column ",string[cnt]," ",string[key[am][cnt]],"(\"",value[am][cnt],"\") is unexpected";
    ];
  if[cnt<count[em];
    :`$"column ",string[cnt]," ",string[key[em][cnt]],"(\"",value[em][cnt],"\") is missing";
    ];
  :`
  };

//----------------------------------------------------------------------------//
.assert.p.insert:{[msg;assertType;res;info;expected;actual]
  `.test.asserts insert (.test.testSuite;.test.testCase;msg;assertType;`FAILURE`SUCCESS res;info;expected;actual);
  $[res;`SUCCESS;last .test.asserts]
  };

//----------------------------------------------------------------------------//
//                             test runner                                    //
//----------------------------------------------------------------------------//
/S/ execute test suite
/E/ns:`.testHdbLoader;
//ns:`.testJSON;
.test.run:{[ns]
  suite:`$ns`testSuite; 
  setUp:ns[`setUp];
  testsNs:` sv ns,`test;
  testList:system"f ",string testsNs;
  tests:` sv/: testsNs,/:testList;
  tearDown:ns[`tearDown];
  .test.suiteStart:.z.p;
  .test.p.runOne'[suite;tests;setUp;value each tests;tearDown];
  .test.suiteEnd:.z.p;
  rep:.test.report[];
  fail:0<count rep[`testCasesFailed];
  msg:"==========================> TestSuite \"", string[suite], "\" ",$[fail;"FAILED";"COMPLETED"]," with ";
  msg,:"[",string[count[rep`testCases]-count[rep`testCasesFailed]],"/",string[count rep[`testCases]],"] test cases, ";
  msg,:"[",string[count[rep`asserts]-count[rep`assertsFailed]],"/",string[count rep[`asserts]],"] asserts.";
  $[fail;.test.p.logError;.test.p.logInfo] msg;
  rep
  };

//----------------------------------------------------------------------------//
.test.runOneTest:{[tCase]
  ns:` sv 2#` vs tCase;
  suite:`$ns`testSuite; 
  setUp:ns[`setUp];
  tearDown:ns[`tearDown];
  .test.p.runOne[suite;tCase;setUp;value tCase;tearDown];
  last .test.res
  };

//----------------------------------------------------------------------------//
.test.p.runOne:{[suite;testCase;setUp;test;tearDown]
  .test.p.logInfo "==========================> testCase ", string[testCase];
  startTs:.z.p;
  (`.test.testSuite`.test.testCase`.test.setUp`.test.test`.test.tearDown) set' (suite;testCase;setUp;test;tearDown);
  .test.setUpErr:.test.testCaseErr:.test.tearDownErr:`;
  .test.lastFunc:();
  assertsBefore:exec count i by result from .test.asserts;  
  setUpRes:@[setUp;::;{.test.setUpErr:`$x}];
  testRes:@[test;::;{.test.testCaseErr:`$x}];
  tearDownRes:@[tearDown;::;{.test.tearDownErr:`$x}];
  endTs:.z.p;
  assertsAfter:exec count i by result from .test.asserts;  
  assertsDiff:assertsAfter - assertsBefore;

  result:$[not all`~/:(.test.setUpErr;.test.testCaseErr;.test.tearDownErr);`ERROR;0<assertsDiff`FAILURE;`FAILURE;`SUCCESS];
  `.test.res insert (suite;testCase;result;sum assertsDiff;assertsDiff`FAILURE;.test.setUpErr;.test.testCaseErr;.test.tearDownErr;startTs;endTs-startTs;.test.lastFunc);
  };

//----------------------------------------------------------------------------//
//                            reports                                         //
//----------------------------------------------------------------------------//
.test.getInterfaceList:{[namespace]
  ` sv/: namespace,/:key[namespace]except ``p`cfg
  };

//----------------------------------------------------------------------------//
/F/.test.report[]
.test.coverage:{[]
  stats:select cnt:count i, testCase by func:functions, result from ungroup select testSuite, testCase, result, functions from .test.res;
  stats:(select testCnt:sum cnt by func from stats) uj (select failCnt:sum cnt, failTestCases:raze testCase by func from stats where not result=`SUCCESS);
  stats
  };

//----------------------------------------------------------------------------//
/F/.test.report[]
.test.report:{[]
  report:()!();
  report[`testCases]:.test.res;
  report[`testCasesFailed]:select from .test.res where not result=`SUCCESS;
  report[`asserts]:.test.asserts;
  report[`assertsFailed]:select from .test.asserts where not result in ``SUCCESS;
  report[`interfaceCoverage]:.test.coverage[];
  report
  };

//----------------------------------------------------------------------------//
//                               mocking                                      //
//----------------------------------------------------------------------------//
.test.mock:{[funcName;funcBody]
  funcName set funcBody
  };

//----------------------------------------------------------------------------//
.test.p.logInfo:{[msg] -1 "INFO ",x;};

//----------------------------------------------------------------------------//
.test.p.logError:{[msg] -1 "ERROR ",x;};

//----------------------------------------------------------------------------//
//                                JUnit export                                //
//----------------------------------------------------------------------------//

//------------------------- xml printer --------------------------------------//
.xml.empty:([]tag:(); attributes:(); content:());
.xml.print:{
  if[98=type x;:"\n" sv .xml.print each x];
  if[99=type x;
    attributes:$[count x`attributes;" ",{" " sv string[key x],'"=",'{$[10h=type x;.Q.s1[x];"\"",.Q.s1[x],"\""]}each value x}x`attributes;""];
    content:"\n" sv .xml.print each x`content;
    :"\n<",string[x`tag], attributes,$[count x`content;">",content,"</",string[x`tag],">";"/>"]
    ];
  };

//------------------------- xml test result ----------------------------------//
/E/.test.toXml .test.res
//x:first .test.res
.test.toXml:{[res]
  properties:.xml.empty,`tag`attributes`content!(`properties;()!();.xml.empty,`tag`attributes`content!(`property;`name`value!("tstPath";ssr[system["cd"];"\\";"/"],"/",string[.z.f]);()));
  testcases:.xml.empty,{`tag`attributes`content!(`testcase;`classname`name`time!(string[.test.appname];string[x`testCase];string[0.001*`long$`time$x`duration]);())} each res;
  sysout:.xml.empty,`tag`attributes`content!(`$"system-out";()!();());
  syserr:.xml.empty,`tag`attributes`content!(`$"system-err";()!();());
  cnt:(`SUCCESS`ERROR`FAILURE!0 0 0),exec count i by result from res;
  duration:`long$`second$.test.suiteEnd-.test.suiteStart;
  name:exec first testSuite from res; //TODO: support for multiple test suits
  suites:.xml.empty,`tag`attributes`content!(`testsuite;`errors`failures`hostname`name`tests`time`timestamp!(cnt`ERROR; cnt`FAILURE; string .z.h; string name; sum cnt; duration; .test.suiteStart);(properties,testcases,sysout,syserr));

  result:.xml.empty,`tag`attributes`content!(`testsuites;()!();suites);
  .xml.print result
  };

//----------------------------------------------------------------------------//
