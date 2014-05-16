// q test/tickLF_test.q -noinit --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q
.sl.init[`test];

//dir:`:test/tmp
/.tst.rm[dir]
.tst.rm:{[dir]
  if["w"~first string .z.o;
    cmd:"rmdir /S /Q ", ssr[1_string dir;"/";"\\"];
    .log.debug "Call command ", cmd;
    system cmd;
    ];
  if[first[ string .z.o] in "sl";
    cmd:"rm -rf ", 1_string dir;
    .log.debug "Call command ", cmd;
    system cmd;
    ];
  };


.tst.desc["test initialization"]{
  before{
    .sl.noinit:1b;
    @[system;"l tickLF.q";0N];
    `.tickLF.cfg.tables mock flip`table`validation`jrnSwitch`eodImg2Jrn`memory`status!flip 
    ((`universe;1b;`eod`img;1b;1b;1b)
      ;(`underlyings;0b;`off;0b;0b;0b)
      ;(`calendar;1b;`img;1b;0b;1b));
    `.tickLF.cfg.jrn mock `:test/tmp/;
    `universe mock ([]time:`time$();sym:`symbol$();mat:`date$());
    `underlyings mock ([]time:`time$();sym:`symbol$();underSym:`symbol$());
    `calendar mock ([]time:`time$();sym:`symbol$();isTrd:`boolean$());
    `config mock `tables`jrn!(.tickLF.cfg.tables;.tickLF.cfg.jrn);
    `tabs mock config[`tables][`table];
    `dirs mock ` sv/:.tickLF.cfg.jrn,/:tabs;
    `.tickLF.cfg.timer mock 100;
    };
  after{
    hclose each value .tickLF.jrnHnd;
    .tst.rm[`:test/tmp];
    system"t 0";
    };
  should["init journals: create new journals"]{
    .tickLF.p.init[config];
    (asc tabs) mustmatch key .tickLF.cfg.jrn;
    1b mustmatch all all key'[dirs] like'"*.ini.",/:string[tabs];
    };
  should["init journals: load one journal and create missing ones"]{
    f:`2011.01.01T10.00.00.000.img.universe;
    jrn:` sv .tickLF.cfg.jrn,`universe,f;
    .[jrn;();:;()];
    .tickLF.p.init[config];
    (asc tabs) mustmatch key .tickLF.cfg.jrn;
    1b mustmatch all all key'[1_dirs] like'"*.ini.",/:string[1_tabs];
    enlist [f] mustmatch  key[first dirs];
    1b mustmatch all not null .tickLF.jrnHnd[tabs];
    0 mustmatch/:.tickLF.jrnI[tabs];
    };
  should["laod proper validation/journal/status action functions"]{
    .tickLF.plug.enrich[`universe]:{[x] .log.debug[`tickPT] "enrich", .Q.s1[x];x};
    .tickLF.plug.validate[`universe]:{[x] .log.debug[`tickPT] "validate", .Q.s1[x];x};
    .tickLF.p.init[config];
    `universe`underlyings`calendar mustmatch key .tickLF.validate;
    `universe`underlyings`calendar mustmatch key .tickLF.validateDel;
    {[x;y;z]y:.tickLF.plug.enrich[x;y];.tickLF.plug.validate[x;y];.tickLF.p.standardValidation[x;y;z];:(y)}[`universe] mustmatch .tickLF.validate[`universe];
    {[x;y;z].tickLF.p.standardValidation[x;y;z];:(y)}[`calendar] mustmatch .tickLF.validate[`calendar];
    12 mustmatch count .tickLF.actionJrn;
    {[x;y;z] .tickLF.p.switchJrn[x;y]; .tickLF.p.updJrn[x;y;z]}[`universe;`.tickLF.jImg] mustmatch .tickLF.actionJrn[`universe`.tickLF.img];
    {[x;y;z] .tickLF.p.switchJrn[x;y]; .tickLF.p.updJrn[x;y;z]}[`calendar;`.tickLF.jImg] mustmatch .tickLF.actionJrn[`calendar`.tickLF.img];
    {[x;y;z] .tickLF.p.updJrn[x;y;z]}[`underlyings;`.tickLF.jImg] mustmatch .tickLF.actionJrn[`underlyings`.tickLF.img];
    {[x;y;z] .tickLF.p.updJrn[x;y;z]}[`calendar;`.tickLF.jUpd] mustmatch .tickLF.actionJrn[`calendar`.tickLF.upd];
    `universe`calendar mustmatch key .tickLF.updStatus;
    {[x;y;z].tickLF.plug.validate[x;z];.tickLF.p.standardValidation[x;y;z]}[`universe] mustmatch .tickLF.validateDel[`universe];
    {[x;y;z].tickLF.p.standardValidation[x;y;z]}[`calendar] mustmatch .tickLF.validateDel[`calendar];
    {[x;y;z] }[`underlyings] mustmatch .tickLF.validateDel[`underlyings];
    };
  should["add tables to global variables"]{
    .tickLF.p.init[config];
    tabs mustmatch .tickLF.t;
    tabs mustmatch key .tickLF.w;
    };
  should["add tables that should be kept in memory"]{
    .tickLF.p.init[config];
    enlist[(0;`)] mustmatch .tickLF.w[`universe];
    .tickLF.p.add[`universe;`;1];
    .tickLF.p.init[config];
    tabs mustmatch .tickLF.t;
    tabs mustmatch key .tickLF.w;
    ((0;`);(1;`)) mustmatch .tickLF.w[`universe];
    `.tickLF.cfg.tables mock flip`table`validation`jrnSwitch`eodImg2Jrn`memory`status!flip 
    ((`universe;1b;`eod`img;1b;1b;1b)
      ;(`underlyings;0b;`off;0b;0b;0b)
      ;(`calendar;1b;`img;1b;0b;1b)
      ;(`test;1b;`img;1b;0b;1b));
    `config mock `tables`jrn!(.tickLF.cfg.tables;.tickLF.cfg.jrn);
    `test mock ([] time:(); sym:`symbol$());
    .tickLF.p.init[config];
    (tabs,`test) mustmatch .tickLF.t;
    4 mustmatch count .tickLF.w;
    hclose .tickLF.jrnHnd[`test];`.tickLF.jrnHnd mock -1_.tickLF.jrnHnd;
    };
  };

