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

//
/A/ DEVnet: Slawomir Kolodynski
/D/ 2013-02-25
/V/ 0.1
/S/ Unit tests for timer (timer.q)
/E/ q test/timer_test.q --noquit -p 5001

/------------------------------------------------------------------------------/
/                                 dependencies                                 /
/------------------------------------------------------------------------------/

system "l lib/qspec/qspec.q";

system "l sl.q";
system "l pe.q";
system "l timer.q";
system "l event.q";
.sl.init[`timer_test];

/F/ starts a q process on the specified port and executes a script
/P/ offset:INT - the process is started at the offset from te current port
/P/ script:STRING - the name of script, without the q extension
/R/ :HANDLE - a handle to the running q process
.tst.tmr.exect:{[offset;script]
  port:.z.i+256;
  if[.z.o in `w32`w64; system "start q -p ",(string port+offset)];
  if[.z.o in `l32`s32`v32`l64`s64`v64;system "q -p ",(string port+offset)];
  system "sleep 2"; // to give time to start
  h:hopen `$":localhost:",string offset+port;
  h "done:0b";
  h "system\"l ",script,".q\"";
  if[not 1b~h "done";show "error in remote script execution for ",script];
  show "started temporary process on port ", .Q.s1 port;
  :h
  };

/------------------------- tests ----------------------------------------------/

.tst.desc["[timer.q] greatest common divisor - .tmr.p.gcd[]"]{
  before{
    };
  after{
    };
  should["calculate gcd correctly"]{
    start:.z.t;
    31000000 mustmatch .tmr.p.gcd 62000000 31000000;
    500 mustmatch .tmr.p.gcd 60000 59000 58000 57000 59500;
    // must be fast enough
    1b mustmatch 1000>.z.t - start;
    };
  };
  
.tst.desc["[timer.q] .tmr.recalcGcd"]{
  before{
    .tst.tmr.f:{};
    .tmr.start[`.tst.tmr.f;10000;`.tst.tmr.f];
    .tmr.reset[];
    };
  after{};
  should[".tmr.p.recalcGcd not should not fail on empty .tmr.status"]{
    .tmr.p.recalcGcd[];
    };
  };

.tst.desc["[timer.q] .tmr.change: starting, stopping and changing period of a callback - .tmr.start[], .tmr.stop[]"]{
  before{
    // start a q process on the next port
    .tst.tmr.h:.tst.tmr.exect[1;"test/ext/timer_aux1"];
    .tst.tmr.h".tmr.start[`f;1000;`f]"; // that will run the callback
    show "waiting 5 sec. to allow timer callack to run 5 times";
    system "sleep 5";
    .tst.tmr.fcount:.tst.tmr.h".test.fcount";
    .tst.tmr.h".tmr.stop[`f]";
    show "waiting 2 sec. to make sure the calback stopped running";
    system "sleep 2";
    .tst.tmr.fcount1:.tst.tmr.h".test.fcount";
    // start the callback again
    .tst.tmr.h".tmr.start[`f;1000;`f]"; // that will run the callback
    show "waiting 5 sec. to allow callback to run 5 times";
    system "sleep 5";
    .tst.tmr.h".tmr.change[2000;`f]";
    show "waiting 11 sec. to allow callback to run 5 times after changed period";
    system "sleep 11";
    .tst.tmr.fcount2:.tst.tmr.h".test.fcount";
    };
  after{
    @[.tst.tmr.h;"exit 0";`$"closed remote process"];
    };
  should["have run the scheduled function the right number of times"]{
    .tst.tmr.fcount mustmatch 6;
    .tst.tmr.fcount1 mustmatch 6;
    .tst.tmr.fcount2 mustmatch 18;
    };
  };

.tst.desc["[timer.q] Testing under load when timer ticks are missed - .tmr.runAt[]"]{
  before{
    port:system "p";
    // start a q process on the next port
    .tst.tmr.h:.tst.tmr.exect[1;"test/ext/timer_aux1"];
    .tst.tmr.h".tmr.runAt[.z.t+5000;`f;`f]";
    show "waiting 21 sec. to miss timer ticks";
    .tst.tmr.h"system \"sleep 21\"";
    system "sleep 1";
    .tst.tmr.fcount:.tst.tmr.h".test.fcount";
    };
  after{
    @[.tst.tmr.h;"exit 0";`$"closed remote process"];
    };
  should["have run the scheduled function once"]{
    .tst.tmr.fcount mustmatch 1;
    };
  };

.tst.desc["[timer.q] Testing log rotate"]{
  before{
    // remove testlog if present
    if[`testlog in key `:./test;system "rm -rf test/testlog"];
    system "mkdir test/testlog";
    .tst.tmr.logdest:getenv `EC_LOG_DEST;
    .tst.tmr.logpath:getenv `EC_LOG_PATH;
    .tst.tmr.logrotate:getenv `EC_LOG_ROTATE;
    `EC_LOG_DEST setenv "FILE,CONSOLE";
    `EC_LOG_PATH setenv "./test/testlog";
    `EC_LOG_ROTATE setenv string .z.t + 10000;
    // start a q process on the next port
    `.tst.tmr.h mock .tst.tmr.exect[1;"test/ext/timer_aux1"];
    `.tst.tmr.pid mock .tst.tmr.h `.z.i;
    show "waiting 21 s for logs to rotate";
    system "sleep 21";
    .tst.tmr.logdir:key `$":./test/testlog";
    .tst.tmr.initlog:$[`init.log in .tst.tmr.logdir;read0 `$":./test/testlog/init.log";()];
    .tst.tmr.currentlog:$[`init.log in .tst.tmr.logdir;read0 `$":./test/testlog/current.log";()];
    };
  after{
    //system "kill -9 ", string[.tst.tmr.pid], "1>/dev/null 2>&1";    
    @[.tst.tmr.h;"exit 0";`$"closed remote process"];
    system "rm -rf test/testlog";
    // restore env. vars
    `EC_LOG_DEST setenv .tst.tmr.logdest;
    `EC_LOG_PATH setenv .tst.tmr.logpath;
    `EC_LOG_ROTATE setenv .tst.tmr.logrotate;
    };
  should["have rotated the logs"]{
    (count .tst.tmr.logdir) mustmatch 4;
    (`init.log in .tst.tmr.logdir) mustmatch 1b;
    (`current.log in .tst.tmr.logdir) mustmatch 1b;
    (last .tst.tmr.initlog)[39 + til 16] mustmatch "log continues in";
    (first .tst.tmr.currentlog)[39 + til 18] mustmatch "log continued from";
    };
  };
\
