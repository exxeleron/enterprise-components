// q test/streamSnap_test.q --noquit -p 5001

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
.tst.desc["initialize stream snap - .stream.plug.init[]"]{
  before{
    .tst.loadLib[`streamSnap.q];
    `fields mock `cfg.snapMinuteBase`cfg.snapTimeoutInMs!(1000;100);
    .tst.mockFunc[`.cr.getCfgField;3;"fields[a2]"];
    .tst.mockFunc[`.cr.getCfgPivot;3;"$[not`srcTickHF in a2;
        (flip (enlist `sectionVal)!enlist `quote`trade)!flip (enlist `outputTab)!enlist ``tradeSnap;
        (flip (enlist `sectionVal)!enlist `quote`trade)!flip (enlist `srcTickHF)!enlist `tick1`tick1]"];
    `.stream.cfg.model mock ((`quote;flip `time`sym!(`time$();0#`));(`trade;flip `time`sym!(`time$();0#`)));
    .tst.mockFunc[`.stream.initPub;1;""];
    .stream.plug.init[];
    };
  should["initialize output tables"]{
    (`quote`trade!`quote`tradeSnap) mustmatch .snap.cfg.src2dst;
    .snap.lastSnapTs mustmatch`tick1`tick1!00:00:00.000 00:00:00.000;
    };
  should["initialize publishing"]{
    `quote`tradeSnap mustmatch .tst.trace[`.stream.initPub][0;;0];
    };
  };

.tst.desc["sub plugin for stream snap - .stream.plug.sub"]{
  before{
    .tst.loadLib[`streamSnap.q];
    `data mock ([] time:2#.z.t;sym:`a`b);
    };
  should["init savepoint data"]{
    .stream.plug.sub[`;`;(12:00:00.000;``trade`quote!(::;data;data))];
    data mustmatch .cache.quote;
    data mustmatch .cache.trade;
    delete quote from `.cache;
    delete trade from `.cache;
    };
  };


.tst.desc["timer plugin for stream snap - .stream.plug.ts"]{
  before{
    .tst.loadLib[`streamSnap.q];
    // `.stream.cfg.model mock ((`quote;flip `time`sym!(`time$();0#`));(`trade;flip `time`sym!(`time$();0#`)));
    `.snap.cfg.snapMinuteBase mock 1;
    `.snap.lastSnapTs mock `tick1`tick1!(12:00:00.000-2*60000;12:00:00.000-2*60000);
    `.snap.cfg.src2dst mock `quote`trade`trade2!`quote`tradeSnap`tradeSnap2;
    `.snap.cfg.table2src mock `tick1`tick1!(`quote`trade;enlist `trade2);
    `.stream.cacheNames mock `trade`quote`trade2!`.cache.trade`.cache.quote`.cache.trade2;
    .tst.mockFunc[`.stream.savepoint;1;""];
    .tst.mockFunc[`.stream.pub;2;""];
    `.cache.trade mock ([] time:((2#12:00:00.000+2*60000),2#12:00:00.000+2*60000);sym:`a`a`b`b; price:1 2 10 20 );
    `.cache.trade2 mock ([] time:((2#12:00:00.000+2*60000),2#12:00:00.000+3*60000);sym:`a`a`b`b; price:1 2 10 20 );
    `.cache.quote mock ([] time:((2#12:00:00.000+2*60000),2#12:00:00.000+3*60000);sym:`a`a`b`b; price:1 2 10 20 );
    };
  after{
    delete from `.cache.trade;delete from `.cache.quote;
    };
  should["calculate and publish snap data"]{
    .stream.plug.ts[.z.p];
    .snap.lastSnapTs mustmatch  `tick1`tick1!12:02:00.000 12:03:00.000;
    (`quote;flip `time`sym`price!(enlist 12:02:00.000;enlist `a;enlist 2j)) mustmatch .tst.trace[`.stream.pub][0];
    (`tradeSnap;flip `time`sym`price!(12:02:00.000 12:02:00.000;`a`b;2 20j)) mustmatch .tst.trace[`.stream.pub][1];
    };
  should["delete cache"]{
    .stream.plug.ts[.z.p];
    0 2 4 mustmatch count each (.cache.trade;.cache.quote;.cache.trade2);
    };
  should["call savepoint"]{
    .stream.plug.ts[.z.p];
    (`tick1`tick1!12:02:00.000 12:03:00.000) mustmatch .tst.trace[`.stream.savepoint][0;0];
    (``trade`trade2`quote!(::;flip `time`sym`price!(`time$();0#`;`long$());flip `time`sym`price!(12:02:00.000 12:02:00.000 12:03:00.000 12:03:00.000;`a`a`b`b;1 2 10 20);flip `time`sym`price!(12:03:00.000 12:03:00.000;`b`b;10 20j))) mustmatch .tst.trace[`.stream.savepoint][0;1];
    };
  should["handle signal during data publishing"]{
    .tst.mockFunc[`.stream.pub;2;"'unexpected"];
    .stream.plug.ts[.z.p];
    .snap.lastSnapTs mustmatch `tick1`tick1!12:02:00.000 12:03:00.000;
    (`quote;flip `time`sym`price!(enlist 12:02:00.000;enlist `a;enlist 2j)) mustmatch .tst.trace[`.stream.pub][0];
    (`tradeSnap;flip `time`sym`price!(12:02:00.000 12:02:00.000;`a`b;2 20j)) mustmatch .tst.trace[`.stream.pub][1];
    (`tradeSnap2;flip `time`sym`price!(12:02:00.000 12:03:00.000;`a`b;2 20j)) mustmatch .tst.trace[`.stream.pub][2];
    0 2 0 mustmatch count each (.cache.trade;.cache.quote;.cache.trade2);
    (`tick1`tick1!12:02:00.000 12:03:00.000) mustmatch .tst.trace[`.stream.savepoint][0;0];
    (``trade`trade2`quote!(::;flip `time`sym`price!(`time$();0#`;`long$());flip `time`sym`price!(`time$();0#`;`long$());flip `time`sym`price!(12:03:00.000 12:03:00.000;`b`b;10 20j))) mustmatch .tst.trace[`.stream.savepoint][0;1];
    };
  };


.tst.desc["eod plugin for stream snap - .stream.plug.eod"]{
  before{
    .tst.loadLib[`streamSnap.q];
    `.snap.cfg.snapMinuteBase mock 1;
    `.snap.lastSnapTs mock `tick1`tick1!(12:00:00.000-2*60000;12:00:00.000-2*60000);
    `.snap.cfg.src2dst mock `quote`trade!`quote`tradeSnap;
    `.stream.cacheNames mock `trade`quote!`.cache.trade`.cache.quote;
    .tst.mockFunc[`.stream.savepoint;1;""];
    .tst.mockFunc[`.stream.pub;2;""];
    `.cache.trade mock ([] time:((2#12:00:00.000+2*60000),2#12:00:00.000+2*60000);sym:`a`a`b`b; price:1 2 10 20 );
    `.cache.quote mock ([] time:((2#12:00:00.000+2*60000),2#12:00:00.000+3*60000);sym:`a`a`b`b; price:1 2 10 20 );
    .stream.plug.eod[.z.d];
    };
  should["calculate and publish snap data"]{
    (`quote;flip `time`sym`price!(12:02:00.000 12:03:00.000;`a`b;2 20j)) mustmatch .tst.trace[`.stream.pub][0];
    (`tradeSnap;flip `time`sym`price!(12:02:00.000 12:02:00.000;`a`b;2 20j)) mustmatch .tst.trace[`.stream.pub][1];
    };
  should["cleanup of internal buffers"]{
    0 mustmatch/: count each (.cache.trade;.cache.quote);
    .snap.lastSnapTs mustmatch enlist[`tick1]!enlist[00:00:00.000];
    };
  should["clear savepoint"]{
    (::) mustmatch .tst.trace[`.stream.savepoint][0];
    };
  };

/------------------------------------------------------------------------------/
/.tst.report