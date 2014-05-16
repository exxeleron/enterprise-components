// q stream_test.q --noquit -p 5001

\l lib/qspec/qspec.q

/------------------------------------------------------------------------------/
.tst.desc["streamAggr plugin"]{
  before{
    .sl.noinit:1b;
    `.stream.cfg.timeout mock 1000;
    `.stream.cfg.tsInterval mock 1000;
    `.stream.cfg.serverAux mock enlist`;
    `.stream.cfg.journal mock `:data/jrn;
    `.stream.cfg.savepointFile mock `:data/savepoint;
    `.stream.cfg.srcTab mock ([]server:enlist`tickHF; tab:enlist`trade);
    `.stream.cfg.model mock enlist (`trade; ([]time:`time$(); sym:`symbol$();price:`float$()));
    system"l stream.q";
    `.hnd.hopen mock {[servers;tmout;flag]0N!(`hopen;servers;tmout;flag)};
    `.hnd.h mock {[s] .hmock[s]};

    `:data/srcJrn set ();
    .hmock.tickHF:{[x]
      0N!(`tickHF;x);
      if[x~"`sub in key `.u";:1b];
      if[x~"`sub in key `.tickLF";:0b];
      if[x~"(.u.sub'[`trade;`];`.u `i`L)";:(.stream.cfg.model;(0;`:data/srcJrn))];
      '"unsupported call:", x;
      };
    };
  after{
    .stream.i:.u.i:0;
    hclose .stream.p.jrnH;
    system "rm data -rf";
    };
  should["aggregation, no subscribers"]{
    system"l streamAggr.q";
    //stream initialization 
    .stream.p.init[];
    tables[] mustmatch enlist`trade;
    trade mustmatch .cache.trade;
    0 mustmatch count .cache.trade;
    0 mustmatch .stream.i;
    0j mustmatch .u.i;
    .stream.p.jrn mustmatch `$string[.stream.cfg.journal],string[.z.d];
    .stream.p.jrnH mustne 0N;
    .u.L mustmatch .stream.p.jrn;
    .stream.srcServers mustmatch enlist`tickHF;

    //po from data source = subscription
    .stream.p.po.tickHF[`tickHF];
    system"t 0";

    //data update 1
    d1:([]time:08:00:00.000 08:00:01.000; sym:`s1`s2; price:1. 2.);
    upd[`trade;d1];

    2 mustmatch count .cache.trade;
    1 mustmatch .stream.i;
    0j mustmatch .u.i;
    get[.u.L] mustmatch ();

    //data update 2
    d2:([]time:08:00:02.000 08:00:03.000; sym:`s1`s2; price:3. 4.);
    upd[`trade;d2];

    4 mustmatch count .cache.trade;
    2 mustmatch .stream.i;
    0j mustmatch .u.i;
    get[.u.L] mustmatch ();

    //timer callback 1
    .stream.plug.ts[0N];
    
    0 mustmatch count .cache.trade;
    2 mustmatch .stream.i;
    1j mustmatch .u.i;
    
    get[.u.L] mustmatch enlist(`jUpd;`trade;d1,d2);

    //client subscription
    .stream.cfg.model[0] mustmatch .u.sub[`trade;`];
    .u.w[`trade] mustmatch enlist(0i;`);

    //data update 2
    d3:([]time:08:00:04.000 08:00:05.000; sym:`s1`s2; price:5. 6.);
    upd[`trade;d3];

    2 mustmatch count .cache.trade;
    3 mustmatch .stream.i;
    1j mustmatch .u.i;
    get[.u.L] mustmatch enlist(`jUpd;`trade;d1,d2);

    //timer callback 1
    .stream.plug.ts[0N];
    
    0 mustmatch count .cache.trade;
    //    3 mustmatch 0N!.stream.i;
    2j mustmatch .u.i;
    
    get[.u.L] mustmatch ((`jUpd;`trade;d1,d2);(`jUpd;`trade;d3));

    //reconnect = po from data source = subscription
    //- start from previous savepoint again
    //    .stream.p.po.tickHF[`tickHF];
    //    system"t 0";


    };
  };

