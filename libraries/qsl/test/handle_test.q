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
//q test/handle_test.q --noquit -p 5001
// TODO: does work on Windows due to "sleep" function 

system "l lib/qspec/qspec.q";
system "l sl.q"; // loads handle
system "l pe.q";

.sl.init[`handle_test];
system "l timer.q";
system "l handle.q";
system "l callback.q";
/------------------------------------------------------------------------------/
/                                  globals                                     /
/------------------------------------------------------------------------------/
/G/ For Unix OS set to 1b - output is redirected to files
.tst.hnd.outRed:0b;
/G/ Dictionary funcs to check entries in .hnd.status depends on connection state
//.tst.hnd.checkConn:()!();
/G/ Sample clients
/.tst.hnd.clients:([] server:`rdb.rdb1`hdb;host:`localhost`localhost;port:.z.i+1024+1+til 2);

/------------------------------------------------------------------------------/
// Some clients parameters
//`.tst.hnd.clients insert (`rdb`hdb;`localhost`localhost;value["\\p"]+1+til 2);

/------------------------------------------------------------------------------/
/                               helper functions                               /
/------------------------------------------------------------------------------/

/F/ Function run on port open
.tst.hnd.Fun1: {[s] .tst.hnd.Fun1Run+:1i;};
.tst.hnd.Fun2: {[s] .tst.hnd.Fun2Run+:1i;};


/F/ Gets connection details as (server)!(connection string).
/E/ servers:`rdb
/E/ servers:`rdb`hdb
/E/ .tst.hnd.details[servers]
.tst.hnd.details:{[servers]
  c:select from .tst.hnd.clients where server in servers;
  :c[`server]!`$":",/:":" sv/: string c[`host],'c[`port];
  };

/------------------------------------------------------------------------------/
/F/ Runs q process.
/E/ srvr:.tst.hnd.clients[`server]
/E/ srvr:.tst.hnd.clients[0;`server]
/E/ .tst.handle.qstart[srvr]
.tst.handle.qstart:{[srvr]
  os:.z.o;
  s:exec from .tst.hnd.clients where server=srvr;
  if[os in `w32`w64; cmd:"start q -p ",.Q.s1 s[`port]];
  if[os in `l32`s32`v32`l64`s64`v64;
    cmd:"nohup q -p ",string[s`port]," < /dev/null > test/",string[srvr],".std 2> test/",string[srvr],".err &";
    .tst.hnd.outRed:1b;
    ];
  .log.info[`tsth] "starting process with ",cmd;
  system cmd;
  system "sleep 2" 
  };

/F/ starts a q process on the specified port and executes a script
/P/ offset:INT - the process is started at the offset from te current port
/P/ script:STRING - the name of script, without the q extension
/R/ :HANDLE - a handle to the running q process
.tst.hnd.exect:{[offset;script]
  port:.z.i+1024;
  .log.info[`test] "starting process at port ",(string port+offset);
  if[.z.o in `w32`w64; system "start q -p ",(string port+offset)];
  if[.z.o in `l32`s32`v32`l64`s64`v64;system "q -p ",(string port+offset)];
  system "sleep 2"; // to give time to start
  h:hopen `$":localhost:",string offset+port;
  .log.info[`test] "loading script ",script,".q"," on remote process";
  h "system\"l ",script,".q\"";
  :h
  };

