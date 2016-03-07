/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/-/
/-/ Licensed under the Apache License, Version 2.0 (the "License");
/-/ you may not use this file except in compliance with the License.
/-/ You may obtain a copy of the License at
/-/
/-/   http://www.apache.org/licenses/LICENSE-2.0
/-/
/-/ Unless required by applicable law or agreed to in writing, software
/-/ distributed under the License is distributed on an "AS IS" BASIS,
/-/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/-/ See the License for the specific language governing permissions and
/-/ limitations under the License.

/A/ DEVnet: Pawel Hudak
/V/ 3.0

/S/ Test framework
/-/ Example of testSuite is located in ec/libraries/qtest/example
/-/ See README.md for qtest usage details

//----------------------------------------------------------------------------//
//                             test results                                   //
//----------------------------------------------------------------------------//
/G/ Table with test results. One row for each executed test case.
/-/  -- testSuite:SYMBOL   - test suite name
/-/  -- testCase:SYMBOL    - test case name
/-/  -- result:SYMBOL      - test result
/-/  -- assertRun:LONG     - number of executed assertions
/-/  -- assertFailed:LONG  - number of failed assertions
/-/  -- setUpErr:SYMBOL    - signal that was thrown during setUp execution, empty ` if setUp was executed without signals
/-/  -- testCaseErr:SYMBOL - signal that was thrown during testCase execution, empty ` if testCase was executed without signals
/-/  -- tearDownErr:SYMBOL - signal that was thrown during tearDown execution, empty ` if tearDown was executed without signals
/-/  -- startTs:TIMESTAMP  - start time of the test
/-/  -- duration:TIMESPAN  - duration of the test
/-/  -- functions:LIST     - list of tested functions that were executed during the test
.test.res:([]testSuite:`symbol$(); testCase:`symbol$();result:`symbol$();assertRun:`long$(); assertFailed:`long$(); setUpErr:`symbol$();testCaseErr:`symbol$();tearDownErr:`symbol$();startTs:`timestamp$(); duration:`timespan$(); functions:());

//----------------------------------------------------------------------------//
/G/ Test component name, based on .z.f.
.test.appname:.z.f;

//----------------------------------------------------------------------------//
//                             assertions                                     //
//----------------------------------------------------------------------------//
/G/ Assertion execution results summary.
/-/  -- testSuite:SYMBOL   - test suite name
/-/  -- testCase:SYMBOL    - test case name
/-/  -- assert:SYMBOL      - assertion description message
/-/  -- assertType:SYMBOL  - assertion type
/-/                        one of `MATCH`FAIL`TRUE`FALSE`TYPE`CONTAINS`CONTAINS`IN`WITHIN`ALL_IN`ALL_WITHIN`LESS_EQ`MORE_EQ`MATCH_MODEL
/-/  -- result:SYMBOL      - assertion result - `FAILURE or `SUCCESS
/-/  -- failureInfo:SYMBOL - detailed information about assertion failure reasons
/-/  -- expected:ANY       - expected assertion value
/-/  -- actual:ANY         - actual assertion value
.test.asserts:([]testSuite:`symbol$(); testCase:`symbol$(); assert:`symbol$(); assertType:`symbol$();result:`symbol$();failureInfo:`symbol$();expected:();actual:());
//initial insert to keep last two columns of generic type
`.test.asserts insert (`;`;`;`;`;`;(::);(::));

