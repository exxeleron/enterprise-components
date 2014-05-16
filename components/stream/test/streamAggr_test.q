// q test/streamAggr_test.q --noquit -p 5001

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
    .tst.loadLib[`streamAggr.q];
    .tst.mockFunc[`.cr.getCfgPivot;3;"(flip (enlist `sectionVal)!enlist `quote`trade)!flip (enlist `outputTab)!enlist ``tradeSnap"];
    `.stream.cfg.model mock ((`quote;flip `time`sym`bid`ask`bidSize`askSize!(`time$();0#`;`float$();`float$();`long$();`long$()));(`trade;flip `time`sym`price`size!(`time$();0#`;`float$();`long$())));
    .tst.mockFunc[`.stream.initPub;1;""];
    .stream.plug.init[];
    };
  should["initialize models"]{
    `quote`tradeSnap mustmatch .aggr.cfg.model[;0];
    };
  should["initialize tables that will be pubslished"]{
    `quote`tradeSnap mustmatch .tst.trace[`.stream.initPub][0;;0];
    };
  };

.tst.desc["timer plugin for stream aggr - .stream.plug.ts"]{
  before{
    .tst.loadLib[`streamAggr.q];
    `.stream.cfg.model mock ((`quote;flip `time`sym!(`time$();0#`));(`trade;flip `time`sym!(`time$();0#`)));
    `.aggr.cfg.src2dst mock `quote`trade!`quote`tradeSnap;
    `.stream.cacheNames mock `trade`quote!`.cache.trade`.cache.quote;
    .tst.mockFunc[`.stream.savepoint;1;""];
    .tst.mockFunc[`.stream.pub;2;""];
    `data mock ([] time:2#.z.t;sym:`a`b);
    `.cache.trade mock data;
    `.cache.quote mock data;
    };
  should["call data publishing"]{
    .stream.plug.ts[.z.p];
    (`quote;data) mustmatch .tst.trace[`.stream.pub][0];
    (`tradeSnap;data) mustmatch .tst.trace[`.stream.pub][1];
    };
  should["delete cache"]{
    .stream.plug.ts[.z.p];
    0 mustmatch/:count each (.cache.trade;.cache.quote);
    };
  should["call savepoint"]{
    .stream.plug.ts[.z.p];
    enlist[0N] mustmatch .tst.trace[`.stream.savepoint];
    };
  should["handle signal during data publishing"]{
    .tst.mockFunc[`.stream.pub;2;"'unexpected"];
    .stream.plug.ts[.z.p];
    (`quote;data) mustmatch .tst.trace[`.stream.pub][0];
    (`tradeSnap;data) mustmatch .tst.trace[`.stream.pub][1];
    2j mustmatch count .tst.trace[`.stream.pub];
    0 mustmatch/:count each (.cache.trade;.cache.quote);
    enlist[0N] mustmatch .tst.trace[`.stream.savepoint];
    };
  };
/------------------------------------------------------------------------------/
