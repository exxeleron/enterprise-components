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

/A/ DEVnet: Piotr Szawlis
/V/ 3.0

// Functional tests of the qsl/os library
// See README.md for details

//----------------------------------------------------------------------------//
.testQslOs.testSuite:"qsl/os functional tests";

.testQslOs.setUp:{
  .test.start `t0.os;
  .test.mock[`hos;.hnd.h[`t0.os]];
  hos (`.os.mkdir;"test")
  };

.testQslOs.tearDown:{
  hos (`.os.rmdir;"test"); 
  .test.stop `t0.os;
  };

.testQslOs.test.commands:{
  hos (`.os.mkdir;"test/testdir");
  hos "`:./test/testdir/test.txt 0: enlist \"This is a test.\"";
  .assert.match["dummy test";1b;1b];
  .assert.true["create directory";`testdir in hos "key `:./test"];
  .assert.true["create file";`test.txt in hos "key `:./test/testdir"];
  hos (`.os.mkdir; "test/dir2cp");
  hos "`:./test/dir2cp/test.txt 0: enlist \"This is a test.\"";
  hos (`.os.cpdir;"test/dir2cp";"test/dir2cpCopy");
  hos (`.os.mkdir; "test/dir2");  
  hos (`.os.cpdir;"test/dir2cp";"test/dir2");
  .assert.true["copy to previously not existing directory";`dir2cpCopy in hos "key `:./test"];
  .assert.true["copy with content";`test.txt in hos "key `:./test/dir2cpCopy"];
  .assert.true["copy to previously existing directory";`dir2 in hos "key `:./test"];
  hos (`.os.mklink;"test/testdir";"test/link");
  .assert.true["create link";`test.txt in hos "key `:./test/link"];
  hos (`.os.rmdir;"test/testdir");
  .assert.false["remove directory";`testdir in hos "key `:./test"];  
  };