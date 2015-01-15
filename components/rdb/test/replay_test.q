// q test/replay_test.q --noquit -p 5001

\l lib/qspec/qspec.q



.tst.desc["test initialization"]{
  before{
    .sl.noinit:1b;
    @[system;"l replay.q";0N];
    `.replay.cfg.params mock `date`rdb!(enlist".z.d";enlist "core.rdb");
    `.replay.cfg.date mock .z.d;
    `.replay.cfg.rdb mock `core.rdb;
    .tst.mockFunc[`.cr.getCfgPivot;3;"(flip (enlist `sectionVal)!enlist `adjustmentFactors`quote`trade`tradeSnap`universe)!
      flip `subSrc`hdbConn`eodClear`eodPerform!
      (`in.tickHF`in.tickHF1`in.tickLF``;
      `core.hdb``core.hdb2`core.hdb`;10110b;10110b)"];
    `fields mock `cfg.fillMissingTabsHdb`cfg.reloadHdb`libs`dataPath!(1;1b;("test.q";"test/test.q");`:path);
    `processType mock `in.tickHF`in.tickHF1`in.tickLF!`$("q:tickHF/tickHF";"q:tickHF/tickHF";"q:tickLF/tickLF");
    .tst.mockFunc[`.cr.getCfgField;3;"$[a2~`type;processType[a0] ;fields[a2]]"];
    .tst.mockFunc[`.replay.p.findJournaLF;3;"`jrnLF"];
    .tst.mockFunc[`.replay.p.findJournaHF;3;"`jrnHF"];
	`.cr.p.cfgTable mock ([] subsection:`in.tickHF`in.tickHF1`in.tickLF ;varName:`type;  cfgVarValue:("q:tickHF/tickHF";"q:tickHF/tickHF";"q:tickLF/tickLF"));
    .tst.mockFunc[`.cr.getModel;1;"`model"];
    .tst.mockFunc[`.replay.p.restoreData;2;""];
    .tst.mockFunc[`.replay.p.initEodParams;0;"`ok"];
    .tst.mockFunc[`.sl.lib;1;".rdb.plug.beforeEod:`test1`test2!(1 2)"];
    .tst.mockFunc[`.replay.p.eodAct;3;""];
    .tst.mockFunc[`.store.run;1;""];
    .replay.p.run[.replay.cfg];
    };
  should["find journal for tickHF servers"]{
    ((.z.d;`in.tickHF;enlist `adjustmentFactors);(.z.d;`in.tickHF1;enlist `quote)) mustmatch .tst.trace[`.replay.p.findJournaHF];
	};
  should["find journal for tickLF servers"]{
    enlist[(.z.d;`in.tickLF;enlist `trade)] mustmatch .tst.trace[`.replay.p.findJournaLF];
    };
  should["get model for tables that should be replayed"]{
    (`in.tickLF`in.tickHF`in.tickHF1) mustmatch .tst.trace[`.cr.getModel];
    };
  should["restore data from journals"]{
    (`jrnLF`model;`jrnHF`model;`jrnHF`model) mustmatch .tst.trace[`.replay.p.restoreData];
    };
  should["initialize eod parameters"]{
    () mustmatch first .tst.trace[`.replay.p.initEodParams];
    };
  should["load custom libraries"]{
    ("test.q";"test/test.q") mustmatch .tst.trace[`.sl.lib];
    };
  should["perform eod plugins"]{
    ((`beforeEod;`test1;.z.d);(`beforeEod;`test2;.z.d)) mustmatch .tst.trace[`.replay.p.eodAct];
    };
  should["perform eod"]{
    (enlist .z.d) mustmatch .tst.trace[`.store.run];
    };
  };


.tst.desc["test init of  eod parameters - .replay.p.initEodParams"]{
  before{
    .sl.noinit:1b;
    @[system;"l replay.q";0N];
    `.replay.cfg.tables mock (flip (enlist `sectionVal)!enlist `adjustmentFactors`quote`trade`tradeSnap`universe)!
      flip `subSrc`eodPath`hdbConn`eodClear`eodPerform!
      (`in.tickHF`in.tickHF1`in.tickLF``;`:core.hdb``:core.hdb`:core.hdb`;
      `core.hdb``core.hdb2`core.hdb`;10110b;10110b);

    .tst.mockFunc[`.hnd.hopen;3;""];
    .tst.mockFunc[`.store.init;4;""];
    .replay.p.initEodParams[];
    };
  should["init store libraray"]{
    4 mustmatch count first .tst.trace[`.store.init];
    };
  should["open conn to hdb"]{
    enlist[(`core.hdb`core.hdb2;100i;`lazy)] mustmatch .tst.trace[`.hnd.hopen];
    };
  };

.tst.desc["perform eod plugins - .replay.p.eodAct"]{
  before{
    .sl.noinit:1b;
    @[system;"l replay.q";0N];
    .rdb.plug.beforeEod:()!();
    `.tst.trace mock .tst.trace,(enlist[`.rdb.plug.beforeEod.test]!enlist[()]);
    .rdb.plug.beforeEod[`test]:{[x] .tst.trace[`.rdb.plug.beforeEod.test]:x};
    .replay.p.eodAct[`beforeEod;`test;.z.d];
    };
  should["invoke before eod callback"]{
    .z.d mustmatch .tst.trace[`.rdb.plug.beforeEod.test];
    };
  };

.tst.desc["restore data from tables - .replay.p.restoreData"]{
  before{
    .sl.noinit:1b;
    @[system;"l replay.q";0N];
    .tst.mockFunc[`.replay.p.replay;1;""];
    .replay.p.restoreData[`test;((`trade;([]time:`time$(); sym:`symbol$()));(`quote;([]time:`time$(); sym:`symbol$())))];
    };
  should["apply `g attr on each tables"]{
    `g mustmatch attr quote`sym;
    `g mustmatch attr trade`sym;
    };
  should["call replay function"]{
    enlist[`test] mustmatch .tst.trace`.replay.p.replay;
    };
  should["update global variable .replay.tabs"]{
    `trade`quote mustmatch .replay.tabs;
    };
  };

.tst.desc["find LF journals - .replay.p.findJournaLF"]{
  before{
    .sl.noinit:1b;
     .sl.reinit[`tst];
    @[system;"l replay.q";0N];
    .tst.mockFunc[`.cr.getCfgField;3;"`:test/tmp"];
    `:test/tmp/quote/2013.01.01.ups.quote set ();
    `:test/tmp/trade/2013.01.01.upd.trade set ();
    `:test/tmp/trade/2013.02.01.upd.trade set ();
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["find journal on disk - .replay.p.matchJrnWithDate"]{
    `:test/tmp/quote/2013.01.01.ups.quote`:test/tmp/trade/2013.02.01.upd.trade mustmatch .replay.p.findJournaLF[.z.d;`test;tabs:`quote`trade];
    };
  should["discard tables for which journal cannot be found - .replay.p.matchJrnWithDate"]{
    `:test/tmp/quote/2013.01.01.ups.quote`:test/tmp/trade/2013.02.01.upd.trade mustmatch .replay.p.findJournaLF[.z.d;`test;tabs:`quote`trade`test];
    .tst.mockFunc[`.log.warn;2;""];
    () mustmatch .replay.p.findJournaLF[2013.01.01;`test;enlist`test];
    "Journal that matches date 2013.01.01 and table test couldn't be found" mustmatch .tst.trace[`.log.warn][0;1];
    };
  };

