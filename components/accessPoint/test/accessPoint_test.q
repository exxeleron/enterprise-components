// q test/accessPoint_test.q --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q
.sl.init[`test];

.tst.desc["test initialization"]{
  before{
    .sl.noinit:1b;
    system["l accessPoint.q"];
    .ap.cfg.timeout:100i;
    .ap.cfg.serverAux:`test;
    .tst.mockFunc[`.hnd.hopen;3;""];
    .tst.mockFunc[`.auth.init;0;""];
    .auth.cfg.tab:flip `users`usergroups`pass`auditView`namespaces`checkLevel`stopWords`functions`validNm!(`user1`user2`user3;`none`flex`strict;("pass1";"pass2";"pass3");(`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO;`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO;`CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO);(enlist `ALL;enlist `.demo;enlist `.demo);`NONE`FLEX`STRICT;("";"value";("test1";"2012.01.01"));(enlist `ALL;`.demo.test1`.demo.test2;`.demo.test1`.demo.test2);({[x;y]1b}[enlist `ALL;];{[x;y]y in x}[`.demo.test1`.demo.test2;];{[x;y]y in x}[`.demo.test1`.demo.test2;]));
    .ap.p.init[];
    };
  after{
    .cb.reset[`.z.pg];
    };
  should["open aux conns"]{
    enlist[(`test;100i;`lazy)] mustmatch .tst.trace[`.hnd.hopen];
    };
  should["init authorization"]{
    enlist[()] mustmatch .tst.trace[`.auth.init];
    };
  
  };


