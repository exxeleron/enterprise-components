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


system"l sl.q";
system"l pe.q";
system"l lib/qspec/qspec.q";

// Usage:   
//q test/authorization_test.q --noquit -p 5001


.sl.init[`authorization_test];
system"l event.q";
system"l authorization.q";

/------------------------------------------------------------------------------/
/                                  globals                                     /
/------------------------------------------------------------------------------/
/G/ For Unix OS set to 1b - output is redirected to files
.tst.hnd.outRed:0b;
{system"x ",x} each (".z.pg";".z.ps";".z.pc";".z.po");
/G/ Dictionary funcs to check entries in .hnd.status depends on connection state
//.tst.hnd.checkConn:()!();
/G/ Sample clients
/.tst.hnd.clients:([] server:`client1`client2;host:`localhost`localhost;port:.z.i+1024+1+til 2);

/------------------------------------------------------------------------------/
/F/ Gets connection details as (server)!(connection string).
/E/ servers:`rdb
/E/ servers:`rdb`hdb
/E/ .tst.hnd.details[servers]
.tst.hnd.details:{[servers]
  c:select from .tst.hnd.clients where server in servers;
  :c[`server]!`$":",/:":" sv/: string c[`host],'c[`port];
  };

/F/ Runs q process.
/E/ srvr:.tst.hnd.clients[`server]
/E/ srvr:.tst.hnd.clients[0;`server]
/E/ .tst.hnd.qstart[srvr]
.tst.hnd.qstart:{[srvr]
  os:.z.o;
  s:exec from .tst.hnd.clients where server=srvr;
  if[os in `w32`w64; cmd:"start q -p ",.Q.s1 s[`port]];
  if[os in `l32`s32`v32`l64`s64`v64;
    cmd:"nohup q -p ",string[s`port]," < /dev/null > test/",string[srvr],".std 2> test/",string[srvr],".err &";
    .tst.hnd.outRed:1b;
    ];
  .log.info[`tsta] "******** starting server ",(string srvr)," with command ", cmd;
  system cmd;
  if[os in `w32`w64;do[100000;100*1000%til 1000]];
  if[os in `l32`s32`v32`l64`s64`v64;system "sleep 3"]; 
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

.tst.loadLib:{[lib]
  .sl.noinit:1b;
  .sl.libpath:distinct `:.,.sl.libpath;
  @[system;"l ",string lib;0N];
  };

/------------------------------------------------------------------------------/
/                                test suits                                    /
/------------------------------------------------------------------------------/
.tst.desc["[authorization.q] initialize authorization library"]{
  before{
    {system"x ",x} each (".z.pg";".z.ps";".z.pc";".z.po");
    .tst.loadLib[`callback.q];
    .tst.mockFunc[`.log.info;2;""];
    .tst.mockFunc[`.log.debug;2;""];
    `users mock ([]users:`user1`user2; usergroups:(enlist`gr1;`gr1`gr2); userType:`technicalUser`user; pass:("pass1";"pass2"));
    };

  after{
    {system"x ",x} each (".z.pg";".z.ps";".z.pc";".z.po");
    delete status from `.cb;
    delete initialized from `.auth.p;
    };
  should["initialize auth without any adding any callbacks"]{
    `groups mock ([]usergroups:`gr1`gr2; auditView:(0#`;0#`);namespaces:(enlist `ALL;enlist `ALL);checkLevel:`NONE; stopWords:("";""));
    .auth.p.init[users;groups;`u;()];
    1b mustmatch .auth.p.initialized;
    enlist[(`auth;"Authorization and audit is turned off")] mustin .tst.trace[`.log.debug];
    mustthrow[".z.pg";{.z.pg}];
    mustthrow[".z.po";{.z.po}];
    mustthrow[".z.pc";{.z.pc}];
    mustthrow[".z.ps";{.z.ps}];
    };

  should["initialize auth with view to connections"]{
    `groups mock ([]usergroups:`gr1`gr2; auditView:(enlist `CONNECTIONS_INFO;enlist `CONNECTIONS_INFO);namespaces:(enlist `ALL;enlist `ALL);checkLevel:`NONE; stopWords:("";""));
    .auth.p.init[users;groups;`u;()];
    1b mustmatch .auth.p.initialized;
    (enlist `.auth.p.pc;enlist `.auth.p.po) mustmatch .cb.status'[`.z.pc`.z.po][`function];
    enlist[(`auth;"Turn on audit view CONNECTIONS_INFO for users:`user1`user2``",string[.z.u])] mustin .tst.trace[`.log.info];
    mustthrow[".z.pg";{.z.pg}];
    mustthrow[".z.ps";{.z.ps}];
    };
  should["initialize audit with view to sync access"]{
    `groups mock ([]usergroups:`gr1`gr2; auditView:(enlist `SYNC_ACCESS_INFO;enlist `SYNC_ACCESS_INFO);namespaces:(enlist `ALL;enlist `ALL);checkLevel:`NONE; stopWords:("";""));
    .auth.p.init[users;groups;`u;()];
    1b mustmatch .auth.p.initialized;
    (enlist `.auth.p.pg) mustmatch .cb.status'[`.z.pg][`function];
    enlist[(`auth;"Turn on audit view SYNC_ACCESS_INFO for users:`user1`user2``",string[.z.u])] mustin .tst.trace[`.log.info];
    mustthrow[".z.po";{.z.po}];
    mustthrow[".z.pc";{.z.pc}];
    mustthrow[".z.ps";{.z.ps}];
    };
  should["initialize authorization"]{
    `groups mock ([]usergroups:`gr1`gr2; auditView:(0#`;0#`);namespaces:(enlist `ALL;enlist `ALL);checkLevel:`FLEX`STRICT; stopWords:("";""));
    .auth.p.init[users;groups;`u;()];
    1b mustmatch .auth.p.initialized;
    (enlist `.auth.p.pg) mustmatch .cb.status'[`.z.pg][`function];
    enlist[(`auth;"Turn on authorization for users:`user1`user2`user2``",string[.z.u])] mustin .tst.trace[`.log.info];
    mustthrow[".z.po";{.z.po}];
    mustthrow[".z.pc";{.z.pc}];
    mustthrow[".z.ps";{.z.ps}];
    };
  should["initialize authorization and audit with view to sync access"]{
    `groups mock ([]usergroups:`gr1`gr2; auditView:(enlist `SYNC_ACCESS_INFO;enlist `SYNC_ACCESS_INFO);namespaces:(enlist `ALL;enlist `ALL);checkLevel:`FLEX`STRICT; stopWords:("";""));
    .auth.p.init[users;groups;`u;()];
    1b mustmatch .auth.p.initialized;
    (enlist `.auth.p.pg) mustmatch .cb.status'[`.z.pg][`function];
    enlist[(`auth;"Turn on authorization and audit view SYNC_ACCESS_INFO for users:`user1`user2``",string[.z.u])] mustin .tst.trace[`.log.info];
    mustthrow[".z.po";{.z.po}];
    mustthrow[".z.pc";{.z.pc}];
    mustthrow[".z.ps";{.z.ps}];
    };
  should["initialize audit with view to async access"]{
    `groups mock ([]usergroups:`gr1`gr2; auditView:(enlist `ASYNC_ACCESS_INFO;enlist `ASYNC_ACCESS_INFO);namespaces:(enlist `ALL;enlist `ALL);checkLevel:`NONE; stopWords:("";""));
    .auth.p.init[users;groups;`u;()];
    1b mustmatch .auth.p.initialized;
    (enlist `.auth.p.ps) mustmatch .cb.status'[`.z.ps][`function];
    enlist[(`auth;"Turn on audit view ASYNC_ACCESS_INFO for users:`user1`user2``",string[.z.u])] mustin .tst.trace[`.log.info];
    mustthrow[".z.pg";{.z.pg}];
    mustthrow[".z.po";{.z.po}];
    mustthrow[".z.pc";{.z.pc}];
    };
  should["initialize authorization and audit with view to all types"]{
    `groups mock ([]usergroups:`gr1`gr2; auditView:(`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO;enlist `CONNECTIONS_INFO);namespaces:(enlist `ALL;enlist `ALL);checkLevel:`FLEX`NONE; stopWords:("";""));
    .auth.p.init[users;groups;`u;()];
    1b mustmatch .auth.p.initialized;
    (enlist `.auth.p.pc;enlist `.auth.p.po;enlist `.auth.p.pg;enlist `.auth.p.ps) mustmatch .cb.status'[`.z.pc`.z.po`.z.pg`.z.ps][`function];
    enlist[(`auth;"Turn on audit view CONNECTIONS_INFO for users:`user1`user2``",string[.z.u])] mustin .tst.trace[`.log.info];
    enlist[(`auth;"Turn on audit view ASYNC_ACCESS_INFO for users:`user1`user2``",string[.z.u])] mustin .tst.trace[`.log.info];
    enlist[(`auth;"Turn on authorization and audit view SYNC_ACCESS_INFO for users:`user1`user2``",string[.z.u])] mustin .tst.trace[`.log.info];
    };
  should["display warnings"]{
    .tst.mockFunc[`.log.warn;2;""];
    `users mock ([]users:`user1`user2`user3; usergroups:(enlist`none;enlist `flex;enlist `strict); userType:`technicalUser`user`user; pass:("pass1";"pass2";"pass3"));
    `groups mock ([]usergroups:`none`flex`strict;auditView:(`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO;`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO;`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO);namespaces:(enlist `ALL;enlist `.demo;enlist `.demo);checkLevel:`NONE`FLEX`STRICT; stopWords:("";("value");("test1";"2012.01.01")));
    .auth.p.init[users;groups;`u;`SYNC`ASYNC`AUTH];
    ((`auth;"Processing of synchronous messages will be slowed down, because audit for synchronous communication is turned on.");(`auth;"Processing of asynchronous messages will be slowed down, because audit for asynchronous communication is turned on.");(`auth;"Processing of synchronous messages will be slowed down, because authorization is turned on.")) mustmatch .tst.trace[`.log.warn];
    };

  };

.tst.desc["[authorization.q] test authorization callbacks"]{
  before{
    .tst.hnd.clients::([] server:`client1`client2;host:`localhost`localhost;port:.z.i+1024+1+til 2);
    // start client server
    .tst.loadLib[`callback.q];
    .tst.hnd.qstart[`client1];
    `hndClient1 mock hopen first .tst.hnd.clients[`port];
    hndClient1"\\l sl.q";
    hndClient1"\\l pe.q";
    hndClient1"\\l callback.q";
    hndClient1"\\l authorization.q";
    hndClient1".sl.init[`client1]";
    `.test.users mock ([]users:enlist`client1; usergroups:`gr1; userType:`user; pass:enlist "222");
    `.test.groups mock ([]usergroups:enlist`gr1; auditView:enlist(); namespaces:enlist(`ALL); checkLevel:enlist`NONE; stopWords:enlist ());
    hndClient1(`.auth.p.init;.test.users;.test.groups;`;());
    };
  after{
    delete initialized from `.auth.p;
    delete status from `.cb;
    {system"x ",x} each (".z.pg";".z.ps";".z.pc";".z.po");
    };
  should["update status when port open"]{
    hndClient1".auth.status:([]user:`symbol$(); hnd:`int$(); ip:`symbol$(); host:`symbol$(); loginTs:`timestamp$());";
    hndClient1(`.auth.setAuth;flip `users`auditView`checkLevel!(enlist `client1;enlist enlist `CONNECTIONS_INFO;enlist `NONE));
    handle:hopen `$"::",string[.tst.hnd.clients[0;`port]],":client1";
    res:hndClient1".auth.status";
    1 mustmatch count res;
    1i mustmatch handle".cb.status[`.z.po][`callCount]";
    hclose hndClient1;
    .tst.hnd.qstop[.tst.hnd.clients[0;`server]];
    };
  should["update status when port close"]{
    .auth.status:([]user:`symbol$(); hnd:`int$(); ip:`symbol$(); host:`symbol$(); loginTs:`timestamp$());
    .auth.setAuth[flip `users`auditView`checkLevel!(enlist `client1;enlist enlist `CONNECTIONS_INFO;enlist `NONE)];
    hndClient1:hopen `$"::",string[.tst.hnd.clients[0;`port]],":client1";
    neg[hndClient1]"hh:hopen `::5001:client1";
    neg[hndClient1]"hclose hh";
    hclose hndClient1;
    .tst.hnd.qstop[.tst.hnd.clients[0;`server]];
    1i mustmatch .cb.status[`.z.pc][`callCount];
    0 mustmatch count .auth.status;
    };
  should["log sync access"]{
    hndClient1".auth.status:([]user:`symbol$(); hnd:`int$(); ip:`symbol$(); host:`symbol$(); loginTs:`timestamp$());";
    hndClient1".tst.log:()";
    hndClient1".log.info:{[x;y] .tst.log,:enlist enlist y}";
    hndClient1".log.warn:{[x;y] .tst.log,:enlist enlist y}";
    handle:hopen `$"::",string[.tst.hnd.clients[0;`port]],":client1";
    handle(`.auth.setAuth;flip `users`auditView`checkLevel!(enlist `client1;enlist enlist `SYNC_ACCESS_INFO;enlist `NONE));
    handle"0N!`test";
    handle"([] t:1 2)";
    @[handle;"'test";::];
    res:handle".tst.log";
    hclose hndClient1;
    .tst.hnd.qstop[.tst.hnd.clients[0;`server]];
    queryStarted:raze res[1 3 5];
    queryCompleted:raze res[2 4];
    queryFailed: res[6];
    3 mustmatch count queryStarted;
    2 mustmatch count queryCompleted;
    (-11 98h) mustmatch  queryCompleted`resType;
    (1 2) mustmatch  queryCompleted`resCount;
    1 mustmatch count queryFailed;
    };
  should["log async access"]{
    hndClient1".auth.status:([]user:`symbol$(); hnd:`int$(); ip:`symbol$(); host:`symbol$(); loginTs:`timestamp$());";
    hndClient1".tst.log:()";
    hndClient1".log.info:{[x;y] .tst.log,:enlist enlist y}";
    hndClient1".log.warn:{[x;y] .tst.log,:enlist enlist y}";
    handle:hopen `$"::",string[.tst.hnd.clients[0;`port]],":client1";
    handle(`.auth.setAuth;flip `users`auditView`checkLevel!(enlist `client1;enlist enlist `ASYNC_ACCESS_INFO;enlist `NONE));
    neg[handle]"0N!`test";    
    neg[handle]"([] t:1 2)";
    @[neg[handle];"'test";::];
    res:handle".tst.log";
    hclose handle;
    .tst.hnd.qstop[.tst.hnd.clients[0;`server]];
    queryStarted:raze res[1 3 5];
    queryCompleted:raze res[2 4];
    queryFailed: res[6];
    3 mustmatch count queryStarted;
    2 mustmatch count queryCompleted;
    (-11 98h) mustmatch  queryCompleted`resType;
    (1 2) mustmatch  queryCompleted`resCount;
    1 mustmatch count queryFailed;
    };
  };

.tst.desc["test authorization"]{
  before{
    .tst.loadLib[`callback.q];
    .tst.mockFunc[`.cr.getGroupCfgTab;2;"if[a1~`usergroups;:([]sectionVal:`",string[.z.u],"`user2`user3;section:`technicalUser`user`user;finalValue:(enlist`none;enlist `flex;enlist `strict))];if[a1~`pass;:([]sectionVal:`user1`user2`user3;finalValue:(\"pass1\";\"pass2\";\"pass3\"))]"];
    .tst.mockFunc[`.cr.isCfgFieldDefined;3;":0b"];
    .tst.mockFunc[`.cr.getCfgPivot;3;"([]sectionVal:`none`flex`strict;auditView:(0#`;0#`;0#`);namespaces:(enlist `ALL;enlist `.demo;enlist `.demo);checkLevel:`NONE`FLEX`STRICT; stopWords:(\"\";(\"value\");(\"test1\";\"2012.01.01\")))"];
    .tst.mockFunc[`.cr.getCfgField;3;":string`u"];
    `.demo.test1 mock {:(x;y)};
    `.demo.test2 mock {:(x+y)};
    `.demo1.test1 mock {x+y};
    .auth.init[];
    };

  after{
    {system"x ",x} each (".z.pg";".z.ps";".z.pc";".z.po");
    delete status from `.cb;
    delete initialized from `.auth.p;
    };
  should["test user validation"]{
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:"2+3"];
    };
  should["test command validation: admin - .ap.p.validcmd[]"]{
    // command as string
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:"value \"2+3\""];
    5 mustmatch .auth.p.pg[cmd];
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:"`"];
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:".demo.test1[1;2012.01.01]"];
    (1;2012.01.01) mustmatch .auth.p.pg[cmd];
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:".demo.test1[`test1;2012.01.01]"];
    (`test1;2012.01.01) mustmatch .auth.p.pg[cmd];
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:".demo1.test1[1;1]"];
    2 mustmatch .auth.p.pg[cmd];
    // function as string, types arguments
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:(".demo.test1";1;2012.01.01)];
    (1;2012.01.01) mustmatch .auth.p.pg[cmd];
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:(".demo.test1";`test1;2012.01.01)];
    (`test1;2012.01.01) mustmatch .auth.p.pg[cmd];
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:(".demo1.test1";1;1)];
    2 mustmatch .auth.p.pg[cmd];
    // function as symbol, types arguments
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:(`.demo.test1;1;2012.01.01)];
    (1;2012.01.01) mustmatch .auth.p.pg[cmd];
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:(`.demo.test1;`test1;2012.01.01)];
    (`test1;2012.01.01) mustmatch .auth.p.pg[cmd];
    1b mustmatch .auth.p.validcmd[u:.z.u;cmd:(`.demo1.test1;1;1)];
    2 mustmatch .auth.p.pg[cmd];
    };
  should["test command validation: strict - .ap.p.validcmd[]"]{
    // command as string
    mustthrow["unsupported query type for check level: STRICT, query: \"value \\\"2+3\\\"\"";
      {.auth.p.validcmd[u:`user3;cmd:"value \"2+3\""]}];
    mustthrow["unsupported query type for check level: STRICT, query: \"`\"";
      {.auth.p.validcmd[u:`user3;cmd:"`"]}];
    mustthrow["unsupported query type for check level: STRICT, query: \"test1\"";
      {.auth.p.validcmd[u:`user3;cmd:"test1"]}];
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(`.demo.test1;1;2012.01.01)];
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(`.demo.test1;`test1;2012.01.01)];
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(`.demo.test1;1;([]a:1 2);1)];
    / fail if there is a function call down the tree
    0b mustmatch .auth.p.validcmd[u:`user3;cmd:(`.demo.test1;1;(value;`trade);1)];
    / fail if function name not found in user2nm
    0b mustmatch .auth.p.validcmd[u:`user3;cmd:(`.demo2.test1;1;1)];
    // function as string, types arguments
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(".demo.test1";1;2012.01.01)];
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(".demo.test1";`test1;2012.01.01)];
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(".demo.test1";1;1)];
    0b mustmatch .auth.p.validcmd[u:`user3;cmd:(".demo1.test1";(value;enlist `trade);1)];
    // function as symbol, types arguments
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(`.demo.test1;1;2012.01.01)];
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(`.demo.test1;`test1;2012.01.01)];
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:(`.demo.test1;1;1)];

    1b mustmatch .auth.p.validcmd[`user3] cmd:(`.demo.test1;`a`b!1 2);
    1b mustmatch .auth.p.validcmd[`user3] cmd:(`.demo.test1;`a`b;1 2);
    1b mustmatch .auth.p.validcmd[`user3] cmd:(`.demo.test1;(enlist `a;1;2));
    0b mustmatch .auth.p.validcmd[`user3] cmd:(`.demo.test1;(`a;1;2));
    0b mustmatch .auth.p.validcmd[u:`user3;cmd:(".demo1.test1";(value;enlist `trade);1)];
    };

  should["test command validation: flex - .ap.p.validcmd[]"]{
    // command as string
    / .demo namespace, long list of stopwords
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:"value \"2+3\""];
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:"\\a"];
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:"`"];
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:"test1"];

    1b mustmatch .auth.p.validcmd[u:`user2;cmd:".demo.test1[1;2012.01.01]"];
    1b mustmatch .auth.p.validcmd[u:`user2;cmd:".demo.test1[`test1;2012.01.01]"];
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:".demo1.test1[1;1]"];
    // function as string, types arguments
    1b mustmatch .auth.p.validcmd[u:`user2;cmd:(".demo.test1";1;2012.01.01)];
    1b mustmatch .auth.p.validcmd[u:`user2;cmd:(".demo.test1";`test1;2012.01.01)];
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:(".demo1.test1";1;1)];
    // function as symbol, types arguments
    1b mustmatch .auth.p.validcmd[u:`user2;cmd:(`.demo.test1;1;2012.01.01)];
    1b mustmatch .auth.p.validcmd[u:`user2;cmd:(`.demo.test1;`test1;2012.01.01)];
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:(`.demo1.test1;1;1)];
    };
  };

.tst.desc["test different levels of command checks - .ap.p.validcmd[]"]{
  before{
    .tst.loadLib[`callback.q];
    .tst.mockFunc[`.cr.getGroupCfgTab;2;"if[a1~`usergroups;:([]sectionVal:`",string[.z.u],"`user2`user3;section:`technicalUser`user`user;finalValue:(enlist`none;enlist `flex;enlist `flex2))];if[a1~`pass;:([]sectionVal:`user1`user2`user3;finalValue:(\"pass1\";\"pass2\";\"pass3\"))]"];
    .tst.mockFunc[`.cr.isCfgFieldDefined;3;":0b"];
    .tst.mockFunc[`.cr.getCfgPivot;3;"([]sectionVal:`none`flex`flex2;auditView:(0#`;0#`;0#`);namespaces:(enlist `ALL;enlist `ALL;enlist `.demo);checkLevel:`NONE`FLEX`FLEX; stopWords:(\"\";(\"test1\";\"2012.01.01\");(\"delete\")))"];
    .tst.mockFunc[`.cr.getCfgField;3;":string`u"];
    `.demo.test1 mock {:(x;y)};
    `.demo.test2 mock {:(x+y)};
    `.demo1.test1 mock {x+y};
    .auth.init[];
    };
  after{
    {system"x ",x} each (".z.pg";".z.ps";".z.pc";".z.po");
    delete status from `.cb;
    delete initialized from `.auth.p;
    };
  should["block calls with stopwords and functions defined (full)"]{
    /not permitted to use use function from other namespace
    0b mustmatch .auth.p.validcmd[u:`user3;cmd:".demo.test1[.demo1.test1[0]]"];
    /stopword in the query
    0b mustmatch .auth.p.validcmd[u:`user3;cmd:".demo.test1[delete from trade]"];
    1b mustmatch .auth.p.validcmd[u:`user3;cmd:".demo.test1[]"];
    /not permitted to use function that is a stop word
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:".demo.test1[test1[0]]"];
    /not permitted to use function argument that is a stop word
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:".demo.test1[test1]"];
    /multiline statements are permitted
    1b mustmatch .auth.p.validcmd[u:`user2;cmd:"a:1+1;select from trade where date=.z.d-1"];
    1b mustmatch .auth.p.validcmd[u:`user2;cmd:"a"];
    1b mustmatch .auth.p.validcmd[u:`user2;cmd:"2+2"];
    0b mustmatch .auth.p.validcmd[u:`user2;cmd:"2+test1"];
    };
  };

.tst.desc["test authorization and audit at the same time"]{
  before{
    .tst.loadLib[`callback.q];
    .tst.hnd.clients:([] server:`client1`client2;host:`localhost`localhost;port:.z.i+1024+1+til 2);
    // start client server
    .tst.hnd.qstart[`client1];
    `hndClient1 mock hopen `$"::",string[first .tst.hnd.clients[`port]],":user1";
    hndClient1"\\l sl.q";
    hndClient1"\\l pe.q";
    hndClient1"\\l callback.q";
    hndClient1"\\l authorization.q";
    hndClient1".sl.init[`client1]";
    .tst.mockFunc[`.cr.getGroupCfgTab;2;"if[a1~`usergroups;:([]sectionVal:`user1`user2`user3;section:`technicalUser`user`user;finalValue:(enlist`none;enlist `flex;enlist `strict))];if[a1~`pass;:([]sectionVal:`user1`user2`user3;finalValue:(\"pass1\";\"pass2\";\"pass3\"))]"];
    .tst.mockFunc[`.cr.isCfgFieldDefined;3;":0b"];
    .tst.mockFunc[`.cr.getCfgPivot;3;"([]sectionVal:`none`flex`strict;auditView:(`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO;`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO;`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO);namespaces:(enlist `ALL;enlist `.demo;enlist `.demo);checkLevel:`NONE`FLEX`STRICT; stopWords:(\"\";(\"value\");(\"test1\";\"2012.01.01\")))"];
    .tst.mockFunc[`.cr.getCfgField;3;":string`u"]; 
    hndClient1".demo.test1:{:(x;y)}";
    hndClient1".demo.test2:{:(x+y)}";
    hndClient1".demo1.test1:{x+y}";
    .demo.test1:{:(x;y)};.demo.test2:{:(x+y)};.demo1.test1:{x+y};
    .auth.init[];
    };
  after{
    {system"x ",x} each (".z.pg";".z.ps";".z.pc";".z.po");
    delete status from `.cb;
    delete initialized from `.auth.p;
    };
  should["log all audit views"]{
    hndClient1".auth.status:([]user:`symbol$(); hnd:`int$(); ip:`symbol$(); host:`symbol$(); loginTs:`timestamp$());";
    hndClient1(set;`.auth.cfg.tab;.auth.cfg.tab);
    hndClient1(`.auth.setAuth;.auth.cfg.tab);
    hndClient1".auth.stopWords:`$exec users!stopWords from  .auth.cfg.tab";
    hndClient1".auth.checkLevels:exec users!checkLevel from  .auth.cfg.tab";
    hndClient1".auth.updateAuthFunctions[]";
    //hndClient1".auth.cfg.tab"
    hndClient1".tst.log:()";
    hndClient1".log.info:{[x;y] .tst.log,:enlist enlist y}";
    hndClient1".log.warn:{[x;y] .tst.log,:enlist enlist y}";
    // open conn
    `hnduser1 mock hopen `$"::",string[first .tst.hnd.clients[`port]],":user1";
    `hnduser2 mock hopen `$"::",string[first .tst.hnd.clients[`port]],":user2";
    `hnduser3 mock hopen `$"::",string[first .tst.hnd.clients[`port]],":user3";
    res:hndClient1".auth.status";
    `user1`user2`user3 mustmatch res`user;
    // sync queries
    5 mustmatch hnduser1"2+3";
    mustthrow["access denied";{hnduser2(`.demo1.test1;2;3)}];
    5 mustmatch hnduser2(`.demo.test2;2;3);
    mustthrow["access denied";{hnduser3(`.demo1.test1;2;3)}];
    5 mustmatch hnduser3(`.demo.test2;2;3);
    hclose hndClient1;
    .tst.hnd.qstop[.tst.hnd.clients[0;`server]];
    };
  };

//.tst.report
