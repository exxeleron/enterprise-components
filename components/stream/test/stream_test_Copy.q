// q stream_test.q --noquit -p 5001

\l lib/qspec/qspec.q

/------------------------------------------------------------------------------/
.tst.hnd.clients:([] server:0#`;host:0#`;port:0#0N);
`.tst.hnd.clients insert (`tickRtr`tickPlus`rdbRtr;`localhost`localhost`localhost;5002 5003 5004);
//.tst.hnd.clients
/------------------------------------------------------------------------------/
/F/ Runs q process.
/E/ srvr:.tst.hnd.clients[`server]
/E/ srvr:.tst.hnd.clients[0;`server]
/E/ .tst.hnd.qstart[srvr]
.tst.hnd.qstart:{[srvr]
  os:.z.o;
  s:exec from .tst.hnd.clients where server=srvr;
  if[os in `w32`w64; cmd:"start q -p ",.Q.s1 s[`port]];
  if[os in `l32`s32`v32`l64`s64`v64;
    cmd:"nohup q -p ",string[s`port]," < /dev/null > ",string[srvr],".std 2> ",string[srvr],".err &";
    .tst.hnd.outRed:1b;
    ];
  system cmd;
  };

/------------------------------------------------------------------------------/
/F/ Stops q process.
/E/ srvr:.tst.hnd.clients[`server]
/E/ srvr:.tst.hnd.clients[0;`server]
/E/ .tst.hnd.qstop[srvr]
.tst.hnd.qstop:{[srvr]
  s:exec from .tst.hnd.clients where server=srvr;
  h:@[hopen;`$":",":" sv string s[`host],s[`port];{}];
  if[0N~h;
    .log.info[`handT] "Cannot connect to port ",string[s `port],".";
    :()];
  // Stop process and for UNIX OS remove all .err and .std files
  @[{x "exit 0"};h;0N];
  if[.z.o in `l32`s32`v32`l64`s64`v64;
    if[.tst.hnd.outRed;
      @[hdel each;`$raze each string (`:,srvr),/:(`.err;`.std);'"ERROR: Could not remove output files:",.Q.s1 srvr];
      ];
    ];
  };

/------------------------------------------------------------------------------/
.tst.desc["stream with one plugin instance"]{
  before{
    //.q.mock:set
    `.plugin.xxx.sub mock `rtrTrade`rtrQuote;
    `.plugin.xxx.hnd mock `rdbRtr`tickRtr;
    `.plugin.xxx.init mock {[subscription]
      `upd set {[tab;data] 0N!(`upd;tab;data)};
      `ts set {[x] 0N!(`ts;x)};
      };

    system["l ../stream.q"];
    `.stream.cfg.mode mock `speed;
    `.stream.cfg.plugin mock `xxx;
    `.plugin.cfg.clones mock enlist[`xxx]!enlist[`mavg50`mavg100];
    `.stream.cfg.subscription mock ([]table:`rtrTrade`rtrQuote`ewxRef; serverName:`tickRtr`tickRtr`tickPlus; serverType:`tick`tick`tickPlus; universe:`);
    `.stream.cfg.conn mock `tickRtr`tickPlus`rdbRtr;
    `.stream.cfg.conn mock `tickRtr`tickPlus`rdbRtr!`::5002`::5003`::5004;
    `.stream.cfg.connTimeout mock 1000;
    `.stream.cfg.timer mock 1000;
    .tst.hnd.qstart each `tickRtr`tickPlus`rdbRtr;
    };
  after{
    .tst.hnd.qstop each `tickRtr`tickPlus`rdbRtr;
    system"t 0";
    };
  should["register one plugin"]{
    h:.tst.hnd.clients[`server]!hopen each .tst.hnd.clients[`port];
    h[`tickRtr]"rtrTrade:([]time:`time$(); sym:`symbol$(); price:`float$(); size:`long$())";
    h[`tickRtr]".u.sub:{[x;y] `h set .z.w; 0N!(`.u.sub;x;y); enlist (`rtrTrade;rtrTrade)}";
    h[`tickPlus]".tp.sub:{[x;y] 0N!(.z.w;x;y)}";
    .stream.init[];
    };
  };
/
.tst.desc["stream with one plugin instance"]{
  before{
    `.stream.cfg.servers mock (enlist`tick)!(enlist`:localhost:5010);
    `.stream.cfg.schedule mock enlist(`tick; `trade; `.tbuff; `inst1; enlist[`N]!enlist[10]);
    `.stream.cfg.universe mock enlist[`tick]!enlist `;
    system["l ../stream.q"];
    .hnd.h[`tick]:{`lastStm set x};
    lastStm:(::);
    `.u.sub set();
    };
  after{
    `trade set();
    `quote set();
    };
  should["init simple plugin, upd.all"]{
    `.tbuff.upd.all mock {x insert y};
    `.tbuff.out mock `.tbuff.tbuff; //TODO: ?
    pl:`.tbuff;
    //test init
    .stream.init[.stream.cfg];
    .stream.register enlist pl;
    .stream.initInstancies[];
    upd mustmatch {x insert y};
    //test stream
    `tab mock([]time:.z.t;sym:`a`b;price:1.0);
    upd[`trade;tab];
    trade mustmatch tab;
    upd[`quote;tab];
    quote mustmatch tab;
    };
  should["init simple plugin, upd.trade"]{
    `.tbuff.upd.trade mock {`.tbuff.tbuff insert x};
    `.tbuff.out mock `.tbuff.tbuff;
    pl:`.tbuff;
    //test init
    .stream.init[.stream.cfg];
    .stream.register enlist pl;
    .stream.initInstancies[];
    upd mustmatch ``trade!(::;{`.tbuff.tbuff insert x});
    //test stream
    `tab mock([]time:.z.t;sym:`a`b;price:1.0);
    upd[`trade;tab];
    .tbuff.tbuff mustmatch tab;
    upd[`quote;tab];
    .tbuff.tbuff mustmatch tab;
    upd[`trade;tab];
    count[.tbuff.tbuff] mustmatch 2*count[tab];
    `.tbuff.tbuff set ();
    };
  should["init simple plugin, upd.trade and upd.quote"]{
    `.tbuff.upd.trade mock {`.tbuff.buffTrade insert x};
    `.tbuff.upd.quote mock {`.tbuff.buffQuote insert x};
    `.tbuff.out mock `.tbuff.buffTrade`.tbuff.buffQuote;
    pl:`.tbuff;
    //test init
    .stream.init[.stream.cfg];
    .stream.register enlist pl;
    .stream.initInstancies[];
    upd mustmatch ``trade`quote!(::;{`.tbuff.buffTrade insert x};{`.tbuff.buffQuote insert x});
    //test stream
    `tab mock([]time:.z.t;sym:`a`b;price:1.0);
    upd[`trade;tab];
    .tbuff.buffTrade mustmatch tab;
    upd[`quote;tab];
    .tbuff.buffQuote mustmatch tab;
    upd[`trade;tab];
    count[.tbuff.buffTrade] mustmatch 2*count[tab];
    `.tbuff.tbuff set ();
    };
  };
