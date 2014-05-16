// q test/streamMrvs_test.q --noquit -p 5001

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
.tst.desc["initialize stream aggr - .stream.plug.init[]"]{
  before{
    .tst.loadLib[`streamMrvs.q];
    `fields mock `cfg.mrvsDumpInterval`cfg.fillMissingTabsHdb`cfg.reloadHdb!(1000;1b;1b);
    .tst.mockFunc[`.cr.getCfgField;3;"fields[a2]"];
    .tst.mockFunc[`.cr.getCfgPivot;3;"$[`hdbConn in a2;(flip (enlist `sectionVal)!enlist `quote`tradeSnap)!
        flip `hdbConn`eodClear`eodPerform!(`core.hdb`;10b;10b); (flip (enlist `sectionVal)!enlist `quote`trade)!flip (enlist `outputTab)!enlist ``tradeSnap]"];
    .tst.mockFunc[`.store.init;4;""];
    .stream.plug.init[];
    };
  should["initialize output tables"]{
    (`quote`trade!`quote`tradeSnap) mustmatch .mrvs.cfg.src2dst;
    };
  should["initialize eod"]{
    3 mustmatch count .tst.trace[`.store.init][0];
    };
  };

.tst.desc["sub plugin for stream mrvs - .stream.plug.sub"]{
  before{
    .tst.loadLib[`streamMrvs.q];
    };
  should["init .mrvs.lastDumpTs"]{
    .stream.plug.sub[`;`;::];
    .mrvs.lastDumpTs mustmatch 00:00:00.000;
    };
  should["init savepoint data"]{
    .stream.plug.sub[`tickHF;enlist(`quote;([] time:();sym:()));enlist(`quote;([] time:();sym:()))];
    ([] time:();sym:()) mustmatch quote;
    delete quote from `.;
    };
  };

.tst.desc["timer plugin for stream mrvs - .stream.plug.ts"]{
  before{
    .tst.loadLib[`streamMrvs.q];
    `.stream.cfg.model mock ((`quote;flip `time`sym!(`time$();0#`));(`trade;flip `time`sym!(`time$();0#`)));
    `.mrvs.cfg.src2dst mock `quote`trade!`quote`tradeSnap;
    `.stream.cacheNames mock `trade`quote!`.cache.trade`.cache.quote;
    .tst.mockFunc[`.stream.savepoint;1;""];
    `data mock ([] time:2#.z.t;sym:`a`b);
    `.cache.trade mock data;
    `.cache.quote mock data;
    `.mrvs.lastDumpTs mock .z.t+1000000;
    `.mrvs.cfg.mrvsDumpInterval mock 100;
    .stream.plug.ts[.z.p];
    };
  should["calculate mrvs data"]{
    quote mustmatch `sym xkey data;
    tradeSnap mustmatch `sym xkey data;
    };
  should["delete cache"]{
    0 mustmatch/:count each (.cache.trade;.cache.quote);
    };
  should["call savepoint"]{
    `.cache.trade mock data;
    `.cache.quote mock data;
    `.mrvs.lastDumpTs mock 00:00:00.000;
    .stream.plug.ts[01:00:00.000];
    .mrvs.lastDumpTs mustgt 00:00:00.000;
    (`sym xkey data) mustmatch/: .tst.trace[`.stream.savepoint][0;;1];
    };
  };

.tst.desc["eod plugin for stream mrvs - .stream.plug.eod"]{
  before{
    .tst.loadLib[`streamMrvs.q];
    .tst.mockFunc[`.store.run;1;""];
    `.stream.cfg.model mock ((`quote;flip `time`sym!(`time$();0#`));(`trade;flip `time`sym!(`time$();0#`)));
    `.mrvs.cfg.src2dst mock `quote`trade!`quote`tradeSnap;
    `.stream.cacheNames mock `trade`quote!`.cache.trade`.cache.quote;
    `data mock ([] time:2#.z.t;sym:`a`b);
    `quote mock data;
    `tradeSnap mock data;
    `.cache.trade mock data;
    `.cache.quote mock data;
    .stream.plug.eod[.z.d];
    };
  should["call .store.run"]{
    .z.d mustmatch .tst.trace[`.store.run][0];
    };
  should["cleanup of internal buffers"]{
    0 mustmatch/: count each (quote;tradeSnap;.cache.trade;.cache.quote);
    };
  };

/------------------------------------------------------------------------------/
