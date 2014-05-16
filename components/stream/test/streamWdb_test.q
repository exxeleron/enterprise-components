// q test/streamWdb_test.q --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q
.sl.init[`test];

//----------------------------------------------------------------------------//
.tst.loadLib:{[lib]
  .sl.noinit:1b;
  .sl.libpath:`:.,.sl.libpath;
  @[system;"l ",string lib;0N];
  };

/------------------------------------------------------------------------------/
/                              initialize stream                               /
/------------------------------------------------------------------------------/
.tst.desc["initialize stream processes"]{
  before{
    .tst.loadLib[`stream.q];
    .tst.loadLib[`streamWdb.q];
    `.tmp.cd mock system "cd";
    `.cache.trade mock ([]time:`time$(); sym:`symbol$();price:`float$());
    `.cache.quote mock ([]time:`time$(); sym:`symbol$();bid:`float$());
    `.stream.cfg.model mock ((`trade;.cache.trade);(`quote;.cache.quote));
    `.stream.cacheNames mock `trade`quote!`.cache.trade`.cache.quote;
    `.stream.cfg.srcTab mock ([]tab:`trade`quote; server:`tickHF; subType:`tickHF);

    `.wdb.cfg.dataDumpInterval mock `long$600000000000;
    `.wdb.cfg.fillMissingTabsHdb mock 0b;
    `.wdb.cfg.reloadHdb mock 0b;
    `.stream.date mock 2012.01.01;

    .tst.mockFunc[`.stream.savepoint;1;""];

    `.wdb.cfg.mrvsDumpInterval mock 00:10:00.000000;
    `.wdb.cfg.data mock hsym`$.tmp.cd,"/test/tmp/wdb/";
    `.wdb.cfg.dstHdb mock hsym`$.tmp.cd,"/test/tmp/dstHdb/";
    `.store.comFile mock ` sv .wdb.cfg.dstHdb,`eodStatus;
    `:test/tmp/wdb/tmp2/tmp set 1;
    .tst.rm[`:test/tmp/wdb/tmp2];
    `:test/tmp/dstHdb/tmpdb/tmp set 1;
    .tst.rm[`:test/tmp/dstHdb/tmpdb/tmp];
    system "cd test/tmp/wdb/tmpdb/";

    `.store.tabs mock ([]table:enlist`universe;hdbPath:.wdb.cfg.dstHdb;hdbName:`kdb.hdb;memoryClear:1b;store:1b);
    `universe mock ([]sym:`a`b`c;id:1 2 3);
    `.store.settings mock ([]reloadHdb:enlist 0b;fillMissingTabsHdb:enlist 0b;hdbConns:`core.hdb);

    .wdb.p.initWdb 2012.01.01;
    };
  after{
    system "cd ",.tmp.cd;
    .tst.rm[`:test/tmp];
    };
  should["perform subscription initialization - .stream.plug.sub[], .wdb.p.initStore[]"]{
    .stream.plug.sub[`tick;.stream.cfg.model;(::)];
    .wdb.lastDumpTs mustmatch 00:00:00.000000;
    meta[.cache.trade] mustmatch meta delete date from select from trade;
    meta[.cache.quote] mustmatch meta delete date from select from quote;
    `sym mustmatch key exec sym from select from trade;
    (`symbol$())mustmatch get ` sv .wdb.cfg.dstHdb,`sym;
    (`symbol$())mustmatch sym;
    };
  should["dump data on ts callback - .stream.plug.ts[], .wdb.p.store[]"]{
    .stream.plug.sub[`tick;.stream.cfg.model;(::)];
    `.wdb.lastDumpTs mock 01:00:00.000000;
    `.cache.trade insert upd:([]time:01:01:00.000 01:03:00.000;sym:`a`b;price:1.1 1.2);
    .stream.plug.ts[.z.d+01:05:00.000000];  //update cache - no trigger for data dump
    (select time,price from upd) mustmatch select time,price from .cache.trade;
    0j mustmatch count trade;
    .tst.trace[`.stream.savepoint] mustmatch ();
    .wdb.lastDumpTs mustmatch 01:00:00.000000;

    `.cache.trade insert upd2:([]time:01:07:00.000 01:08:00.000;sym:`a`c;price:11.1 11.2);
    .stream.plug.ts[.z.d+01:11:00.000000];  //first trigger for data dump
    (select time,price from upd,upd2) mustmatch select time,price from trade;
    0j mustmatch count .cache.trade;
    .tst.trace[`.stream.savepoint] mustmatch enlist 01:11:00.000000;
    .wdb.lastDumpTs mustmatch 01:11:00.000000;

    `.cache.trade insert upd3:([]time:01:12:00.000 01:13:00.000;sym:`a`d;price:21.1 21.2);
    .stream.plug.ts[.z.d+01:16:00.000000];  //update cache - no trigger for data dump
    (select time,price from upd,upd2) mustmatch select time,price from trade;
    (select time,price from upd3) mustmatch select time,price from .cache.trade;
    .tst.trace[`.stream.savepoint] mustmatch enlist 01:11:00.000000;
    .wdb.lastDumpTs mustmatch 01:11:00.000000;

    `.cache.trade insert upd4:([]time:01:17:00.000 01:18:00.000;sym:`a`c;price:31.1 31.2);
    .stream.plug.ts[.z.d+01:22:00.000000];  //second trigger for data dump
    (select time,price from upd,upd2,upd3,upd4) mustmatch select time,price from trade;
    0j mustmatch count .cache.trade;
    .tst.trace[`.stream.savepoint] mustmatch 01:11:00.000000 01:22:00.000000;
    .wdb.lastDumpTs mustmatch 01:22:00.000000;
    };
  should["perform eod - .stream.plug.eod[]"]{
    .stream.plug.sub[`tick;.stream.cfg.model;(::)];
    `.cache.trade insert upd:([]time:01:01:00.000 01:02:00.000 01:03:00.000 01:03:00.000;sym:`a`b`a`b;price:1.1 1.2 1.3 1.4);
    .stream.plug.ts[.z.d+01:05:00.000000];  //trigger data dump
    beforeEod:system"cd";
    .stream.plug.eod[day:2012.01.01]; //perform eod (note: stream is responsible for last ts[] trigger
      
    //check if cache was cleared
    0j mustmatch count .cache.trade;
    //check if prev day was moved to dst hdb
    `2012.01.01 mustin key .wdb.cfg.dstHdb;
    //check if dst data was sorted on disk
    
    (select time, price from `sym xasc upd) mustmatch select time, price from ` sv .wdb.cfg.dstHdb,`2012.01.01`trade`;
    
    //Check if new day was created
    0j mustmatch count trade;
    beforeEod mustmatch system"cd";
    };
  };


/------------------------------------------------------------------------------/
/
reverse select count i by date from trade
reverse select count i by date from quote

select count i by time.hh from trade
select count i by time.hh from .cache.trade

select count i by time.hh from ob
select count i by time.hh from .cache.ob
.Q.chk[`:.]
.u.end .z.d
