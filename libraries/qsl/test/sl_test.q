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

// Usage:
//q test/sl_test.q --noquit -p 5001


\l lib/qspec/qspec.q

.tst.desc["[sl.q] Setting up defaults"]{
  before{
    system "l sl.q";
    system "l pe.q";
    /clean up the environment
    if[0<count .sl.test.libpath:getenv `EC_LIB_PATH;`EC_LIB_PATH setenv ""];
    if[0<count .sl.test.etcpath:getenv `EC_ETC_PATH;`EC_ETC_PATH setenv ""];
    if[0<count .sl.test.dllpath:getenv `EC_DLL_PATH;`EC_DLL_PATH setenv ""];
    delete libpath from `.sl;
    delete etcpath from `.sl;
    delete dllpath from `.sl;
    delete firstRun from `.sl.p;
    delete libpath from  `.sl;
    .sl.init[`testapp];
    };
  after{
    /reconstruct the environment
    if[0<count .sl.test.libpath;`EC_LIB_PATH setenv .sl.test.libpath];
    if[0<count .sl.test.etcpath;`EC_ETC_PATH setenv .sl.test.etcpath];
    if[0<count .sl.test.dllpath;`EC_DLL_PATH setenv .sl.test.dllpath];
    delete libpath from `.sl;
    delete etcpath from `.sl;
    delete dllpath from `.sl;
    };
  should["set configuration variables to default"]{
    //if[0~count getenv`QHOME;.sl.libpath mustmatch enlist `:./lib/];
    .sl.libpath mustmatch $[0~count syspath:getenv`EC_SYS_PATH;enlist `:./lib/;(`:./lib/;`$":",syspath,"/bin/ec/libraries/")];
    .sl.etcpath mustmatch $[0~count syspath;enlist `:./etc/;(`:./etc/;`$":",syspath,"/etc/")];
    .sl.dllpath mustmatch $[0~count syspath:getenv`EC_SYS_PATH;enlist `:./dll/;(`:./dll/;`$":",syspath,"/bin/ec/libraries/")];
    };
  };

.tst.desc["[sl.q] Getting configuration from environment"]{
  before{
    system "l sl.q";
    system "l pe.q";
    system "mkdir testlib";
    system "mkdir testetc";
    `:testlib/tlib1.q 0: enlist "a:1;";
    `:testlib/tlib2.q 0: enlist "a+:1;";
    `:testetc/te.q 0: enlist "b:3;";
    /set up the environment
    .sl.test.libpath:getenv `EC_LIB_PATH;
    `EC_LIB_PATH setenv "./testlib";
    .sl.test.etcpath:getenv `EC_LIB_PATH;
    `EC_ETC_PATH setenv "./testetc/";
    .sl.reinit[`testapp];
    .sl.etc[`te];
    .sl.lib[`tlib1];
    .sl.lib[`tlib2];
    };
  after{
    /reconstruct the environment
    if[0<count .sl.test.libpath;`EC_LIB_PATH setenv .sl.test.libpath];
    if[0<count .sl.test.etcpath;`EC_ETC_PATH setenv .sl.test.etcpath];
    if[0<count .sl.test.dllpath;`EC_DLL_PATH setenv .sl.test.dllpath];
    /remove created directories with files
    system (rmdir:$["w"~first string .z.o;"rmdir /s /q";"rm -rf"])," testlib";
    system rmdir," testetc";
    };
  should["set configuration according to environment variables"]{
    .sl.libpath mustmatch enlist `:./testlib;
    .sl.etcpath mustmatch enlist `:./testetc/;
    a mustmatch 2;
    b mustmatch 3;
    };
  };

.tst.desc["[sl.q] converting backslashes to forward slashes in log path"]{
  before{
    system "l sl.q";
    .sl.test.logpath:getenv `EC_LOG_PATH;
    `EC_LOG_PATH setenv "C:\\dir1\\dir2/dir3/";
    // remove current path variable if any
    .log _:`path;
    .sl.p.initLog[];
    };
    after {
      if[0<count .sl.test.logpath;`EC_LOG_PATH setenv .sl.test.logpath];
      };
    should["convert backslashes to forward slashes in log path"]{
      (count string .log.path) mustmatch (string .log.path)?"\\";
      };
  };
