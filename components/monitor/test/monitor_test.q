// q test/monitor_test.q --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q
.sl.init[`test];

//----------------------------------------------------------------------------//
.tst.loadLib:{[lib]
  .sl.noinit:1b;
  .sl.libpath:`:.,.sl.libpath;
  @[system;"l ",string lib;0N];
  };

//----------------------------------------------------------------------------//
.tst.desc["test monitor initialization"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    `.monitor.cfg.procMaskList mock `kdb`admin;
    `.monitor.cfg.jrn mock `:test/tmp/jrn;
    `.monitor.cfg.eventDir mock `:test/tmp/events;
    `.monitor.cfg.monitorStatusPublishing mock 0b;

    `.monitor.cfg.schedule set `sysEvent`sysStatus`sysConnStatus!1000 1000 2000i;
    //min .monitor.cfg.schedule[`sysStatus`sysResUsageFromQ];
    `.monitor.cfg.yakCheckInterval mock 1000;
    //min .monitor.cfg.schedule[`sysConnStatus`sysLogStatus`sysResUsageFromQ];
    `.monitor.cfg.checksInterval mock 1000;
    `.monitor.cfg.diskCheckInterval mock 2000;

    `.monitor.cfg.sysHdbSummaryProcList mock `hdb1`hdb2;
    `.monitor.cfg.sysHdbStatsProcList mock `hdb1`hdb2;
    `.monitor.cfg.sysFuncSummaryProcList mock `gw1`gw2;
    `.monitor.cfg.sysFuncSummaryProcNs mock `.ns`.ns2;
    //exec sectionVal!finalValue from .cr.getCfgTab[`THIS;`sysTable;`execTime];
    //TODO: test dailyExecTimes
    //.tmr.startAt'[value .monitor.cfg.dailyExecTimes;` sv/:`.monitor.p.dailyExec,/:key .monitor.cfg.dailyExecTimes;24*60*60*1000j;key .monitor.cfg.dailyExecTimes];
    `.monitor.cfg.dailyExecTimes mock `sysFuncSummary`sysHdbStats!03:00:00.000 03:00:00.000;
    };
  after{
    .tst.rm[`:test/tmp];
    system"t 0";
    };
  should["init journal - .monitor.p.initJrn[]"]{
    .monitor.p.initJrn 2012.01.01;
    .u.L mustmatch `:test/tmp/jrn2012.01.01;
    .u.L mustmatch .monitor.p.jrn;
    .u.L mustmatch key .u.L;
    .u.i mustmatch 0j;
    .monitor.p.jrnH enlist (`test;1);
    .monitor.p.jrnH enlist (`test;2);
    ((`test;1j);(`test;2j)) mustmatch get .u.L;
    if[.monitor.p.jrnH;hclose .monitor.p.jrnH;.monitor.p.jrnH:0;];

    .monitor.p.initJrn 2012.01.01;
    .u.L mustmatch `:test/tmp/jrn2012.01.01;
    .u.L mustmatch .monitor.p.jrn;
    .u.L mustmatch key .u.L;
    .u.i mustmatch 2j;
    if[.monitor.p.jrnH;hclose .monitor.p.jrnH;.monitor.p.jrnH:0;];
    };
  should["init timers - .monitor.p.initTimers[]"]{
    .monitor.p.initTimers[];
    (`.monitor.p.tsCheck`.monitor.p.yakTs`.monitor.p.tsEventsRead`.monitor.p.diskTs!1000 1000 1000 2000i) mustmatch exec fun!periodms from .tmr.status;
    };
  should["init request id - .monitor.p.initRequestId[]"]{
    .monitor.p.initRequestId[];
    -7h mustmatch type .monitor.p.lastReqId;
    };
  should["init mrvs - .monitor.p.initMrvs[]"]{
    .monitor.p.initMrvs[];
    tables[] mustmatch key .mrvs;
    enlist[0] mustmatch distinct count each value .mrvs;
    };
  should["perform eod - .monitor.p.tsCheck[]"]{
    `.monitor.cfg.monitorStatusPublishing mock 0b;
    `.monitor.p.date mock .z.d-1;
    .tst.mockFunc[`.monitor.p.initJrn;1;""];
    .tst.mockFunc[`.u.end;1;""];
    .monitor.p.tsCheck[];
    (.z.d) mustmatch last .tst.trace[`.monitor.p.initJrn];
    (.z.d-1) mustmatch last .tst.trace[`.u.end];
    };
  };

