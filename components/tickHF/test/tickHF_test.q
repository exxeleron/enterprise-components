// q test/tickHF_test.q --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q
.sl.init[`test];

.tst.rm:{[dir]
  if["w"~first string .z.o;
    cmd:"rmdir /S /Q ", ssr[1_string dir;"/";"\\"];
    .log.debug[`test] "Call command ", cmd;
    system cmd;
    ];
  if[first[ string .z.o] in "sl";
    cmd:"rm -rf ", 1_string dir;
    .log.debug[`test] "Call command ", cmd;
    system cmd;
    ];
  };
.tst.desc["eod with handling late ticks"]{
  before{
    .sl.noinit:1b;
    @[system;"l tickHF.q";0N];
    system"t 0";

    (set) ./:                     model:enlist (`quote;([] time:(); sym:`symbol$(); ask:();bid:();sizeA:();sizeB:()));
    .tickHF.cfg.dataPath:"test/tmp";
    .tickHF.cfg.jrnPrefix:"in.tickHF";
    .sl.timestampMode:`UTC;
    .sl.eodDelay:00:01:00.000;
    .u.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)];

    .u.nextday.names:model[;0]!` sv/:`.cache,/:model[;0];
    (set) ./:                    ((value .u.nextday.names)(;)'model[;1]);
    .tickHF.p.checkModel value .u.nextday.names;
    .u.nextday.d:.u.d;
    `.u.ts set .u.eodMode.ts;
    };

  after{
    /hclose .u.l;
    /hclose .u.nextday.l;
    .tst.rm `:test/tmp;
    //        .log.status:(`FATAL`ERROR`WARN`INFO`DEBUG)!5#0;
    //        .event.hist:1#.event.hist;
    //        .hnd.reset[];
    //        delete from `.cb.status;
    
    };
  
  should["eod with zero latency mode, data published with time"]{
    .tickHF.cfg.aggrInterval:0Nt;
    .u.p.zeroLatencyMode[];
    .z.d mustmatch .u.d;
    .cache.quote mustmatch quote;
    // pub data before eod, .u.i, .u.j should grow
    .u.upd[`quote;flip 2#enlist (23:59:45.491;`a;1.;1.;1j;1j)];
    .u.i mustmatch 1;
    .u.j mustmatch 0;
    // call .u.ts after midnight, before real eod 
    .u.ts (.z.d+1)+00:00:00.001; // upd should change to updEodDetectionMode
    .u.upd mustmatch .u.updEodDetectionMode;
    .u.late.i mustmatch .u.i; // from this i late ticks are counted
    .u.nextday.d mustmatch .z.d+1;
    // pub late data after midnight, before real eod -> .u.i, .u.j should grow
    .u.upd[`quote;flip 2#enlist (23:59:45.491;`a;1.;1.;1j;1j)];
    .u.i mustmatch 2;
    .u.j mustmatch 0;
    .u.nextday.j mustmatch 0;
    // pub data after midnight for the next day, before real eod -> late ticks .u.nextday.i, .u.nextday.j should grow
    .u.upd[`quote;x:flip 2#enlist (00:01:45.491;`a;1.;1.;1j;1j)];
    .u.i mustmatch 2;
    .u.j mustmatch 0;
    .u.nextday.i mustmatch 0;
    .u.nextday.j mustmatch 1;
    0 mustlt count .cache.quote;
    // journal for the next day should be created
    1b mustmatch any (f:key `:test/tmp) like "*",string .z.d+1;
    // invoke real eod, all nextday values should be moved to .u.[ijd], cached values should be published and deleted
    .u.ts (.z.d+1)+00:01:00.001;
    .u.upd mustmatch .u.updActiveDay;
    // clear nextday values
    .u.nextday.i mustmatch 0;
    .u.nextday.l mustmatch 0i;
    (.u.nextday[`L]) mustmatch (::);    
    .u.i mustmatch 1j;
    .u.j mustmatch 1j;
    0 mustmatch count .cache.quote;
    };

  should["eod in throttled mode, data published with time"]{
    .tickHF.cfg.aggrInterval:100;
    .u.p.aggrMode[];
    .z.d mustmatch .u.d;
    .cache.quote mustmatch quote;
    // pub data before eod, .u.i, .u.j should grow
    .u.upd[`quote;flip 2#enlist (23:59:45.491;`a;1.;1.;1j;1j)];
    .u.i mustmatch 0;
    .u.j mustmatch 1;
    .tickHF.ts[];
    .u.i mustmatch 1;
    .u.j mustmatch 1;
    // call .u.ts after midnight, before real eod 
    .u.ts (.z.d+1)+00:00:00.001; // upd should change to updEodDetectionMode
    .u.upd mustmatch .u.updEodDetectionMode;
    .u.late.i mustmatch .u.i; // from this i late ticks are counted
    .u.nextday.d mustmatch .z.d+1;
    // pub late data after midnight, before real eod -> .u.i, .u.j should grow
    .u.upd[`quote;flip 2#enlist (23:59:45.491;`a;1.;1.;1j;1j)];
    .u.i mustmatch 1;
    .u.j mustmatch 2;
    .u.nextday.j mustmatch 0;
    0 mustlt count quote;
    .tickHF.ts[];
    .u.i mustmatch 2;
    0 mustmatch count quote;
    // pub data after midnight for the next day, before real eod -> late ticks .u.nextday.i, .u.nextday.j should grow
    .u.upd[`quote;x:flip 2#enlist (00:01:45.491;`a;1.;1.;1j;1j)];
    .u.i mustmatch 2;
    .u.j mustmatch 2;
    .u.nextday.i mustmatch 0;
    .u.nextday.j mustmatch 1;
    0 mustlt count .cache.quote;
    // journal for the next day should be created
    1b mustmatch any (f:key `:test/tmp) like "*",string .z.d+1;
    .tickHF.ts[];
    .u.i mustmatch 2;
    .u.j mustmatch 2;
    .u.nextday.i mustmatch 0;
    .u.nextday.j mustmatch 1;
    // invoke real eod, all nextday values should be moved to .u.[ijd], cached values should be published and deleted
    .u.ts (.z.d+1)+00:01:00.001;
    .u.upd mustmatch .u.updActiveDay;
    // clear nextday values
    .u.nextday.i mustmatch 0;
    .u.nextday.l mustmatch 0i;
    (.u.nextday[`L]) mustmatch (::);    
    .u.i mustmatch 0j;
    .u.j mustmatch 1j;
    0 mustmatch count .cache.quote;       
    0 mustlt count quote;
    .tickHF.ts[];
    .u.i mustmatch .u.j;
    };
  should["test case if tickHF is still before triggering real eod and capture late ticks is on"]{
    .tickHF.cfg.aggrInterval:100;
    .u.p.aggrMode[];
    // assuming it is still yesterday, i.e. we are still before eod trigger for yesterday, activeDay=yesterday
    activeJrn:`$":test/tmp/in.tickHF",string .z.d;
    nextdayJrn:`$":test/tmp/in.tickHF",string .z.d+1;
    activeJrn set ();
    h:hopen activeJrn;
    h enlist (`jUpd;`quote;2#enlist (23:59:45.491;`a;1.;1.;1j;1j));
    hclose h;
    nextdayJrn set ();
    h:hopen nextdayJrn;
    h enlist (`jUpd;`quote;2#enlist (00:01:45.491;`a;1.;1.;1j;1j));
    hclose h;
    .sl.zd:{.z.d};
    .u.nextday.d:1+.u.d;
    .u.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)];
    .u.nextday.tick[(.tickHF.cfg.jrnPrefix;.tickHF.cfg.dataPath)];
    .u.nextday.L mustmatch nextdayJrn;
    .u.L mustmatch activeJrn;
    .u.d mustmatch .z.d;
    .u.nextday.d mustmatch .z.d+1;
    .u.i mustmatch 1;
    .u.j mustmatch 1;
    .u.nextday.i mustmatch 1;
    .u.nextday.j mustmatch 1;
    };

  };


\
/
.tst.report
.hnd.status

create new table that not should be store