.tst.desc["test publishing data"]{
  before{
    .sl.noinit:1b;
    @[system;"l tickLF.q";0N];
    `.tickLF.cfg.tables mock flip`table`validation`jrnSwitch`eodImg2Jrn`memory`status!flip 
    ((`universe;1b;`eod`img;1b;1b;1b)
      ;(`underlyings;0b;`off;0b;0b;0b)
      ;(`calendar;1b;`img;1b;0b;1b));
    `.tickLF.cfg.jrn mock `:test/tmp/;
    `.tickLF.cfg.timer mock 100;
    `universe mock ([]time:`time$();sym:`symbol$();mat:`date$());
    `underlyings mock ([]time:`time$();sym:`symbol$();underSym:`symbol$());
    `calendar mock ([]time:`time$();sym:`symbol$();isTrd:`boolean$());
    `config mock `tables`jrn!(.tickLF.cfg.tables;.tickLF.cfg.jrn);
    `.tickLF.cfg.types mock `universe`underlyings`calendar!("tsd";"tss";"tsb");
    `tabs mock config[`tables][`table];
    `dirs mock ` sv/:.tickLF.cfg.jrn,/:tabs;
    `enrich mock ();`validate mock ();
    .tickLF.plug.enrich[`universe]:{[x] enrich,::enlist x;x};
    .tickLF.plug.validate[`universe]:{[x] validate,::enlist x};
    `.tickLF.plug.validate mock .tickLF.plug.validate;
    `.tickLF.plug.enrich mock .tickLF.plug.enrich;
    .tickLF.p.init[config];
    };
  after{
    hclose each value .tickLF.jrnHnd;
    .tst.rm[`:test/tmp];
    system"t 0";
    };
  should["perform plugin enrich"]{
    .tickLF.pubUpd[`underlyings;(.z.t ;`a; .z.d)];
    () mustmatch enrich;
    .tickLF.pubUpd[`universe;d:(.z.t ;`a; .z.d)];
    enlist[d] mustmatch enrich;
    1 mustmatch count universe;
    };
  should["perform plugin validation"]{
    .tickLF.pubUpd[`underlyings;(.z.t ;`a; .z.d)];
    () mustmatch validate;
    .tickLF.pubUpd[`universe;d:(.z.t ;`a; .z.d)];
    enlist[d] mustmatch validate;
    1 mustmatch count universe;
    };
  should["perform plugin validation with del"]{
    /![`underlyings;enlist ( in;`sym;enlist `a`b);0b;0#`]
    /parse "delete from `underlyings where sym in `a`b"
    .tickLF.pubDel[`underlyings;enlist ( in;`sym;enlist `a`b);0b;0#`];
    () mustmatch validate;
    /parse"delete from `universe where sym in `a`b, mat>.z.d"
    /(!;enlist `universe;enlist (( in;`sym;enlist `a`b);(>;`mat;.z.d));0b;0#`)
    //        /t:`universe;c:(( ;`sym;enlist `a`b);(>;`mat;`.z.d));b:0b;a:0#`
    .tickLF.pubDel[`universe;((in ;`sym;enlist `a`b);(>=;`mat;.z.d));0b;0#`];
    enlist[(`.tickLF.del;((in ;`sym;enlist `a`b);(>=;`mat;.z.d));0b;0#`)] mustmatch validate;
    };
  
  should["perform standard validation"]{
    .tickLF.pubUpd[`underlyings;(.z.t ;`a; .z.d)];
    .tickLF.pubUpd[`universe;d:(.z.t ;`a; .z.d)];
    d mustmatch raze value flip universe;
    .tickLF.pubUps[`universe;d:(.z.t ;`a; .z.d+1);c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    d mustmatch raze value flip universe;
    };
  should["perform status update"]{
    .tickLF.pubUpd[`underlyings;(.z.t ;`a; .z.d)];
    0N mustmatch .tickLF.PubNo[`underlyings`.tickLF.upd];
    .tickLF.pubUpd[`universe;d:(.z.t ;`a; .z.d)];
    1 mustmatch .tickLF.PubNo[`universe`.tickLF.upd];
    3 mustmatch count .tickLF.status[];
    };
  should["perform update data in memory"]{
    .tickLF.pubUpd[`universe;d:(.z.t ;`a; .z.d)];
    d mustmatch raze value flip universe;
    .tickLF.pubUpd[`universe;newd:(.z.t ;`a; .z.d)];
    (d,newd) mustmatch raze flip value flip universe;
    };
  should["perform upsert data in memory"]{
    .tickLF.pubUps[`universe;d:(.z.t ;`a; .z.d); c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    d mustmatch raze value flip universe;
    .tickLF.pubUps[`universe;d1:(.z.t ;`b; .z.d); c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    (d,d1) mustmatch  raze flip value flip universe;
    .tickLF.pubUps[`universe;d2:(.z.t ;`b; .z.d+1); c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    (d,d2) mustmatch raze flip value flip universe;
    };
  should["perform del in memory"]{
    .tickLF.pubUpd[`universe;d:(.z.t ;`a; .z.d)];
    .tickLF.pubDel[`universe;((in ;`sym;enlist `a`b);(>=;`mat;.z.d));0b;0#`];
    0 mustmatch count universe;
    };
  should["update journal when upd"]{
    .tickLF.pubUpd[`universe;d:(.z.t ;`a; .z.d)];
    d mustmatch raze value flip universe;
    delete from `universe;
    -11!.tickLF.jrn[`universe];
    d mustmatch raze value flip universe;
    j:get .tickLF.jrn[`universe];
    enlist[(`.tickLF.jUpd;`universe;d)] mustmatch j;
    };
  should["update journal when img"]{
    .tickLF.pubImg[`universe;d:(.z.t ;`a; .z.d)];
    d mustmatch raze value flip universe;
    delete from `universe;
    -11!.tickLF.jrn[`universe];
    d mustmatch raze value flip universe;
    j:get .tickLF.jrn[`universe];
    enlist[(`.tickLF.jImg;`universe;d)] mustmatch j;
    };
  should["update journal when ups"]{
    .tickLF.pubUps[`universe;d:(.z.t ;`a; .z.d); c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    j:get .tickLF.jrn[`universe];
    delete from `universe;
    -11!.tickLF.jrn[`universe];
    d mustmatch raze value flip universe;
    enlist[(`.tickLF.jUps;`universe;d;c;b;a)] mustmatch j;
    };
  should["update journal when del"]{
    .tickLF.pubDel[`universe;c:((in ;`sym;enlist `a`b);(>=;`mat;.z.d));b:0b;a:0#`];
    j:get .tickLF.jrn[`universe];
    `universe insert (.z.t;`a;.z.d);
    -11!.tickLF.jrn[`universe];
    0 mustmatch count universe;
    enlist[(`.tickLF.jDel;`universe;c;b;a)] mustmatch j;
    };
  should["switch,update journal when img"]{
    .tickLF.pubImg[`universe;d:(.z.t ;`a; .z.d)];
    j:get .tickLF.jrn[`universe];
    enlist[(`.tickLF.jImg;`universe;d)] mustmatch j;
    10b mustmatch  key[` sv .tickLF.cfg.jrn,`universe] like "[0-9]*ini.universe";
    01b mustmatch  key[` sv .tickLF.cfg.jrn,`universe] like "[0-9]*img.universe";
    // wait until journal will be created with new timestamp
    do[1000;10000%100%til 100000];
    .tickLF.pubImg[`universe;dnew:(.z.t ;`a; .z.d)];
    // wait untill journal will be written on disk
    j:get .tickLF.jrn[`universe];
    enlist[(`.tickLF.jImg;`universe;dnew)] mustmatch j;
    100b mustmatch  key[` sv .tickLF.cfg.jrn,`universe] like "[0-9]*ini.universe";
    011b mustmatch  key[` sv .tickLF.cfg.jrn,`universe] like "[0-9]*img.universe";
    .tickLF.pubImg[`underlyings;d:(.z.t ;`a; .z.d)];
    j:get .tickLF.jrn[`underlyings];
    enlist[(`.tickLF.jImg;`underlyings;d)] mustmatch j;
    (enlist 1b) mustmatch  key[` sv .tickLF.cfg.jrn,`underlyings] like "[0-9]*ini.underlyings";
    (enlist 0b) mustmatch  key[` sv .tickLF.cfg.jrn,`underlyings] like "[0-9]*img.underlyings";
    };
  should["validata data model"]{
    `t mock `universe;
    d:(.z.t;`a;.z.d);
    .tickLF.p.validateModel[t;d];
    d:2#/:(.z.t;`a;.z.d);
    .tickLF.p.validateModel[t;d];
    d:([] time:enlist .z.t;sym:enlist `a;mat:enlist .z.d);
    .tickLF.p.validateModel[t;d];
    `d mock (.z.t;`a);
    mustthrow["Number of columns [universe] is incorrect:2, expected:3";{.tickLF.p.validateModel[t;d]}];
    `d mock (.z.t;`a;`g;`f);
    mustthrow["Number of columns [universe] is incorrect:4, expected:3";{.tickLF.p.validateModel[t;d]}];
    `d mock 2#/:(.z.t;`a;.z.d;`b);
    mustthrow["Number of columns [universe] is incorrect:4, expected:3";{.tickLF.p.validateModel[t;d]}];
    `d mock ([] time:enlist .z.t;sym:enlist `a;test:enlist .z.d);
    mustthrow["Missing columns in [universe]:,`mat, expected:`time`sym`mat";{.tickLF.p.validateModel[t;d]}];
    `d mock ([] time:enlist .z.t;sym:enlist `a;mat:enlist .z.d;test:enlist .z.d);
    mustthrow["Number of columns [universe] is incorrect:4, expected:3";{.tickLF.p.validateModel[t;d]}];
    `d mock ([] time:enlist .z.t;sym:enlist `a;mat:enlist `a);
    mustthrow["Received [universe] type:,(`mat;\"s\"), expected type is: ,(`mat;\"d\")";{.tickLF.p.validateModel[t;d]}];
    `d mock ([] time:enlist .z.t;sym:enlist .z.d;mat:enlist `a);
    mustthrow["Received [universe] type:((`sym;\"d\");(`mat;\"s\")), expected type is: ((`sym;\"s\");(`mat;\"d\"))";{.tickLF.p.validateModel[t;d]}];
    };
  should["validata parameters"]{
    `t mock `universe;
    `fn mock `.tickLF.ups;
    p:(();enlist[`sym]!enlist `sym;`time`mat!`time`mat);
    .tickLF.p.validateParams[t;fn;p];
    `p mock (`a;enlist[`sym]!enlist `sym;`time`mat!`time`mat);
    mustthrow["Function call [.tickLF.ups] table [universe]: evaluation of paramters: (`a;(,`sym)!,`sym;`time`mat!`time`mat) throws an error: type";{.tickLF.p.validateParams[t;fn;p]}];
    `p mock (`a;enlist[`a]!enlist `sym;`time`mat!`time`mat);
    mustthrow["Function call [.tickLF.ups] table [universe]: specified columns:,`a for group-bys don't exist in data model";{.tickLF.p.validateParams[t;fn;p]}];
    `p mock (`a;enlist[`sym]!enlist `sym;`time`test!`time`mat);
    mustthrow["Function call [.tickLF.ups] table [universe]: specified columns:,`test for aggregations don't exist in data model";{.tickLF.p.validateParams[t;fn;p]}];
    };
  should["subscribe to universe"]{
    .tickLF.sub[`universe;`a];
    `a mustin .tickLF.w[`universe][;1];
    d:(2#.z.t;`a`b;2#.z.d);
    .tickLF.pubImg[`universe;d];
    enlist[`a] mustmatch universe[`sym];
    };
  should["test .z.pc"]{
    .tickLF.sub[`universe;`a];
    .z.pc[0];
    (enlist (0i;`a)) mustmatch .tickLF.w[`universe];
    };
  should["publish with invalid handle"]{
    .tickLF.w[`universe]:((100;`);(0j;`));
    d:(2#.z.t;`a`b;2#.z.d);
    .tickLF.pubImg[`universe;d];
    2 mustmatch count universe;
    };

  };


.tst.desc["test journal replay"]{
  before{
    .sl.noinit:1b;
    @[system;"l tickLF.q";0N];
    `.tickLF.cfg.timer mock 100;
    };
  should["set model and repaly data"]{
    model:(`universe;flip `time`sym`mat!(`time$();0#`;`date$()));
    jrn:`:test/tmp/jrn;
    .[jrn;();:;()];
    h:hopen jrn;
    h enlist (`test;`ok);
    hclose h;
    `testvar mock ();
    `test mock {testvar::x};
    j:(1;jrn);
    .sub.tickLF.initAndReplayTab[(model;j)];
    universe mustmatch model 1;
    testvar mustmatch `ok;
    .tst.rm[`:test/tmp];
    };
  should["log error that data cannot be replayed"]{
    `.log.path mock `:test/tmp/log;
    `model mock (`universe;flip `time`sym`mat!(`time$();0#`;`date$()));
    `j mock (1;`:test);
    .tst.mockFunc[`.log.error;2;""];
    .sub.tickLF.initAndReplayTab[(model;j)];
    `EVENT_FAILED mustmatch .tst.trace[`.log.error][0][1]`status;
    system"t 0";
    };
  };


.tst.desc["test subscription"]{
  before{
    .sl.noinit:1b;
    @[system;"l tickLF.q";0N];
    `.tickLF.cfg.tables mock flip`table`validation`jrnSwitch`eodImg2Jrn`memory`status!flip 
    ((`universe;1b;`eod`img;1b;1b;1b)
      ;(`underlyings;0b;`off;0b;0b;0b)
      ;(`calendar;1b;`img;1b;0b;1b));
    `.tickLF.cfg.jrn mock `:test/tmp/;
    `.tickLF.cfg.timer mock 100;
    `universe mock ([]time:`time$();sym:`symbol$();mat:`date$());
    `underlyings mock ([]time:`time$();sym:`symbol$();underSym:`symbol$());
    `calendar mock ([]time:`time$();sym:`symbol$();isTrd:`boolean$());
    `config mock `tables`jrn!(.tickLF.cfg.tables;.tickLF.cfg.jrn);
    `tabs mock config[`tables][`table];
    `dirs mock ` sv/:.tickLF.cfg.jrn,/:tabs;
    .tickLF.p.init[config];
    `.tickLF.upd mock {[x;y] .log.debug[`tickPT] "Perform upd: ", .Q.s1(x;y); x upsert y};
    };
  after{
    hclose each value .tickLF.jrnHnd;
    .tst.rm[`:test/tmp];
    system"t 0";
    };
  should["subscribe to tables"]{
    .tickLF.p.updJrn[`universe;`.tickLF.upd;d:(.z.t ;`a; .z.d)];
    res:.tickLF.sub[;`] each `universe`underlyings;
    ((`universe;value `universe);(`underlyings;value `underlyings)) mustmatch res[;0];
    ((.tickLF.jrnI[`universe`underlyings]),'(.tickLF.jrn[`universe`underlyings])) mustmatch res[;1];
    .sub.tickLF.initAndReplayTab'[res];
    d mustmatch first each value flip universe;
    };
  };


.tst.desc["test eod actions"]{
  before{
    .sl.noinit:1b;
    @[system;"l tickLF.q";0N];
    `.tickLF.cfg.tables mock flip`table`validation`jrnSwitch`eodImg2Jrn`memory`status!flip 
    ((`universe;1b;`eod`img;1b;1b;1b)
      ;(`underlyings;0b;`off;0b;0b;0b)
      ;(`calendar;1b;`img;1b;0b;1b));
    `.tickLF.cfg.jrn mock `:test/tmp/;
    `.tickLF.cfg.timer mock 100;
    `universe mock ([]time:`time$();sym:`symbol$();mat:`date$());
    `underlyings mock ([]time:`time$();sym:`symbol$();underSym:`symbol$());
    `calendar mock ([]time:`time$();sym:`symbol$();isTrd:`boolean$());
    `config mock `tables`jrn!(.tickLF.cfg.tables;.tickLF.cfg.jrn);
    `tabs mock config[`tables][`table];
    `dirs mock ` sv/:.tickLF.cfg.jrn,/:tabs;
    `eodplug mock ();
    .tickLF.plug.eod[`universe]:{[x].log.debug[`tickPT] "perform ", string x; eodplug,::x};
    .tickLF.plug.eod[`underlyings]:{[x].log.debug[`tickPT] "perform ", string x; eodplug,::x};
    .tickLF.p.init[config];
    };
  after{
    hclose each value .tickLF.jrnHnd;
    .tst.rm[`:test/tmp];
    system"t 0";
    };
  should["switch configured journals"]{
    .tickLF.p.endofday[];
    (10b) mustmatch  key[` sv .tickLF.cfg.jrn,`universe] like "[0-9]*ini.universe";
    (01b) mustmatch  key[` sv .tickLF.cfg.jrn,`universe] like "[0-9]*eod.universe";
    (enlist 0b) mustmatch  key[` sv .tickLF.cfg.jrn,`underlyings] like "underlyings.eod.*[0-9]";
    (enlist 0b) mustmatch  key[` sv .tickLF.cfg.jrn,`calendar] like "calendar.eod.*[0-9]";
    };
  should["perform eod plugins"]{
    .tickLF.p.endofday[];
    `universe`underlyings mustmatch eodplug;
    };
  should["update journals with images"]{
    `universe insert d:(.z.t ;`a; .z.d);
    .tickLF.p.endofday[];
    enlist[(`.tickLF.jImg;`universe;universe)] mustmatch get .tickLF.jrn[`universe];
    };
  };





\
/
.tst.report