/------------------------------------------------------------------------------/
/F/ Stops q process.
/E/ srvr:.tst.hnd.clients[`server]
/E/ srvr:.tst.hnd.clients[0;`server]
/E/ .tst.hnd.qstop[srvr]
.tst.hnd.qstop:{[srvr]
  s:exec from .tst.hnd.clients where server=srvr;
  h:@[hopen;`$":",":" sv string s[`host],s[`port];{}];
  if[0N~h;
    .log.info[`handT] "Cannot connect to port ",string[s `port],".";
    :()];
  // Stop process and for UNIX OS remove all .err and .std files
  @[{x "exit 0"};h;0N];
  // if[.tst.hnd.outRed; TODO: make it work on Linux
    //  @[hdel each;`$raze each string (`:,srvr),/:(`.err;`.std);'"ERROR: Could not remove output files:",.Q.s1 srvr];
    //  ];
  };

/------------------------------------------------------------------------------/
/                                test suits                                    /
/------------------------------------------------------------------------------/
.tst.desc["[handle.q] Setup connection in lazy mode"]{
  before{
    .hnd.reset[];
    .log.info[`test] "starting Setup connection in lazy mode test";
    .tst.hnd.clients:([] server:`rdb.rdb1`hdb.hdb1;host:`localhost`localhost;port:.z.i+512+til 2);
    .tst.handle.qstart[`rdb.rdb1];
    .tst.hnd.Fun1Run:.tst.hnd.Fun2Run:0i;
    .hnd.poAdd[`rdb.rdb1;`.tst.hnd.Fun1];
    .hnd.poAdd[`hdb.hdb1;`.tst.hnd.Fun2];
    .tst.hnd.servers:.tst.hnd.details[`rdb.rdb1`hdb.hdb1];
    .hnd.hopen[.tst.hnd.servers;1000i;`lazy];
    };
  after{
    .tst.hnd.qstop[`rdb.rdb1];
    .hnd.reset[];
    };
  should["open connections on the first request, throw and start reconnecting on access to non running server"]{
    (key .tst.hnd.servers) mustmatch 1_exec server from .hnd.status;
    (2#`registered) mustmatch 1_exec state from .hnd.status;
    0 mustmatch count .tmr.status;
    .tst.hnd.Fun1Run mustmatch 0i;
    4j mustmatch .hnd.h[`rdb.rdb1] "2j+2j";
    .tst.hnd.Fun1Run mustmatch 1i;
    .tst.hnd.Fun2Run mustmatch 0i;
    `open mustmatch .hnd.status[`rdb.rdb1;`state];
    0N mustmatch @[{.hnd.h[`hdb.hdb1] x};"2+2";0N];  
    .tst.hnd.Fun2Run mustmatch 0i;
    `failed mustmatch .hnd.status[`hdb.hdb1;`state];
    1 mustmatch count .tmr.status;
    };
  };

.tst.desc["[handle.q] Setup connection in eager mode"]{
  before{
    .log.info[`test] "starting Setup connection in eager mode test";
    .log.info[`test] "count .hnd.status before starting `rdb.rdb1", string count .hnd.status;
    .tst.hnd.Fun1Run:.tst.hnd.Fun2Run:0i;
    .hnd.poAdd[`rdb.rdb1;`.tst.hnd.Fun1];
    .hnd.poAdd[`hdb.hdb1;`.tst.hnd.Fun2];
    .tst.handle.qstart[`rdb.rdb1];
    .log.info[`test] "count .hnd.status after starting `rdb.rdb1", string count .hnd.status;
    .tst.hnd.servers:.tst.hnd.details[`rdb.rdb1`hdb.hdb1];
    .hnd.hopen[.tst.hnd.servers;1000i;`eager];
    };
  after{
    .tst.hnd.qstop[`rdb.rdb1];
    .hnd.reset[];
    };
  should["be connected to the running server and fail on non-running, throw on access to non running server"]{
    (key .tst.hnd.servers) mustmatch 1_exec server from .hnd.status;
    (`open`failed) mustmatch 1_exec state from .hnd.status;
    1 mustmatch count .tmr.status;
    .tst.hnd.Fun1Run mustmatch 1i;
    .tst.hnd.Fun2Run mustmatch 0i;
    4 mustmatch .hnd.h[`rdb.rdb1] "2+2";
    0N mustmatch @[{.hnd.h[`hdb.hdb1] x};"2+2";0N];
    `failed mustmatch .hnd.status[`hdb.hdb1;`state];
    1 mustmatch count .tmr.status;
    .tst.hnd.Fun2Run mustmatch 0i;
    };
  };  
.tst.desc["[handle.q] Testing port close"]{
  before{
    .log.info[`test] "starting Testing port close test";
    .tst.hnd.clients:([] server:`rdb.rdb1`hdb.hdb1;host:`localhost`localhost;port:.z.i+512+til 2);
    .tst.handle.qstart each `hdb.hdb1`rdb.rdb1;
    .tst.hnd.Fun1Run:.tst.hnd.Fun2Run:0i;
    .hnd.pcAdd[`rdb.rdb1;`.tst.hnd.Fun1];
    .hnd.pcAdd[`hdb.hdb1;`.tst.hnd.Fun2];
    .hnd.hopen[.tst.hnd.details[`rdb.rdb1`hdb.hdb1];1000i;`eager];
    .z.pc[.hnd.status[`rdb.rdb1;`handle]]; // simulate lost connection
    };
  after{
    .tst.hnd.qstop each `hdb.hdb1`rdb.rdb1;
    .hnd.reset[];
    .hnd.reset[]; // to test if we can call reset again
    };
  should["Call port close functions"]{
    .tst.hnd.Fun1Run mustmatch 1i;
    .tst.hnd.Fun2Run mustmatch 0i;
    };
  };


.tst.desc["[handle.q] Testing reconnect"]{
  // start a q server
  before{
    .log.info[`test] "starting reconnect test";
    .tst.hnd.clients::([] server:`rdb.rdb1`hdb.hdb1;host:`localhost`localhost;port:.z.i+512+til 2);
    `.tst.hnd.h1 mock .tst.hnd.exect[2;"test/ext/handle_test_aux1"];
    `.tst.hnd.pid mock .tst.hnd.h1 `.z.i;
    .tst.handle.qstart[`rdb.rdb1];
    .tst.hnd.h1".hnd.hopen[enlist[`rdb]!enlist `::",string[.z.i+512],";1000i;`eager]";
    .tst.hndStatus1:.tst.hnd.h1".hnd.status[`rdb;`state]";
    .tst.hnd.qstop[`rdb.rdb1];
    system "sleep 2";
    .tst.hndStatus2:.tst.hnd.h1".hnd.status[`rdb;`state]";
    .tst.handle.qstart[`rdb.rdb1];
    system "sleep 3";
    .tst.hndStatus3:.tst.hnd.h1".hnd.status[`rdb;`state]";
    };
  after{
    @[.tst.hnd.h1;"exit 0";`$"closed remote process"];
    .tst.hnd.qstop[`rdb.rdb1];
    };
  should["reconnect"]{
    .tst.hndStatus1 mustmatch `open; // should connect succesfully
    .tst.hndStatus2 mustmatch `lost; // detect lost connection
    .tst.hndStatus3 mustmatch `open; // reconnect
    };
  };