//----------------------------------------------------------------------------//
/F/ Assertion `MATCH validates whether `actual is exactly the same as `expected.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING   - message describing the purpose of the assertion
/P/ actual:ANY   - actual value which is being analyzed
/P/ expected:ANY - expected value
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.match["12 is 12"; 12; "12"] 
/E/  .assert.match["12 is 12"; 12; 12.f] 
/E/  .assert.match["12 is 12"; 12; 12] 
/E/  .assert.match["vector is correct"; 1 2 3; 1 2] 
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
/F/ Assertion `FAIL catches and validates expected signal after evaluation of given expression.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING                   - message describing the purpose of the assertion
/P/ expression:LIST              - expression which is being analyzed, expression will be executed in protected evaluation
/P/ expectedSig:SYMBOL OR STRING - signal or 'like-stle' pattern that should match the signal thrown after expression evaluation
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.fail["2 cannot be added to `a"; "2+`a"; "type"]
.assert.fail:{[msg;expression;expectedSig]
  actual:@[value;expression;{(`ASSERTION_SIGNAL_MARKER;x)}];
  if[res:first[actual]~`ASSERTION_SIGNAL_MARKER;
    res:last[actual] like $[10h=type expectedSig;expectedSig;string expectedSig];
	];
  :.assert.p.insert[`$msg;`FAIL;res;`;expectedSig;actual];
  };

//----------------------------------------------------------------------------//
/F/ Assertion `TRUE validates whether `actual is 1b.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING - message describing the purpose of the assertion
/P/ actual:ANY - actual value which is being analyzed
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.true["res is TRUE";1b]
.assert.true:{[msg;actual]
  res:1b~actual;
  info:$[-1h=type actual;`;`$"expected type -1h instead of ", string[type actual],"h"];
  :.assert.p.insert[`$msg;`TRUE;res;info;1b;actual];
  };

//----------------------------------------------------------------------------//
/F/ Assertion `FALSE validates whether `actual is 0b.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING - message describing the purpose of the assertion
/P/ actual:ANY - actual value which is being analyzed
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.true["res is FALSE";0b]
.assert.false:{[msg;actual]
  res:0b~actual;
  info:$[-1h=type actual;`;`$"expected type -1h instead of ", string[type actual],"h"];
  :.assert.p.insert[`$msg;`FALSE;res;info;0b;actual];
  };

//----------------------------------------------------------------------------//
/F/ Assertion `TYPE validates type of the `actual.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING     - message describing the purpose of the assertion
/P/ actual:ANY     - actual value which is being analyzed
/P/ expected:SHORT - type identifier number
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.type["res type is symbol";`test;-11h]
.assert.type:{[msg;actual;expected]
  res:expected=type actual;
  info:$[-5h=type expected;`;`$"expected type must be specified as 'short type identifier' (type -5h), received type ", string[type expected],"h"];
  :.assert.p.insert[`$msg;`TYPE;res;info;expected;type actual];
  };

//----------------------------------------------------------------------------//
/F/ Assertion `CONTAINS validates whether `actual contains `expected.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING   - message describing the purpose of the assertion
/P/ actual:LIST  - actual value which is a list of entries, one of which should contain `expected entry
/P/ expected:ANY - value which should be in the `actual list
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.contains["List contains 1"; (`12;`23;`a;1); 1] 
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
/F/ Assertion `CONTAINS_ALL validates whether `actual contains all of the `expected entries.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING    - message describing the purpose of the assertion
/P/ actual:LIST   - actual value which is a list of entries, which should include all of the `expected entries
/P/ expected:LIST - list of values which should be a sublist of the `actual list
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.containsAll["List contains 1 2 3"; (`12;`23;`a;1); 1 2 3] 
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
  :.assert.p.insert[`$msg;`CONTAINS_ALL;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
/F/ Assertion `IN validates whether `actual item is in the `expected list.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING    - message describing the purpose of the assertion
/P/ actual:ANY    - actual value which should be in the `expected list of entries
/P/ expected:LIST - list of values which should contain the `actual value
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.in["2 in the domain"; 2; 1 2 3] 
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
/F/ Assertion `WITHIN validates whether `actual item is within the `expected range.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING    - message describing the purpose of the assertion
/P/ actual:ANY    - actual value which should be within the `expected range
/P/ expected:PAIR - range which should contain the `actual value
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.within["res is in range";2;1 5]
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
/F/ Assertion `ALL_IN validates whether `actual items are all in the `expected list.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING    - message describing the purpose of the assertion
/P/ actual:LIST   - actual is a list of values which all should be in the `expected list of entries
/P/ expected:LIST - list of values which should contain all of the `actual values
/E/ .assert.allIn["all results are in domain"; 1 2 3; 1 2 3 4 5]
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
/F/ Assertion `ALL_WITHIN validates whether `actual items are all within the `expected range.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING    - message describing the purpose of the assertion
/P/ actual:LIST   - actual is a list of values which all should be within the `expected range
/P/ expected:LIST - list of values which should contain all of the `actual values
/P/ expected:PAIR - range which should contain all of the `actual values
/E/ .assert.allWithin["all results are in domain"; 1 2 3; 1 5]
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
/F/ Assertion `LESS_EQ validates whether `actual <= `expected is true.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING   - message describing the purpose of the assertion
/P/ actual:ANY   - actual value which is being analyzed
/P/ expected:ANY - expected value which is the upper limit for the `actual value
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.lessEq["res is <=100"; 12; 100] 
.assert.lessEq:{[msg;actual;expected]
  output:.[<=;(actual;expected);::];
  info:$[output~"type";`$"invalid types for <= operator:",string[type actual],"h and ",string[type expected],"h";
    -1h=type output;`;
    `$"operator <= signal:'",output];
  res:info~`;
  :.assert.p.insert[`$msg;`LESS_EQ;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
/F/ Assertion `MORE_EQ validates whether `actual >= `expected is true.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING   - message describing the purpose of the assertion
/P/ actual:ANY   - actual value which is being analyzed
/P/ expected:ANY - expected value which is the lower limit for the `actual value
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.moreEq["res is >=0"; 12; 0] 
.assert.moreEq:{[msg;actual;expected]
  output:.[>=;(actual;expected);::];
  info:$[output~"type";`$"invalid types for >= operator:",string[type actual],"h and ",string[type expected],"h";
    -1h=type output;`;
    `$"operator >= signal:'",output];
  res:info~`;
  :.assert.p.insert[`$msg;`MORE_EQ;res;info;expected;actual];
  };

//----------------------------------------------------------------------------//
/F/ Assertion `MATCH_MODEL validates whether `actual data model is matching `expected model.
/-/ Assertion result is inserted into .test.asserts global table.
/P/ msg:STRING     - message describing the purpose of the assertion
/P/ actual:TABLE   - actual table which is being analyzed
/P/ expected:TABLE - expected data mode which should match `actual data model
/R/ `SUCCESS in case of assertion success, otherwise a DICT with detailed failure information with entries from .test.asserts table.
/E/  .assert.matchModel["test model";([]colA:1 2 3);([]colA:`long$())]
/E/  .assert.matchModel["test model";([]colA:string `aaa`bb);([]colA:`symbol$())]
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