//----------------------------------------------------------------------------//
.tst.desc["test yak status handling - .monitor.p.yakTs[]"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    .tst.mockFunc[`.q.system;1;"yak.mock"];
    .tst.mockFunc[`.monitor.p.addProcesses;1;""];
    .tst.mockFunc[`.monitor.p.removeProcesses;1;""];

    .tst.mockFunc[`.monitor.pub;2;""];


    `.monitor.cfg.procMaskList mock `ALL;
    //first two processes running in yak
    yak.mock:();
    yak.mock,:"uid,pid,port,executed_cmd,status,started,started_by,stopped,cpu_user,cpu_sys,cpu_usage,mem_rss,mem_vms,mem_usage\n";
    yak.mock,:"access.ap,3045,9040,q accessPoint.q -lib demolib/apPlugin query/query -w 5000 -p 9040 -U /home/kdb/devSystem/data/shared/security/access.ap.txt,RUNNING,2013.02.13 10:37:30,user,,2.47,1.33,0.0,,83456,0.323\n";
    yak.mock,:"access.ap2,3048,9039,q accessPoint.q -lib demolib/apPlugin query/query -w 5000 -p 9039 -U /home/kdb/devSystem/data/shared/security/access.ap2.txt,RUNNING,2013.02.13 10:37:30,user,,2.39,1.15,0.0,,83456,0.331\n";
    };
  after{
    };
  should["add two initial processes from yak"]{
    `.hnd.status mock ([]server:`symbol$(); state:`symbol$());
    .monitor.p.yakTs[.z.t];
    meta[sysResUsageFromOs] mustmatch meta[((!). flip .tst.trace[`.monitor.pub])[`sysResUsageFromOs]];

    ([]sym:`access.ap`access.ap2;cpuUser:2.47 2.39;cpuSys:1.33 1.15;cpuUsage:0.0 0.0f;memRss:0n 0n;memVms:83456 83456j;memUsage:0.323 0.331) mustmatch delete time from ((!). flip .tst.trace[`.monitor.pub])[`sysResUsageFromOs];

    meta[sysStatus] mustmatch meta[((!). flip .tst.trace[`.monitor.pub])[`sysStatus]];
    ([]sym:`access.ap`access.ap2;pid:3045 3048i;port:9040 9039i;
      command:`$("q accessPoint.q -lib demolib/apPlugin query/query -w 5000 -p 9040 -U /home/kdb/devSystem/data/shared/security/access.ap.txt";
        "q accessPoint.q -lib demolib/apPlugin query/query -w 5000 -p 9039 -U /home/kdb/devSystem/data/shared/security/access.ap2.txt");
      status:`RUNNING`RUNNING;started:2013.02.13T10:37:30.000 2013.02.13T10:37:30.000;startedBy:`user`user;stopped:0N 0Nz) mustmatch delete time from ((!). flip .tst.trace[`.monitor.pub])[`sysStatus];

    .tst.trace[`.monitor.p.addProcesses] mustmatch enlist[`access.ap`access.ap2];
    .tst.trace[`.monitor.p.removeProcesses] mustmatch ();
    };
  should["add two additional processes from yak"]{
    `.hnd.status mock ([]server:`access.ap`access.ap2; state:`open);
    yak.mock,:"core.hdb,28992,9031,q hdb.q -w 5000 -p 9031 -U /home/kdb/devSystem/data/shared/security/core.hdb.txt,RUNNING,2013.02.13 10:49:52,user,,2.11,1.04,0.0,,83456,0.377\n";
    yak.mock,:"core.rdb,28990,9030,q rdb.q -w 90000 -p 9030 -U /home/kdb/devSystem/data/shared/security/core.rdb.txt,RUNNING,2013.02.13 10:49:52,user,,36.4,30.2,0.0,,345600,7.29\n";

    .monitor.p.yakTs[.z.t];
    `access.ap`access.ap2`core.hdb`core.rdb mustmatch exec sym from ((!). flip .tst.trace[`.monitor.pub])[`sysResUsageFromOs];
    `access.ap`access.ap2`core.hdb`core.rdb mustmatch exec sym from ((!). flip .tst.trace[`.monitor.pub])[`sysStatus];

    .tst.trace[`.monitor.p.addProcesses] mustmatch enlist[`core.hdb`core.rdb];
    .tst.trace[`.monitor.p.removeProcesses] mustmatch ();
    };
  should["react on stopping of one of the processes from yak"]{
    `.hnd.status mock ([]server:`access.ap`access.ap2; state:`open`open);
    yak.mock:();
    yak.mock,:"uid,pid,port,executed_cmd,status,started,started_by,stopped,cpu_user,cpu_sys,cpu_usage,mem_rss,mem_vms,mem_usage\n";
    yak.mock,:"access.ap,3045,9040,q accessPoint.q -lib demolib/apPlugin query/query -w 5000 -p 9040 -U /home/kdb/devSystem/data/shared/security/access.ap.txt,RUNNING,2013.02.13 10:37:30,user,,2.47,1.33,0.0,,83456,0.323\n";
    yak.mock,:"access.ap2,3048,9039,q accessPoint.q -lib demolib/apPlugin query/query -w 5000 -p 9039 -U /home/kdb/devSystem/data/shared/security/access.ap2.txt,STOPPED,2013.02.13 10:37:30,user,,2.39,1.15,0.0,,83456,0.331\n";

    .monitor.p.yakTs[.z.t];

    `access.ap`access.ap2 mustmatch exec sym from ((!). flip .tst.trace[`.monitor.pub])[`sysResUsageFromOs];
    `access.ap`access.ap2 mustmatch exec sym from ((!). flip .tst.trace[`.monitor.pub])[`sysStatus];
    .tst.trace[`.monitor.p.addProcesses] mustmatch ();
    .tst.trace[`.monitor.p.removeProcesses] mustmatch enlist[enlist`access.ap2];
    };
  should["limit monitored processes to `access.ap`core.rdb"]{
    `.monitor.cfg.procMaskList mock `access.ap`core.rdb;
    yak.mock:();
    yak.mock,:"uid,pid,port,executed_cmd,status,started,started_by,stopped,cpu_user,cpu_sys,cpu_usage,mem_rss,mem_vms,mem_usage\n";
    yak.mock,:"access.ap,3045,9040,q accessPoint.q -lib demolib/apPlugin query/query -w 5000 -p 9040 -U /home/kdb/devSystem/data/shared/security/access.ap.txt,RUNNING,2013.02.13 10:37:30,user,,2.47,1.33,0.0,,83456,0.323\n";

    .monitor.p.yakTs[.z.t];

    enlist[`access.ap] mustmatch exec sym from ((!). flip .tst.trace[`.monitor.pub])[`sysResUsageFromOs];
    enlist[`access.ap] mustmatch exec sym from ((!). flip .tst.trace[`.monitor.pub])[`sysStatus];
    .tst.trace[`.monitor.p.addProcesses] mustmatch enlist[enlist`access.ap];
    .tst.trace[`.monitor.p.removeProcesses] mustmatch ();
    };
  };

