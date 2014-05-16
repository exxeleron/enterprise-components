// q test/rdb_test.q --noquit -p 5001

\l lib/qspec/qspec.q

.tst.desc["test initialization"]{
  before{
    .sl.noinit:1b;
    @[system;"l rdb.q";0N];
    eodTabs:(flip (enlist `sectionVal)!enlist `adjustmentFactors`quote`trade`tradeSnap`universe)!
    flip `eodPath`hdbConn`eodClear`eodPerform!(`:core.hdb``:core.hdb`:core.hdb`;`core.hdb``core.hdb2`core.hdb`;10110b;10110b);
    `.rdb.cfg.eodTabs            mock eodTabs;
    `.rdb.cfg.fillMissingTabsHdb mock 1b;
    `.rdb.cfg.timeout            mock 100i;
    `.rdb.cfg.reloadHdb          mock 1b;
    `.rdb.cfg.timestampMode      mock `UTC;
    `.rdb.cfg.dataPath           mock `:test/data;
    `.rdb.curr_zd                mock $[`UTC~.rdb.cfg.timestampMode; {.z.d};{.z.D}];
    .tst.mockFunc[`.store.init;4;""];
    .tst.mockFunc[`.hnd.hopen;3;""];
    .tst.mockFunc[`.hnd.poAdd;2;""];
    .rdb.p.init[];
    };
  should["call initialization of store library for tables that should be stored"]{
    5 mustmatch count .tst.trace[`.store.init][0][0];
    11b mustmatch .tst.trace[`.store.init][0; 1 2];
    };
  should["open connection to hdb"]{
    `core.hdb`core.hdb2 mustmatch .tst.trace[`.hnd.hopen][0;0];
    };
  };

.tst.desc["test end-of-day"]{
  before{
    .sl.noinit:1b;
    @[system;"l rdb.q";0N];
    .tst.mockFunc[`.store.run;1;""];
    `.rdb.date mock .z.d;
    };
  should["perform callback .u.end"]{
    .u.end .z.d;
    enlist[.z.d] mustmatch .tst.trace[`.store.run];
    .rdb.date mustmatch .z.d+1;
    };
  should["not perform eod for second call"]{
    .tst.mockFunc[`.log.info;2;""];
    .u.end .z.d-1;
    0 mustmatch count  .tst.trace[`.store.run];
    "Eod proccess was called already. Further eod activities won't be performed" mustmatch .tst.trace[`.log.info][0;1];
    .rdb.date mustmatch .z.d;
    };
  should["perform plugin beforeEod"]{
    .rdb.plug.beforeEod[`test]:{ `call mock 1b};
    .u.end .z.d;
    call mustmatch 1b;
    .rdb.date mustmatch .z.d+1;
    };
  should["crush plugin beforeEod"]{
    .tst.mockFunc[`.log.error;2;""];
    .rdb.plug.beforeEod[`test]:{ 'test};
    .rdb.plug.beforeEod[`test2]:{ `call mock 1b};
    .u.end .z.d;
    call mustmatch 1b;
    .rdb.date mustmatch .z.d+1;
    ("Perform beforeEod for table test";`.rdb.plug.beforeEod.test;"test") mustmatch .tst.trace[`.log.error][0;1]`descr`funcName`signal;
    };
  should["perform plugin afterEod"]{
    .rdb.plug.afterEod[`test]:{ `call mock 1b};
    .u.end .z.d;
    call mustmatch 1b;
    .rdb.date mustmatch .z.d+1;
    };
  should["crush plugin afterEod"]{
    .tst.mockFunc[`.log.error;2;""];
    .rdb.plug.afterEod[`test]:{ 'test};
    .rdb.plug.afterEod[`test2]:{ `call mock 1b};
    .u.end .z.d;
    call mustmatch 1b;
    .rdb.date mustmatch .z.d+1;
    ("Perform afterEod for table test";`.rdb.plug.afterEod.test;"test") mustmatch .tst.trace[`.log.error][0;1]`descr`funcName`signal;
    };
  
  };
/
.tst.report