//----------------------------------------------------------------------------//
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
/F/ Executes one test suite.
/P/ ns:SYMBOL - namespace which should include some specific variables:
/-/   -- testSuite:SYMBOL       - test suite name
/-/   -- setUp:LAMBDA           - set-up lambda
/-/   -- tearDown:LAMBDA        - tear-down lambda
/-/   -- test:DICT(NAME;LAMBDA) - dictionary with test cases
/R/ :TABLE - output from .test.report[]
/E/  .test.run `.testHdbWirter
/E/  .test.run `.testJSON
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
/F/ Executes one test case.
/P/ tCase:SYMBOL - test case name
/R/ :DICT - dictionary with results, keys are matching columns from .test.res
/E/  .test.runOneTest
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
/F/ Returns list of interface functions and globals in the given namespace.
/P/ namespace:SYMBOL - namespace
/R/ :LIST SYMBOL - list of interface functions and globals
/E/ .test.getInterfaceList `.qtest
.test.getInterfaceList:{[namespace]
  ` sv/: namespace,/:key[namespace]except ``p`cfg
  };

//----------------------------------------------------------------------------//
/F/ Retunrs statistics about interface functions coverage in the executed test cases.
/R/ TABLE - table with coverage information
/-/  -- func:SYMBOL               - function name
/-/  -- testCnt:LONG              - count of test cases which were executing given function
/-/  -- failCnt:LONG              - count of test cases which were executing given function and failed
/-/  -- failTestCases:LIST SYMBOL - list of test cases which were executing given function and failed
/E/  .test.coverage[]
.test.coverage:{[]
  stats:select cnt:count i, testCase by func:functions, result from ungroup select testSuite, testCase, result, functions from .test.res;
  stats:(select testCnt:sum cnt by func from stats) uj (select failCnt:sum cnt, failTestCases:raze testCase by func from stats where not result=`SUCCESS);
  stats
  };

//----------------------------------------------------------------------------//
/F/ Retunrs full report about executed functions.
/R/ :DICT - dictionary with all information about executed tests.
/-/  -- testCases         - summary of all test cases (see .test.res)
/-/  -- testCasesFailed   - subset of testCases, limited to failed test cases only
/-/  -- asserts           - summary of all assertions (see .test.asserts)
/-/  -- assertsFailed     - subset of asserts, limited to failed test cases only
/-/  -- interfaceCoverage - interface functions coverage in the executed test cases (see .test.coverage[])
/E/  .test.report[]
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
/F/ Creates mock. Currently simple set which does not allow 'un-mocking'.
/P/ funcName:SYMBOL - mocked name
/P/ funcBody:ANY    - mocked value
/R/ no return value
/E/  .test.mock[`.hdb.status;{([]tab:`trade`quote;statue:`OK`OK)}]
.test.mock:{[funcName;funcBody]
  funcName set funcBody
  };

//----------------------------------------------------------------------------//
.test.p.logInfo:{[msg] -1 "INFO ",x;};

//----------------------------------------------------------------------------//
.test.p.logError:{[msg] -1 "ERROR ",x;};

//----------------------------------------------------------------------------//
//                            xml export                                      //
//----------------------------------------------------------------------------//
/G/ Empty xml tag.
.xml.empty:([]tag:(); attributes:(); content:());

//----------------------------------------------------------------------------//
/F/ Prints q data table as xml.
/P/ x:TABLE | DICT - q table or dictionary with 
/-/   -- tag:SYMBOL      - tag name
/-/   -- attributes:DICT - set of xml tag-attributes in form of a q dictionary
/-/   -- content:TABLE   - recursive subelements with columns tag, attributes, content.
/R/ :STRING - string with xml representation of given q table
/E/ .xml.print .xml.empty
.xml.print:{[x]
  if[98=type x;:"\n" sv .xml.print each x];
  if[99=type x;
    attributes:$[count x`attributes;" ",{" " sv string[key x],'"=",'{$[10h=type x;.Q.s1[x];"\"",.Q.s1[x],"\""]}each value x}x`attributes;""];
    content:"\n" sv .xml.print each x`content;
    :"\n<",string[x`tag], attributes,$[count x`content;">",content,"</",string[x`tag],">";"/>"]
    ];
  };

//----------------------------------------------------------------------------//
//                          xml test result export                            //
//----------------------------------------------------------------------------//
/F/ Converts test result to xml format compatible with Jenkins.
/P/ res:TABLE - test result table matching the model from .test.res
/R/ :STRING - xml representation of result, compatible with Jenkins
/E/ .test.toXml .test.res
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