//----------------------------------------------------------------------------//
.tst.desc["test adding/removing monitored processes"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    .tst.mockFunc[`.monitor.pub;2;""];
    `.monitor.status mock 0#.monitor.status;
    `.monitor.cfg.monitorStatusPublishing mock 1b;
    .tst.mockFunc[`.hnd.hopen;3;""];
    };
  after{
    };
  should["add new process to monitoring list without sysMonitorStatus publishing - .monitor.p.addProcesses[]"]{
    `.monitor.cfg.monitorStatusPublishing mock 0b;

    .monitor.p.addProcesses `core.rdb;

    .tst.trace[`.hnd.hopen] mustmatch enlist(`core.rdb;10i;`eager);
    enlist[0Wp] mustmatch distinct exec ts0_req from .monitor.status;
    1b mustmatch all null exec (ts1_befExec, ts2_afterExec, ts3_res) from .monitor.status;
    ([]sym:`core.rdb;request:`base`sysResUsageFromQ`sysLogStatus`sysConnStatus`sysQueues;check:`proc`memState`logHist`hndStatus`tcpQueue)
    mustmatch select sym, request, check from .monitor.status;
    .tst.trace[`.monitor.pub] mustmatch ();

    .cb.status[`.hnd.po.core_rdb][`function] mustmatch enlist`.monitor.p.po;
    .cb.status[`.hnd.pc.core_rdb][`function] mustmatch enlist`.monitor.p.pc;
    };
  should["add new process to monitoring list - .monitor.p.addProcesses[]"]{
    .monitor.p.addProcesses `core.rdb;

    .tst.trace[`.hnd.hopen] mustmatch enlist(`core.rdb;10i;`eager);
    ((!). flip .tst.trace[`.monitor.pub])[`sysMonitorStatus] mustmatch .monitor.status;
    };
  should["receive new connection - .monitor.p.po[]"]{
    `.hnd.status mock ([server:enlist `core.rdb] state:enlist `open);
    .monitor.p.addProcesses `core.rdb;
    .monitor.p.po`core.rdb;
    ([]sym:enlist `core.rdb; hndStatus:enlist`open) mustmatch distinct select sym, hndStatus from .monitor.status;
    ((!). flip reverse .tst.trace[`.monitor.pub])[`sysMonitorStatus] mustmatch .monitor.status;
    };

  should["remove process from monitoring list - .monitor.p.removeProcesses[]"]{
    `.hnd.status mock ([server:enlist `core.rdb] state:enlist `open);
    .monitor.p.addProcesses `core.rdb;
    .monitor.p.removeProcesses`core.rdb;
    ([]sym:enlist `core.rdb;pid:enlist 0Ni;port:enlist 0Ni;command:enlist `;status:enlist `;started:enlist 0Nz;startedBy:enlist `;stopped:enlist 0Nz) mustmatch delete time from ((!). flip .tst.trace[`.monitor.pub])[`sysStatus];
    ([]sym:enlist `core.rdb;connRegistered:enlist`;connOpen:enlist`;connClosed:enlist`;connLost:enlist`;connFailed:enlist`) mustmatch delete time from ((!). flip .tst.trace[`.monitor.pub])[`sysConnStatus];
    };
  should["loose connection - .monitor.p.pc[]"]{
    `.hnd.status mock ([server:enlist `core.rdb] state:enlist `closed);
    .monitor.p.addProcesses `core.rdb;
    .monitor.p.removeProcesses`core.rdb;
    .monitor.p.pc`core.rdb;
    ([]sym:enlist `core.rdb; hndStatus:enlist`closed) mustmatch distinct select sym, hndStatus from .monitor.status;
    ((!). flip reverse .tst.trace[`.monitor.pub])[`sysMonitorStatus] mustmatch .monitor.status;
    };
  };

//----------------------------------------------------------------------------//
.tst.desc["test polling"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    //    `.monitor.cfg.jrn mock `:test/tmp/jrn; 
    `.monitor.cfg.monitorStatusPublishing mock 0b;
    `.monitor.p.date mock .z.d;
    `.hnd.status mock ([server:enlist `core.rdb] state:enlist `open);
    .tst.mockFunc[`.hnd.hopen;3;""];
    .monitor.p.addProcesses `core.rdb;
    .monitor.p.po`core.rdb;
    };
  after{
    //    .monitor.p.removeProcesses`core.rdb;
    //    .monitor.p.pc`core.rdb;

    .tst.rm[`:test/tmp];
    system"t 0";
    };
  should["send two new requests - .monitor.p.tsCheck[]"]{
    .tst.mockFunc[`.monitor.p.sendReq;2;"`reqSent"]
    .monitor.p.lastReqId mustmatch 0j;
    .monitor.p.tsCheck[];
    
    //.monitor.status -> updated time, ts0_req, status, requestId
    0 mustmatch count select from .monitor.status where status=`reqFailed;
    sent:select from .monitor.status where status=`reqSent;
    sent mustmatch select from .monitor.status where (interval>0) or (request=`base);
    2 mustmatch count sent;
    (`second$sent`time) musteq' `second$sent`ts0_req;
    til[2] mustmatch sent`requestId;

    //.monitor.p.lastReqId -> increased
    .monitor.p.lastReqId mustmatch 2j;

    //send .monitor.p.sendReq[] to one server - core.rdb
    1 mustmatch count .tst.trace[`.monitor.p.sendReq];
    first[.tst.trace[`.monitor.p.sendReq]][0] mustmatch `core.rdb;
    til[2] mustmatch key first[.tst.trace[`.monitor.p.sendReq]][1];
    //publish sysMonitorStatus
    };
  should["send requests - .monitor.p.sendReq[]"]{
    `.hnd.ah mock {[x;y]`.tmp.hnd mock (x;y)};
    res:.monitor.p.sendReq[`core.rdb; 7 8!("test1";"test2")];
    res mustmatch `reqSent;
    .tmp.hnd[0] mustmatch `core.rdb;
    .tmp.hnd[1;0] mustmatch "{[codeList](neg .z.w)res:(`.monitor.response;.sl.zp[];@[value;;{(`signal;x)}]each codeList;.sl.zp[])}";
    .tmp.hnd[1;1] mustmatch 7 8j!("test1";"test2");
    };
  };

//----------------------------------------------------------------------------//
.tst.desc["test handling asynch polling responses - .monitor.response"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    `.monitor.cfg.monitorStatusPublishing mock 0b;
    `.monitor.p.date mock .z.d;
    `.hnd.status mock ([server:enlist `core.rdb] state:enlist `open; handle:.z.w);
    .tst.mockFunc[`.hnd.hopen;3;""];
    .monitor.p.addProcesses `core.rdb;
    .monitor.p.po`core.rdb;

    `.monitor.status mock ([]sym:`core.rdb`core.rdb`core.rdb; state:`open; handle:.z.w; request:`testReq; check:`check1`check2`check3; requestId:14 15 16);
    };
  after{
    };
  should["handle asynch messages which are not a monitor-response - .monitor.response"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .tst.mockFunc[`.monitor.p.publishResult;2;""];
    `res mock (mock;`.tmp.test;12);
    value res;
    .tst.trace[`.monitor.p.publishResult] mustmatch ();
    .tst.trace[`.monitor.pub] mustmatch ();
    12j mustmatch .tmp.test;
    };
  should["handle monitor-reponse without signals - .monitor.response[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .tst.mockFunc[`.monitor.p.publishResult;2;""];
    `res mock (`.monitor.response;2012.01.01D12:00:01.000000;14 15 16!((`res1);(`res2);(`res3));2012.01.01D12:00:05.000000);
    value res;
    .tst.trace[`.monitor.p.publishResult] mustmatch enlist (`core.rdb;`testReq.check1`testReq.check2`testReq.check3!`res1`res2`res3);
    .tst.trace[`.monitor.pub] mustmatch ();
    };
  should["handle monitor-reponse with signals - .monitor.response[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .tst.mockFunc[`.monitor.p.publishResult;2;""];
    `res mock (`.monitor.response;2012.01.01D12:00:01.000000;14 15 16!((`signal;"sig1");(123);(`signal;"sig2"));2012.01.01D12:00:05.000000);
    value res;
    .tst.trace[`.monitor.p.publishResult] mustmatch enlist (`core.rdb;enlist[`testReq.check2]!enlist[123]);
    .tst.trace[`.monitor.pub] mustmatch ();
    .monitor.status[`status] mustmatch `resSignal`resReceived`resSignal;
    };
  should["publish sysConnStatus - .monitor.p.publishResult[], .monitor.p.getHnd[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    `hndStRes mock ([]sym:enlist`core.rdb;connRegistered:`core.hdb;connOpen:`s.ap1;connClosed:`s.ap2;connLost:`s.ap3;connFailed:`s.ap4);
    `hndSt mock ([server:`core.hdb`s.ap1`s.ap2`s.ap3`s.ap4]state:`registered`open`closed`lost`failed;timeout:100);
    .monitor.p.publishResult[`core.rdb;r:`base.proc`sysConnStatus.hndStatus!(`core.rdb;hndSt)];
    hndStRes mustmatch delete time from last last .tst.trace[`.monitor.pub];
    };
  should["publish sysLogStatus - .monitor.p.publishResult[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .monitor.p.publishResult[`core.rdb;`base.proc`sysLogStatus.logHist!(`core.rdb;(`FATAL`ERROR`WARN!1 2 2))];
    1j musteq count .tst.trace[`.monitor.pub];
    `sysLogStatus mustmatch first first .tst.trace[`.monitor.pub];
    ([]sym:enlist `core.rdb; logFatal:1; logError:2; logWarn:2) mustmatch delete time from last last .tst.trace[`.monitor.pub];
    };
  should["publish sysLogStatus - .monitor.p.publishResult[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .monitor.p.publishResult[`core.rdb;`base.proc`sysResUsageFromQ.memState!(`core.rdb;(`peak`used`syms`symw!1 2 3 4))];
    1j musteq count .tst.trace[`.monitor.pub];
    `sysResUsageFromQ mustmatch first first .tst.trace[`.monitor.pub];
    ([]sym:enlist `core.rdb; memPeak:1; memUsed:2; memSyms:3; memSymw:4) mustmatch delete time from last last .tst.trace[`.monitor.pub];
    };
  should["publish monitor data - .monitor.pub[]"]{
    .tst.mockFunc[`.u.pub;2;""];
    .tst.mockFunc[`.monitor.p.jrnH;1;""];
    `tab mock ([]time:enlist 12:00:00.000; sym:`core.hdb);
    `.u.i mock 0j;
    .monitor.pub[`sysConnStatus;tab];
    .tst.trace[`.monitor.p.jrnH] mustmatch enlist enlist (`jUpd;`sysConnStatus;tab);
    .u.i mustmatch 1j;
    .tst.trace[`.u.pub] mustmatch enlist (`sysConnStatus;tab);
    };
  };

//----------------------------------------------------------------------------//
.tst.desc["test event handling"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    `.monitor.cfg.eventDir mock `:test/data/;
    `eventBase mock `componentId`module`level`tsId`funcName`descr!(`core.rdb;`rdb;`info;2012.01.01T01:00:00.000;`rdb.eod;"rdb eod");
    (`$":test/data/event.started")      set eventBase,enlist[`status]!enlist[`EVENT_STARTED];
    (`$":test/data/event.inprogress")   set eventBase,`status`progress`timeLeft!(`EVENT_PROGRESS;20;01:00:00.000);
    (`$":test/data/event.failed")       set eventBase,enlist[`status]!enlist[`EVENT_FAILED];
    (`$":test/data/event.completed")    set eventBase,`status`progress`timeLeft!(`EVENT_COMPLETED;100;00:00:00.000);
    (`$":test/data/eventFile_archive")  set `archive;
    (`$":test/data/archiveFile")        set `archive;
    (`$":test/data/archive/buFile")     set `archive;
    (`$":test/data/fileDuringWriting#") set `inProgress;
    };
  after{
    .tst.rm[`:test/data];
    };
  should["find event files - .monitor.p.tsEventsRead[]"]{
    .tst.mockFunc[`.monitor.p.processEventFile;1;""];
    .monitor.p.tsEventsRead[];
    .tst.trace[`.monitor.p.processEventFile] mustmatch `event.completed`event.failed`event.inprogress`event.started;
    };
  should["process event files - .monitor.p.processEventFile[]"]{
    .tst.mockFunc[`.monitor.p.processEvent;1;""];
    .tst.mockFunc[`.monitor.p.backupEvent;3;""];
    .monitor.p.processEventFile[`file];
    .tst.trace[`.monitor.p.processEvent] mustmatch enlist`:test/data/file;
    .tst.trace[`.monitor.p.backupEvent] mustmatch enlist("test/data/";`file;"test/data//archive/", string[.z.d],"/");
    };
  should["generate sysEvent with state `started - .monitor.p.processEvent[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .monitor.p.processEvent[`:test/data/event.started];
    .tst.trace[`.monitor.pub][0;0] mustmatch `sysEvent;
    (delete time from .tst.trace[`.monitor.pub][0;1]) mustmatch `sym`module`eventLevel xcol flip enlist each eventBase,`status`progress`timeLeft!(`EVENT_STARTED;0Nj;0Nt);
    };
  should["generate sysEvent with state `progress - .monitor.p.processEvent[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .monitor.p.processEvent[`:test/data/event.inprogress];
    .tst.trace[`.monitor.pub][0;0] mustmatch `sysEvent;
    (delete time from .tst.trace[`.monitor.pub][0;1]) mustmatch `sym`module`eventLevel xcol flip enlist each eventBase,`status`progress`timeLeft!(`EVENT_PROGRESS;20;01:00:00.000);
    };
  should["generate sysEvent with state `failed - .monitor.p.processEvent[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .monitor.p.processEvent[`:test/data/event.failed];
    .tst.trace[`.monitor.pub][0;0] mustmatch `sysEvent;
    (delete time from .tst.trace[`.monitor.pub][0;1]) mustmatch `sym`module`eventLevel xcol flip enlist each eventBase,`status`progress`timeLeft!(`EVENT_FAILED;0Nj;0Nt);
    };
  should["generate sysEvent with state `completed - .monitor.p.processEvent[]"]{
    .tst.mockFunc[`.monitor.pub;2;""];
    .monitor.p.processEvent[`:test/data/event.completed];
    .tst.trace[`.monitor.pub][0;0] mustmatch `sysEvent;
    (delete time from .tst.trace[`.monitor.pub][0;1]) mustmatch `sym`module`eventLevel xcol flip enlist each eventBase,`status`progress`timeLeft!(`EVENT_COMPLETED;100;00:00:00.000);
    };
  should["backup event file - .monitor.p.backupEvent[]"]{
    .tst.mockFunc[`.q.system;1;""];
    .tst.loadLib[`monitor.q];
    .monitor.p.backupEvent[eventDir:"test/data/";file:`event.started; backupDir:"test/data/archive/"];
    get[`:test/data/archive/lastEvent] mustmatch `event.started;
    last[.tst.trace[`.q.system]] mustmatch "mv test/data/event.started test/data/archive/";
    };
  };

//----------------------------------------------------------------------------//
.tst.desc["test hdb statistics - sysHdbSummary"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    `:test/data/hdb/tab1 set ([]c:1 2 3);
    `:test/data/hdb/tab2 set ([]c:`1`2`3);
    `:test/data/hdb/2012.01.01/tab3/ set ([]c:1 2 3 4);
    `:test/data/hdb/2012.01.02/tab3/ set ([]c:1 2 3 4);

    `:test/data/hdb2/tab1 set ([]c:1 2 3);
    `:test/data/hdb2/tab2 set ([]c:`1`2`3);
    `:test/data/hdb2/par.txt 1: ssr[system["cd"];"\\";"/"],"/test/data/par1/\n";
    `:test/data/par1/2012.01.01/tab3/ set ([]c:1 2 3 4);
    `:test/data/par1/2012.01.02/tab3/ set ([]c:1 2 3 4);
    };
  after{
    .tst.rm[`:test/data];
    };
  should["analyze non-existing hdb disk usage [du] - .monitor.p.hdbSummary[]"]{
    .monitor.p.hdbSummary["test/data/missingHdb/"] mustmatch ([]hdb:enlist`$"test/data/missingHdb/" ;sizeMB:enlist 0N);
    };
  should["analyze hdb disk usage [du] -  .monitor.p.hdbSummary[]"]{
    .monitor.p.hdbSummary["test/data/hdb/"] mustmatch ([]hdb:enlist`$"test/data/hdb/" ;sizeMB:enlist 1j);
    .monitor.p.hdbSummary["test/data/hdb2/"] mustmatch ([]hdb:enlist`$"test/data/hdb2/" ;sizeMB:enlist 2j);
    };
  should[".monitor.p.getHdbTabs[]"]{
    `tab1`tab2`tab3 mustmatch asc .monitor.p.getHdbTabs["test/data/hdb/"];
    `tab1`tab2`tab3 mustmatch asc .monitor.p.getHdbTabs["test/data/hdb2/"];
    };
  should[".monitor.p.getHdbSummary[]"]{
    (delete time from .monitor.p.getHdbSummary[`hdb`hdb2!`:test/data/hdb/`:test/data/hdb2/])
    mustmatch ([]sym:`hdb`hdb2;path:`:test/data/hdb/`:test/data/hdb2/;hdbSizeMB:1 2j;hdbTabCnt:3 3j;tabList:(`tab3`tab1`tab2;`tab3`tab1`tab2));
    };
  should["generate hdb disk usage stats - .monitor.p.dailyExec.sysHdbSummary[]"]{
    `.monitor.cfg.sysHdbSummaryPathDict mock `hdb1`hdb2!`:test/data/hdb/`:test/data/hdb2/;
    .tst.mockFunc[`.monitor.pub;2;""];
    .monitor.p.dailyExec.sysHdbSummary[];
    .tst.trace[`.monitor.pub][0;0]mustmatch `sysHdbSummary;
    (delete time from .tst.trace[`.monitor.pub][0;1])
    mustmatch ([]sym:`hdb1`hdb2;path:`:test/data/hdb/`:test/data/hdb2/;hdbSizeMB:1 2j;hdbTabCnt:3 3j;tabList:(`tab3`tab1`tab2;`tab3`tab1`tab2));
    };
  };

//----------------------------------------------------------------------------//
.tst.desc["test hdb statistics - sysHdbStats"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    `.hnd.status mock ([s:enlist`hdb1]handle:enlist 0i);
    `.tmp.data mock ([]hdbDate:.z.d;hour:12:00:00.000 13:00:00.000;totalRowsCnt:1j;minRowsPerSec:2j;avgRowsPerSec:3j;medRowsPerSec:4j;maxRowsPerSec:5j;dailyMed:6j);
    code:"`hdbDate`hour`table xcols update table:a0 from .tmp.data";
    .tst.mockFunc[`.hdb.dataVolumeHourly;2;code];
    .tst.mockFunc[`.monitor.pub;2;""];
    };
  after{
    };
  should["generate hdb statistics - .monitor.p.getOneHdbStats[], .monitor.p.getHdbStats[]"]{
    res:.monitor.p.getOneHdbStats[`hdb1;.z.d];
    tables[] mustmatch exec distinct table from res;
    .tmp.data mustmatch delete sym, time,table from select from res where table=tables[][0];
    enlist[`hdb1] mustmatch exec distinct sym from res;
    enlist[.z.d] mustmatch exec distinct hdbDate from res;

    res2:.monitor.p.getHdbStats[enlist`hdb1;.z.d];
    (delete time from res)mustmatch (delete time from res2);

    `.monitor.cfg.sysHdbStatsProcList mock enlist `hdb1;
    .monitor.p.dailyExec.sysHdbStats[];
    .tst.trace[`.monitor.pub][0;0] mustmatch `sysHdbStats;
    (delete time from .tst.trace[`.monitor.pub][0;1]) mustmatch (delete time from res2);
    };
  };

.tst.desc["test func statistics"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    .tst.mockFunc[`.monitor.pub;2;""];
    `.hnd.status mock ([s:enlist`ap1]handle:enlist 0i);
    `.ns.func1 mock {2+3};
    `.ns.var mock 12;
    `.ns2.func1 mock {2+x};
    `.ns2.func2 mock {x+3};
    };
  after{
    };
  should["get func summary of unavailable server - .monitor.p.getFuncSummary[]"]{
    .tst.mockFunc[`.hnd.h;2;"'`unavailable"];
    res:.monitor.p.getFuncSummary[procList:enlist`ap1;procNs:`.ns`.ns2`.ns3];
    (delete time from res)mustmatch ([]sym:`ap1;procNs:`.ns`.ns2`.ns3;funcCnt:0Ni; func:`symbol$(();();()));
    };
  should["get func summary - .monitor.p.getFuncSummary[]"]{
    res:.monitor.p.getFuncSummary[enlist`ap1;`.ns`.ns2`.ns3];
    (delete time from res)mustmatch ([]sym:`ap1;procNs:`.ns`.ns2`.ns3;funcCnt:1 2 0i; func:(enlist `.ns.func1;`.ns2.func1`.ns2.func2;`symbol$()));
    };
  should[".monitor.p.dailyExec.sysFuncSummary[]"]{
    `.monitor.cfg.sysFuncSummaryProcList mock enlist`ap1;
    `.monitor.cfg.sysFuncSummaryProcNs mock `.ns`.ns2`.ns3;
    .monitor.p.dailyExec.sysFuncSummary[];
    `time`sym`procNs`funcCnt`func mustmatch cols (last last .tst.trace[`.monitor.pub]);
    `sysFuncSummary mustmatch (first last .tst.trace[`.monitor.pub]);
    };
  should[".monitor.p.getKdbLicSummary[]"]{
    `.sl.componentId mock `core.rdb;
    lic:.monitor.p.getKdbLicSummary[];
    if[count .z.l;
      (delete time from lic) mustmatch ([]sym:enlist`core.rdb;maxCoresAllowed:"I"$.z.l 0;expiryDate:"D"$.z.l 1;updateDate:"D"$.z.l 2;cfgCoreCnt:.z.c);
      ];
    if[0=count .z.l;
      (delete time from lic) mustmatch ([]sym:enlist`core.rdb;maxCoresAllowed:enlist 0Ni;expiryDate:enlist 0Nd;updateDate:enlist 0Nd;cfgCoreCnt:.z.c);
      ];
    };
  should[".monitor.p.dailyExec.getKdbLicSummary[]"]{
    .monitor.p.dailyExec.sysKdbLicSummary[];
    `time`sym`maxCoresAllowed`expiryDate`updateDate`cfgCoreCnt mustmatch cols (last last .tst.trace[`.monitor.pub]);
    `sysKdbLicSummary mustmatch (first last .tst.trace[`.monitor.pub]);
    };
  };


.tst.desc["test disk usage - sysDiskSpace"]{
  before{
    .tst.loadLib[`monitor.q];
    .monitor.p.initSysTables[];
    `:test/data/tickBin/tmp set 1000#"1234567890";
    `:test/data/tickEtc/tmp set 1000#"1234567890";
    `:test/data/tick/tmp set 3000#"1234567890";
    `:test/data/hdb/tab1/tmp set 4000#"1234567890";
    `:test/data/hdb/tab2/tmp set 5000#"1234567890";
    };
  after{
    .tst.rm[`:test/data];
    };
  should["check disk usage - .monitor.p.du[]"]{
    7j mustmatch .monitor.p.du `:test/data/tick;
    21j mustmatch .monitor.p.du `:test/data/hdb;
    };
  should["check free diskspace - .monitor.p.df[]"]{
    res:.monitor.p.df`:test/data;
    res[`path] mustmatch enlist`:test/data;
    (exec c!t from meta res) mustmatch `path`filesystem`blocks1K`totalBytesUsed`totalBytesAvailable`totalCapacityPerc`mountedOn!"ssjjjss";
    };
  should["check free diskspace - .monitor.p.diskTs[]"]{
    `.cr.getCfgTab mock {[x;y;z]([] subsection:`tick`tick`tick`hdb`hdb`hdb2`hdb; varName:`binPath`etcPath`dataPath`binPath`logPath`logPath`unsupportedPath; finalValue:`:test/data/tickBin`:test/data/tickEtc`:test/data/tick`:test/data/hdb`:test/data/hdbLog`:missingPath`:test/data/hdb)};
    .tst.mockFunc[`.monitor.pub;2;""];
    .monitor.p.diskTs[];
    res:.tst.trace[`.monitor.pub][0];
    res[0] mustmatch `sysDiskUsage;
    (exec c!t from meta res[1])mustmatch `time`sym`pathName`path`filesystem`mountedOn`blocks1K`totalBytesAvailable`totalBytesUsed`procBytesUsed!"tsssssjjjj";
    (exec totalBytesUsed, totalBytesAvailable, procBytesUsed from res[1] where path=`:missingPath)mustmatch `totalBytesUsed`totalBytesAvailable`procBytesUsed!(enlist 0Nj;enlist 0Nj;enlist 0Nj);
    };
  };

//----------------------------------------------------------------------------//
\
/
.tst.report