.tst.desc["find HF journals - .replay.p.findJournaHF"]{
  before{
    .sl.noinit:1b;
    .sl.reinit[`tst];
    @[system;"l replay.q";0N];
    .tst.mockFunc[`.cr.getCfgField;3;"`:test/tmp"];
    `:test/tmp/test2013.01.01 set ();
    `:test/tmp/test2013.02.01 set ();
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["find journal on disk"]{
    enlist[`:test/tmp/test2013.02.01] mustmatch .replay.p.findJournaHF[2013.02.01;`test;tabs:`quote`trade];
    };
  should["return empty list if journal cannot be found"]{
    .tst.mockFunc[`.log.warn;2;""];
    () mustmatch .replay.p.findJournaHF[2013.02.02;`test;tabs:`quote`trade];
    "Journal that matches date 2013.02.02 and process test couldn't be found" mustmatch .tst.trace[`.log.warn][0;1];
    };
  
  };

.tst.desc["replay data from tickHF/tickLF journals to memory"]{
  before{
    sl.noinit:1b;
    @[system;"l replay.q";0N];
    .tst.mockFunc[`.replay.p.initEodParams;0;"`ok"];
    .tst.mockFunc[`.sl.lib;1;".rdb.plug.beforeEod:`test1`test2!(1 2)"];
    .tst.mockFunc[`.replay.p.eodAct;3;""];
    .tst.mockFunc[`.store.run;1;""];
    
    `.replay.cfg.params mock `date`rdb!(enlist".z.d";enlist "core.rdb");
    `.replay.cfg.date mock .z.d;
    `.replay.cfg.rdb mock `core.rdb;
    .tst.mockFunc[`.cr.getCfgPivot;3;"(flip (enlist `sectionVal)!enlist `adjustmentFactors`quote`trade`tradeSnap`universe)!
      flip `subSrc`hdbConn`eodClear`eodPerform!
      (`in.tickLF`in.tickHF```;
      `core.hdb``core.hdb2`core.hdb`;10110b;10110b)"];
    `fields mock `cfg.fillMissingTabsHdb`cfg.reloadHdb`command`dataPath!(1;1b;" -lib test.q test/test.q ";`:path);
    `processType mock `in.tickHF`in.tickHF1`in.tickLF!`$("q:tickHF/tickHF";"q:tickHF/tickHF";"q:tickLF/tickLF");
    .tst.mockFunc[`.cr.getCfgField;3;"$[a2~`type;processType[a0] ;fields[a2]]"];
	`.cr.p.cfgTable mock ([] subsection:`in.tickHF`in.tickLF ;varName:`type;  cfgVarValue:("q:tickHF/tickHF";"q:tickLF/tickLF"));
    .tst.mockFunc[`.cr.getModel;1;"d:`in.tickLF`in.tickHF!(enlist (`adjustmentFactors;([] sym:`$();factor:()));enlist (`quote;([] sym:`$();price:())));d[ a0]"];
    .tst.mockFunc[`.sl.lib;1;".rdb.plug.beforeEod:`test1`test2!(1 2)"];
    .tst.mockFunc[`.store.run;1;""];
    `:test/tmp/adjustmentFactors/2013.01.01.upd.adjustmentFactors set ();
    hlf:hopen `:test/tmp/adjustmentFactors/2013.01.01.upd.adjustmentFactors;
    hlf enlist  (`upd;`adjustmentFactors;(`a`a;1 1));
    `:test/tmp/2013.01.01tickHF set ();
    hhf:hopen `:test/tmp/2013.01.01tickHF;
    hhf enlist (`upd;`quote;(`a`a;1 1));
    hclose each (hhf;hlf);
    `upd mock {x insert y};
    .tst.mockFunc[`.replay.p.findJournaLF;3;"enlist `:test/tmp/adjustmentFactors/2013.01.01.upd.adjustmentFactors"];
    .tst.mockFunc[`.replay.p.findJournaHF;3;"enlist `:test/tmp/2013.01.01tickHF"];
    .replay.p.run[.replay.cfg];
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["replay data from tickHF journal"]{
    count[quote] mustmatch 2;
    };
  should["replay data from tickLF journal"]{
    count[adjustmentFactors] mustmatch 2;
    };
  };

/
.tst.report




