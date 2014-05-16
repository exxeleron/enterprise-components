// q test/stream_test.q --noquit -p 5001

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
    .sl.relib[`$"qsl/u"];
    .tst.loadLib[`stream.q];
    .tst.mockFunc[`.hnd.hopen;3;""];
    `.stream.cfg.timeout mock 100i;
    `.stream.cfg.serverAux mock enlist`rdb;
    `.stream.cfg.tsInterval mock 1000;

    `.tmp.trade mock ([]time:`time$(); sym:`symbol$();price:`float$());
    `.tmp.quote mock ([]time:`time$(); sym:`symbol$();bid:`float$());
    `.stream.cfg.model mock ((`trade;.tmp.trade);(`quote;.tmp.quote));
    `.stream.cfg.srcTab mock ([]server:`tick1`tick1;tab:`trade`quote;subType:`tickHF`tickHF;subType:`tickHF`tickHF);

    `.stream.date mock 2012.01.10;

    .tst.mockFunc[`.stream.plug.init;0;""];
    };
  after{
    .tst.rm[`:test/data];
    };
  should["initialize stream - .stream.p.init[]"]{
    .stream.p.init[];
    .stream.p.srcSubscriptionOn mustmatch 1b;
    .tst.trace[`.stream.plug.init] mustmatch enlist ();
    .cb.status[`.hnd.po.tick1][`function] mustmatch enlist `.stream.p.TickHFPo;
    .stream.srcServers mustmatch enlist`tick1;
    .tst.trace[`.hnd.hopen] mustmatch ((enlist`tick1;100i;`eager);(enlist`rdb;100i;`lazy));
    };
  should["initialize stream without subscription - .stream.p.init[], .stream.srcSubscriptionOff[]"]{
    .tst.mockFunc[`.stream.plug.init;0;".stream.srcSubscriptionOff[]"];

    .stream.p.init[];
    .stream.p.srcSubscriptionOn mustmatch 0b;
    .tst.trace[`.stream.plug.init] mustmatch enlist ();
    .cb.status[`.hnd.po.tick1][`function] mustmatch enlist `.stream.p.TickHFPo;
    .stream.srcServers mustmatch enlist`tick1;
    .tst.trace[`.hnd.hopen] mustmatch (enlist (enlist`rdb;100i;`lazy));
    };
  should["initialize publishing one table - .stream.initPub[]"]{
    .stream.initPub[(enlist (`quote;.tmp.quote))];
    quote mustmatch .tmp.quote;
    `g mustmatch attr quote`sym;
    .u.w mustmatch enlist[`quote]!(enlist());
    .u.t mustmatch enlist`quote;
    };
  should["initialize publishing two tables - .stream.initPub[]"]{
    .stream.initPub[.stream.cfg.model];
    trade mustmatch .tmp.trade;
    quote mustmatch .tmp.quote;
    `g mustmatch attr trade`sym;
    `g mustmatch attr quote`sym;
    .u.w mustmatch `trade`quote!(();());
    .u.t mustmatch `trade`quote;
    };
  should["initialize publishing one table without sym column - .stream.initPub[]"]{
    pubWithoutSym:{.stream.initPub[model:(enlist (`quote;delete sym from .tmp.quote))]};
    mustthrow["missingSymCol";pubWithoutSym];
    };
  should["initialize journaling - .stream.p.initJrn[]"]{
    `.stream.cfg.journal mock `:test/data/jrn;
    .stream.p.initJrn[2012.01.01];
    .u.L mustmatch `:test/data/jrn2012.01.01;
    .stream.p.jrn mustmatch .u.L;
    .u.i mustmatch 0j;
    () mustmatch get .stream.p.jrn;

    .stream.p.jrnH enlist (`test;`data;1 2 3);
    .stream.p.initJrn[2012.01.01];
    .u.L mustmatch `:test/data/jrn2012.01.01;
    .stream.p.jrn mustmatch .u.L;
    (enlist (`test;`data;1 2 3j)) mustmatch get .stream.p.jrn;
    .u.i mustmatch 1j;

    .stream.p.initJrn[2012.01.02];
    .u.L mustmatch `:test/data/jrn2012.01.02;
    .stream.p.jrn mustmatch .u.L;
    .u.i mustmatch 0j;
    () mustmatch get .stream.p.jrn;
    };
  should["perform eod process - .u.end[]"]{
    `.stream.cfg.journal mock `:test/data/jrn;
    .stream.p.initJrn[2012.01.01];
    .tst.mockFunc[`.stream.plug.ts;1;""];
    .tst.mockFunc[`.stream.plug.eod;1;""];
    .tst.mockFunc[`.u.endPublish;1;""];
    .u.end[2012.01.10];
    .u.L mustmatch `:test/data/jrn2012.01.11;
    .tst.trace[`.stream.plug.ts]mustmatch (enlist 2012.01.10+24:00:00.000);
    .tst.trace[`.stream.plug.eod]mustmatch enlist 2012.01.10;
    .tst.trace[`.u.endPublish]mustmatch enlist 2012.01.10;
    };
  should["publish data - .stream.pub[]"]{
    .tst.mockFunc[`.stream.p.jrnH;1;""];
    .tst.mockFunc[`.u.pub;2;""];
    `.u.i mock 0j;
    data:([]c:1 2 3);
    .stream.pub[`table;data];
    .u.i mustmatch 1j;
    .tst.trace[`.u.pub]mustmatch enlist (`table;data);
    .tst.trace[`.stream.p.jrnH]mustmatch enlist enlist (`jUpd;`table;value flip data);
    };
  should["initialize `lowLevel mode - .stream.initMode[]"]{
    .stream.initMode[`lowLevel];
    .stream.mode mustmatch `lowLevel;
    };
  should["initialize `cache mode - .stream.initMode[]"]{
    .stream.initMode[`cache];
    .stream.mode mustmatch `cache;
    .stream.cacheNames mustmatch `trade`quote!`.cache.trade`.cache.quote;
    .cache.trade mustmatch .tmp.trade;
    .cache.quote mustmatch .tmp.quote;
    };
  should["initialize `unsupportedMode mode - .stream.initMode[]"]{
    .tst.mockFunc[`.log.error;2;""];
    .stream.initMode[`unsupportedMode];
    .tst.trace[`.log.error]mustmatch enlist (`stream;"mode not supported:unsupportedMode");
    };
  should["execute savepoint - .stream.savepoint[]"]{
    `.stream.cfg.savepointFile mock `:test/data/savepoint;
    `.stream.i mock `a`b!1 2i;
    data:(1;2;`data);
    .stream.savepoint[data];
    (.stream.i;data) mustmatch get `$":test/data/savepoint", string .stream.date;
    };
  should["subscribe (no savepoint data) - .stream.p.sub[]"]{
    `.stream.cfg.model mock enlist((`trade;.tmp.trade));
    `.stream.cfg.srcTab mock 1#([]server:`tick1`tick1;tab:`trade`quote;subType:`tickHF`tickHF;subType:`tickHF`tickHF);
    `.stream.cfg.tsInterval mock 100i;
    `.stream.cfg.savepointFile mock `:test/data/savepoint;
    .tst.mockFunc[`.stream.plug.sub;3;""];

    .stream.p.sub[`tick1;`];
    .stream.i mustmatch enlist[`trade]!enlist[0j];
    upd  mustmatch .stream.p.upd;
    jUpd mustmatch .stream.p.jUpd;
    .stream.lastTs mustmatch 00:00:00.000;
    .cache[.stream.cfg.model[;0]] mustmatch .stream.cfg.model[;1];
    .tst.trace[`.stream.plug.sub] mustmatch enlist (`tick1;`;::);
    };
  should["subscribe (savepoint data) - .stream.p.sub[]"]{
    `.stream.cfg.model mock enlist((`trade;.tmp.trade));
    `.stream.cfg.srcTab mock 1#([]server:`tick1`tick1;tab:`trade`quote;subType:`tickHF`tickHF;subType:`tickHF`tickHF);
    `.stream.cfg.tsInterval mock 100i;
    `.stream.cfg.savepointFile mock `:test/data/savepoint;
    .tst.mockFunc[`.stream.plug.sub;3;""];
    (`$string[.stream.cfg.savepointFile],string[.stream.date]) set (`trade`quote!1 2i;`savepointData);
    .stream.p.sub[`tick1;`];
    .stream.i mustmatch enlist[`trade]!enlist[0j];
    upd  mustmatch .stream.p.upd;
    jUpd mustmatch .stream.p.jUpd;
    .stream.lastTs mustmatch 00:00:00.000;
    .cache[.stream.cfg.model[;0]] mustmatch .stream.cfg.model[;1];
    .tst.trace[`.stream.plug.sub] mustmatch enlist (`tick1;`;`savepointData);
    };
  };
.tst.desc["simulate data processing"]{
  before{
    .tst.loadLib[`stream.q];
    `.tmp.trade mock ([]time:`time$(); sym:`symbol$();price:`float$());
    `.tmp.quote mock ([]time:`time$(); sym:`symbol$();bid:`float$());
    `.stream.cfg.model mock ((`trade;.tmp.trade);(`quote;.tmp.quote));
    `.stream.cfg.srcTab mock ([]server:`tick1`tick1;tab:`trade`quote;subType:`tickHF`tickHF;subType:`tickHF`tickHF);
    `.stream.cfg.tsInterval mock 1000;

    .stream.initMode[`cache];
    `.stream.i mock `trade`quote!10 12j;
    `.tmp.upd mock ([]time:12:00:00.000 12:00:00.000; sym:`a`b;price:1 2f);
    .tst.mockFunc[`.stream.plug.ts;1;""];
    };
  after{
    };
  should["replay callback with unsupported table - .stream.p.jUpd[]"]{
    .stream.p.jUpd[`unsupportedTable;value flip .tmp.upd]
    .stream.i mustmatch `trade`quote!10 12j;
    };
  should["replay callback without skipping, without timer trigger - .stream.p.jUpd[]"]{
    `.stream.skip mock `trade`quote!0 0j;
    `.stream.lastTs mock 11:59:59.500;

    .stream.p.jUpd[`trade;value flip .tmp.upd];
    .stream.i mustmatch `trade`quote!12 12j;
    .cache.trade mustmatch .tmp.upd;
    //ts not invoked - tsInterval didn't 'pass' yet
    .stream.lastTs mustmatch 11:59:59.500;
    .tst.trace[`.stream.plug.ts] mustmatch ();
    };
  should["replay callback without skipping, with timer trigger  - .stream.p.jUpd[]"]{
    `.stream.skip mock `trade`quote!0 0j;
    `.stream.lastTs mock 11:59:00.000;
    `.stream.date mock 2012.01.01;
    .stream.p.jUpd[`trade;value flip .tmp.upd];
    .stream.i mustmatch `trade`quote!12 12j;
    .cache.trade mustmatch .tmp.upd;
    .stream.lastTs mustmatch 12:00:00.000;
    .tst.trace[`.stream.plug.ts] mustmatch enlist 2012.01.01+12:00:00.000;
    };
  should["replay callback with skipping - .stream.p.jUpd[]"]{
    `.stream.skip mock `trade`quote!12 12j;
    `.stream.lastTs mock 11:59:59.500;

    .stream.p.jUpd[t:`trade;value flip .tmp.upd];
    .stream.i mustmatch `trade`quote!12 12j;
    count[.cache.trade] mustmatch 0;
    .stream.lastTs mustmatch 11:59:59.500;
    .tst.trace[`.stream.plug.ts] mustmatch ();
    };
  should["cache: perform live data update - .stream.p.upd[]"]{ 
    .stream.p.upd[`trade;.tmp.upd];
    .cache.trade mustmatch .tmp.upd;
    .stream.i mustmatch `trade`quote!12 12j;

    .stream.p.upd[`trade;.tmp.upd];
    .cache.trade mustmatch 4#.tmp.upd;
    .stream.i mustmatch `trade`quote!14 12j;
    };
  };
/------------------------------------------------------------------------------/
