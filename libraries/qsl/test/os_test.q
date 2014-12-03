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

/A/ DEVnet: Slawomir Kolodynski
/V/ 3.0

// Usage:
//q test/os_test.q --noquit -p 5001

system"l sl.q";
system"l lib/qspec/qspec.q";

.sl.init[`os_test];
system"l lib/qsl/os.q";

/F/ for windows converts forward slashes to backslashes

/------------------------------------------------------------------------------/
/                                tests                                         /
/------------------------------------------------------------------------------/

.tst.desc["[os.q] mkdir, rmdir"]{
  before{
    .os.mkdir "test/testdir";
    `:./test/testdir/test.txt 0: enlist "This is a test.";
    };
  after{};
  should["create and erase directory"]{
    1b mustmatch `testdir in key `:./test;
    1b mustmatch `test.txt in key `:./test/testdir;
    .os.rmdir "test/testdir";
    0b mustmatch `testdir in key `:./test;
    };
  };
  
.tst.desc["[os.q] cpdir"]{
  before{
    .os.mkdir "test/dir2cp";
    `:./test/dir2cp/test.txt 0: enlist "This is a test.";
    .os.cpdir["test/dir2cp";"test/dir2cpCopy"];
    .os.mkdir "test/dir2";
    .os.cpdir["test/dir2cp";"test/dir2"]; // copy to existing directory
    
    };
  after{
    .os.rmdir "test/dir2cp";
    .os.rmdir "test/dir2cpCopy";
    .os.rmdir "test/dir2"
    };
  should["copy a directory"]{
    1b mustmatch `dir2cpCopy in key `:./test;
    1b mustmatch `test.txt in key `:./test/dir2cpCopy;
    };
  should["copy contents to existing directory"]{
    1b mustmatch `test.txt in key `:./test/dir2;
    };
  };
  
.tst.desc["[os.q] move"]{
  before{
    .os.mkdir "test/dir2move";
    `:./test/dir2move/test.txt 0: enlist "This is a test.";
    // move file
    .os.move["test/dir2move/test.txt";"test/dir2move/movedtest.txt"];
    // move directory
    .os.move["test/dir2move";"test/dirmoved"];
    };
  after{
    .os.rmdir "test/dirmoved";
    };
  should["move a directory"]{
    1b mustmatch `dirmoved in key `:./test;
    1b mustmatch `movedtest.txt in key `:./test/dirmoved;
    }; 
  };


