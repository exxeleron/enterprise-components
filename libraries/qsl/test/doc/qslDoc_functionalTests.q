/L/ Copyright (c) 2011-2015 Exxeleron GmbH
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

// Functional tests of the qsl/doc library
// See README.md for details

//----------------------------------------------------------------------------//
.testQslDoc.testSuite:"qsl/doc functional tests";

.testQslDoc.setUp:{
  .test.start`t0.doc;
  };

.testQslDoc.tearDown:{
  .test.stop`t0.doc;
  };

//----------------------------------------------------------------------------//
//                           .doc.list[]                                      //
//----------------------------------------------------------------------------//
.testQslDoc.test.doc_list:{[]
  .assert.match["documentation not loaded at startup"; .test.h[`t0.doc]"count .doc.p.all"; 0j];
  res:.test.h[`t0.doc]".doc.list`";

  .assert.moreEq["documentation loaded after .doc.list call"; .test.h[`t0.doc]"count .doc.p.all"; 1j];
  .assert.matchModel[".doc.list returns table with functions"; res; ([]func:`symbol$(); ns:`symbol$(); args:(); descr:(); params:(); ret:(); examples:(); file:`symbol$() )];
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_list_mockFunc:{[]
  allFunc:.test.h[`t0.doc]".doc.list`";
  mockFuncOnly:.test.h[`t0.doc]".doc.list`mockFunc";
  .assert.match[".doc.list`mockFunc returns only functions from .mockFunc namespace"; exec distinct ns from mockFuncOnly; enlist`mockFunc];
  .assert.match[".doc.list` content for .mockFunc functions is the same as in .doc.list`mockFunc"; mockFuncOnly; select from allFunc where ns=`mockFunc];
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_list_unknownNamespace:{[]
  res:.test.h[`t0.doc]".doc.list`unknownNamespace";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_list_invalidType:{[]
  res:.test.h[`t0.doc]".doc.list 12";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_list_functionOutsideOfSrcFile:{[]
  .test.h[`t0.doc]".mockFunc.adHocFunc:{2+x}";
  res:.test.h[`t0.doc]".doc.list`adHocFunc";
  };

//----------------------------------------------------------------------------//
//                           .doc.find[]                                      //
//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find:{[]
  .assert.match["documentation not loaded at startup"; .test.h[`t0.doc]"count .doc.p.all"; 0j];
  res:.test.h[`t0.doc]".doc.find`implicit";
  .assert.moreEq["documentation loaded after .doc.find call"; .test.h[`t0.doc]"count .doc.p.all"; 1j];
  .assert.match[".doc.find`implicit returns proper type"; res; ()];
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_functionKeyword:{[]
  res:.test.h[`t0.doc]".doc.show`functionKeyword";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_descKeyword:{[]
  res:.test.h[`t0.doc]".doc.show`descKeyword";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_argKeyword:{[]
  res:.test.h[`t0.doc]".doc.show`argKeyword";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_returnKeyword:{[]
  res:.test.h[`t0.doc]".doc.show`returnKeyword";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_exampleKeyword:{[]
  res:.test.h[`t0.doc]".doc.show`exampleKeyword";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_mockFunc:{[]
  res:.test.h[`t0.doc]".doc.show`functionKeyword";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_sourceExample:{[]
  res:.test.h[`t0.doc]".doc.show`sourceExample";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_argName:{[]
  res:.test.h[`t0.doc]".doc.show`sourceExample";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_bodyPart:{[]
  res:.test.h[`t0.doc]".doc.show`bodyPart";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_unknownKeyword:{[]
  res:.test.h[`t0.doc]".doc.show`unknownKeyword";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_find_invalidType:{[]
  res:.test.h[`t0.doc]".doc.show 12";
  };

//----------------------------------------------------------------------------//
//                           .doc.show[]                                      //
//----------------------------------------------------------------------------//
.testQslDoc.test.doc_info:{[]
  .assert.match["documentation not loaded at startup"; .test.h[`t0.doc]"count .doc.p.all"; 0j];
  res:.test.h[`t0.doc]".doc.show`.mockFunc.oneArg";
  .assert.moreEq["documentation loaded after .doc.show call"; .test.h[`t0.doc]"count .doc.p.all"; 1j];
  .assert.match[".doc.show`.mockFunc.oneArg returns proper type"; res; ()];
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_list_unknownFunction:{[]
  res:.test.h[`t0.doc]".doc.show`.mockFunc.unknownFunction";
  };

//----------------------------------------------------------------------------//
.testQslDoc.test.doc_info_invalidType:{[]
  res:.test.h[`t0.doc]".doc.show 12";
  };

//----------------------------------------------------------------------------//
.test.report[]`testCasesFailed
