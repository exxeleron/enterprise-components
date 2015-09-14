// q test/feedMng_test.q --noquit -p 5001

\l lib/qsl/sl.q
.sl.init[`feddMng_test];
\l lib/qspec/qspec.q
.sl.libpath:(`:.;`:./lib/;`$":",getenv[`QHOME],"/lib/");

//dir:`:test/tmp
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
    `.q.hopen mock {[x] 0};
    .sl.noinit:1b;
    .sl.relib[`$"qsl/sub"];
    @[system;"l feedMng.q";0N];
    .sl.relib[`$"qsl/handle"];
    .sl.relib[`$"pluginExample.q"];
    `.cr.p.cfgTable mock ([]sectionType:`group;varName:`host`port`kdb_user`kdb_password;finalValue:("";0;"";"");errType:`;subsection:`in.tickLF);
    `.feedMng.cfg.tables mock ([sectionVal:`sysUniverse`universe]; subSrc:2#`in.tickLF);
    `.feedMng.cfg.serverAux mock `;
    `.feedMng.cfg.timeout mock 100i;
    `.data.universe mock ([] time:2#.z.t;sym:`a`b;flag:`instrClass1`instrClass2;instrGroup:`group1`group2);
    `.data.sysUniverse mock ([]  time:2#.z.t; sym:`kdb.feedRtr`kdb.feedRtr; instrumentGroup:`group1`group2; instrument:`a`b;subItem:`a`b);
    //TODO: use new qsl/sub library
    `.sub.p.sub mock {[x;y] `sysUniverse set 0#.data.sysUniverse; `universe set .data.universe};
    `.data.pubUpd mock 0#.data.sysUniverse;
    `.tickLF.pubUpd mock {[x;y] `.data.pubUpd insert y};
    `.tickLF.pubDel mock {[x;c;b;a] ![x;c;b;a]};
    .hnd.p.getTechnicalUser:{([] proc:enlist `in.tickLF;host:enlist "";port:0;kdb_user:enlist"";kdb_password:enlist"")};
    };
  after{
    .hnd.hclose enlist `in.tickLF;
    delete from `.hnd.status where server=`in.tickLF;
    };
  should["test .feedMng.p.recreateSysUniFromJrn with update"]{
    .hnd.hopen[`in.tickLF;100i;`eager];
    .feedMng.serverDst:`in.tickLF;
    `universe mock .data.universe;
    `sysUniverse mock 0#.data.sysUniverse;
    .feedMng.p.recreateSysUniFromJrn[];
    (delete time from .data.sysUniverse) mustmatch delete time from sysUniverse;
    
    };
  should["test .feedMng.p.recreateSysUniFromJrn with delete"]{
    .hnd.hopen[`in.tickLF;100i;`eager];
    .feedMng.serverDst:`in.tickLF;
    `universe mock 0#.data.universe;
    `sysUniverse mock .data.sysUniverse;
    .feedMng.p.recreateSysUniFromJrn[];
    0 mustmatch count sysUniverse;    
    };
  should["test .feedMng.p.recreateSysUniFromJrn if there is no update"]{
    `universe mock .data.universe;
    `sysUniverse mock .data.sysUniverse;
    .feedMng.p.recreateSysUniFromJrn[];
    sysUniverse mustmatch  sysUniverse;
    };
  should["test .feedMng.p.recreateSysUniFromJrn with incorrect model"]{
    `.feedMng.plug.jrn mock {([] test:())};
    `universe mock .data.universe;
    `sysUniverse mock .data.sysUniverse;
    mustthrow["Meta of the created .feedMng.plug.jrn is not matching sysUniverse";{.feedMng.p.recreateSysUniFromJrn[]}];
    };
  should["test .feedMng.p.poPlugin with sysUniverse update"]{
    `universe mock .data.universe;
    .feedMng.p.poPlugin[];
    (delete time from .data.sysUniverse) mustmatch delete time from sysUniverse;
    };
  should["test .feedMng.p.poPlugin with error"]{
    `.feedMng.p.recreateSysUniFromJrn mock {'test};
    .feedMng.p.poPlugin[];
    ;
    };
  should["test initilization"]{
    `universe mock .data.universe;
    .hnd.hclose enlist `in.tickLF;
    .feedMng.p.init[];
    (delete time from .data.sysUniverse) mustmatch delete time from sysUniverse;
    };
  };

.tst.desc["test upd and del functions"]{
  before{
    //        .q.hopen:.tst.hopen
    .sl.noinit:1b;
    @[system;"l lib/qsl/sub.q";0N];
    @[system;"l feedMng.q";0N];
    
    .tst.hopen:.q.hopen;
    `.q.hopen mock {[x] 0};
    .sl.relib[`$"qsl/handle"];
    `.cr.p.cfgTable mock ([]sectionType:`group;varName:`host`port`kdb_user`kdb_password;finalValue:("";0;"";"");errType:`;subsection:`tickLF);
    .hnd.p.getTechnicalUser:{([] proc:enlist `tickLF;host:enlist "";port:0;kdb_user:enlist"";kdb_password:enlist"")};
    `.cfg.timout mock 100i;
    .hnd.hopen[`tickLF;.cfg.timout;`eager];
    `.feedMng.serverDst mock `tickLF;
    `.tickLF.pubDel mock .feedMng.load.del;
    `.tickLF.pubUpd mock .feedMng.load.upd;
    };
  should["publish upd"]{
    .feedMng.upd[data:flip `time`sym`instrumentGroup`instrument`subItem!(enlist 11:39:37.004;enlist `feed1;enlist `;enlist `sym1;enlist `sym1)];
    (2#data) mustmatch sysUniverse;
    };
  should["publish del"]{
    `sysUniverse mock flip `time`sym`instrumentGroup`instrument`subItem!(enlist 11:39:37.004;enlist `feed1;enlist `;enlist `sym1;enlist `sym1);
    .feedMng.del[flip `time`sym`instrumentGroup`instrument`subItem!(enlist 11:39:37.004;enlist `feed1;enlist `;enlist `sym1;enlist `sym1)];
    0 mustmatch count sysUniverse;
    `sysUniverse mock flip `time`sym`instrumentGroup`instrument`subItem!(enlist 11:39:37.004;enlist `feed1;enlist `;enlist `sym1;enlist `sym1);
    .feedMng.del[flip `time`sym`instrumentGroup`instrument`subItem!(enlist 11:39:37.004;enlist `feed1;enlist `;enlist `sym2;enlist `sym2)];
    1 mustmatch count sysUniverse;
    };

  };


.tst.desc["manage sysUniverse from one reference table"]{
  before{
    @[system;"l lib/qsl/sub.q";0N];
    @[system;"l feedMng.q";0N];
    };
  should["[.feedMng.compareUni] compare universe"]{
    new:flip `time`sym`instrumentGroup`instrument`subItem!(11:39:37.004 11:39:37.004 11:39:37.004 11:39:37.004;`feed1`feed1`feed2`feed1;````;`sym1`sym2`sym3`sym4;`sym1`sym2`sym3`sym4);
    old:0#sysUniverse;
    res:.feedMng.compareUni[old;new];
    (`sym xasc delete time from new) mustmatch res[`upd];
    old:flip `time`sym`instrumentGroup`instrument`subItem!(enlist 11:39:37.004;enlist `feed1;enlist `;enlist `sym1;enlist `sym1);
    new:flip `time`sym`instrumentGroup`instrument`subItem!(11:39:37.004 11:39:37.004 11:39:37.004 11:39:37.004;`feed1`feed1`feed2`feed1;````;`sym1`sym2`sym3`sym4;`sym1`sym2`sym3`sym4);
    res:.feedMng.compareUni[old;new];
    (`sym xasc delete time from 1_new) mustmatch res[`upd];

    old:flip `time`sym`instrumentGroup`instrument`subItem!(enlist 11:39:37.004;enlist `feed1;enlist `;enlist `sym1;enlist `sym1);
    new:1_new;
    res:.feedMng.compareUni[old;new];
    (`sym xasc delete time from new) mustmatch res[`upd];
    (`sym xasc delete time from old) mustmatch res[`del];
    };
  };

.tst.desc["replay state from the journal file with one reference table"]{
  before{
    //        .q.hopen:.tst.hopen
    .tst.hopen:.q.hopen;
    .sl.noinit:1b;
    `.q.hopen mock {[x] 0};
    @[system;"l lib/qsl/sub.q";0N];
    @[system;"l feedMng.q";0N];
    .sl.relib[`$"qsl/handle"];
    `.cfg.timout mock 100i;
    `.cfg.serverAux mock enlist `;
    /`.cfg.table mock ([] table:`universe`ca;serverSrc:((enlist `tickLF)!enlist `::5001;(enlist `tickLF)!enlist `::5001));
    /`.cfg.sysTable mock ([] table:enlist `sysUniverse;serverSrc:enlist (enlist `tickLF)!enlist `::5001);
    `.cr.p.cfgTable mock ([]sectionType:`group;varName:`host`port`kdb_user`kdb_password;finalValue:("";0;"";"");errType:`;subsection:`in.tickLF);
    `jrnuniverse mock `:test/tmp/jrnuniverse;
    `jrnsysUniverse mock `:test/tmp/jrnsysUniverse;
    `universe mock ([] time:(); sym:`symbol$(); flag:`symbol$());
    `.tickLF.jrnImg mock .tickLF.img;
    `.tickLF.jrnUpd mock .tickLF.upd;
    `.tickLF.jrnDel mock .tickLF.del;
    `.tickLF.jrnUps mock .tickLF.ups;
    `.tickLF.pubDel mock .feedMng.load.del;
    `.tickLF.pubUpd mock .feedMng.load.upd;
    .hnd.p.getTechnicalUser:{([] proc:enlist `in.tickLF;host:enlist "";port:0;kdb_user:enlist"";kdb_password:enlist"")};
    .hnd.hopen[`in.tickLF;.cfg.timout;`eager];
    .feedMng.serverDst:`in.tickLF;
    };
  after{
    .tst.rm[`:test/tmp];
    .hnd.hclose enlist `in.tickLF;
    delete from `.hnd.status where server=`in.tickLF;
    };
  should["init sysUniverse on port open callback in case if there was no update to the sysUsniverse"]{
    .q.hopen:.tst.hopen;
    .[jrnuniverse;();:;()];h:hopen jrnuniverse;
    h enlist (`.tickLF.jrnImg;`universe;(3#.z.t;`sym1`sym2`sym3;`a`b`c));
    h enlist (`.tickLF.jrnUpd;`universe;(2#.z.t;`sym4`sym5;`b`c));
    hclose h;
    .[jrnsysUniverse;();:;()];h:hopen jrnsysUniverse;
    h enlist (`.tickLF.jrnUpd;`sysUniverse;(5#.z.t;`feed1`feed1`feed2`feed1`feed2;`a`b`c`b`c;`sym1`sym2`sym3`sym4`sym5;`sym1`sym2`sym3`sym4`sym5));
    hclose h;
    `jrnCnt mock `universe`sysUniverse!2 1;
    `.tickLF.sub mock {[x;y] :((x;0#value x);(jrnCnt[x];`$":test/tmp/jrn",string x))};
    `.q.hopen mock {[x] 0};
    `flagMap mock `a`b`c!(`feed1`feed1`feed2);
    .feedMng.plug.jrn:{[] select time, sym:flagMap[flag], instrumentGroup:`, instrument:sym, subItem:sym from universe};
   .feedMng.p.poPlugin[];
    new:.feedMng.plug.jrn[];
    res:.feedMng.compareUni[sysUniverse;new];
    0 mustmatch/: count each res;
    };
  should["init sysUniverse on port open callback in case if there was an insert  to the universe"]{
    .q.hopen:.tst.hopen;
    .[jrnuniverse;();:;()];h:hopen jrnuniverse;
    h enlist (`.tickLF.jrnImg;`universe;(3#.z.t;`sym1`sym2`sym3;`a`b`c));
    h enlist (`.tickLF.jrnUpd;`universe;(2#.z.t;`sym4`sym5;`b`c));
    h enlist (`.tickLF.jrnUpd;`universe;(2#.z.t;`sym6`sym7;`b`c));
    hclose h;
    .[jrnsysUniverse;();:;()];h:hopen jrnsysUniverse;
    h enlist (`.tickLF.jrnUpd;`sysUniverse;(5#.z.t;`feed1`feed1`feed2`feed1`feed2;`a`b`c`b`c;`sym1`sym2`sym3`sym4`sym5;`sym1`sym2`sym3`sym4`sym5));
    hclose h;
    `jrnCnt mock `universe`sysUniverse!3 1;
    `.tickLF.sub mock {[x;y] :((x;0#value x);(jrnCnt[x];`$":test/tmp/jrn",string x))};
    `.q.hopen mock {[x] 0};
    `flagMap mock `a`b`c!(`feed1`feed1`feed2);
    .feedMng.plug.jrn:{[] select time, sym:flagMap[flag], instrumentGroup:`, instrument:sym, subItem:sym from universe};
    .feedMng.p.poPlugin[];
    new:.feedMng.plug.jrn[];
    res:.feedMng.compareUni[sysUniverse;new];
    0 mustmatch/: count each res;
    };

  };

.tst.desc["test plugins"]{
  before{
    //        .q.hopen:.tst.hopen
    `.q.hopen mock {[x] 0};
    .sl.noinit:1b;
    .sl.relib[`$"qsl/sub"];
    @[system;"l feedMng.q";0N];
    .sl.relib[`$"qsl/handle"];
    .sl.relib[`$"pluginExample.q"];
    `.cr.p.cfgTable mock ([]sectionType:`group;varName:`host`port`kdb_user`kdb_password;finalValue:("";0;"";"");errType:`;subsection:`in.tickLF);
    .hnd.p.getTechnicalUser:{([] proc:enlist `in.tickLF;host:enlist "";port:0;kdb_user:enlist"";kdb_password:enlist"")};
    `.feedMng.cfg.tables mock ([sectionVal:`sysUniverse`universe]; subSrc:2#`in.tickLF);
    `.feedMng.cfg.serverAux mock `;
    `.feedMng.cfg.timeout mock 100i;
    `.data.universe mock ([] time:2#.z.t;sym:`a`b;flag:`instrClass1`instrClass2;instrGroup:`group1`group2);
    `.data.sysUniverse mock ([]  time:2#.z.t; sym:`kdb.feedRtr`kdb.feedRtr; instrumentGroup:`group1`group2; instrument:`a`b;subItem:`a`b);
    //TODO: use new qsl/sub library
    `.sub.p.sub mock {[x;y;z] `sysUniverse set 0#.data.sysUniverse; `universe set .data.universe};
     `universe set .data.universe;`sysUniverse set 0#.data.sysUniverse;
    `.data.pubUpd mock 0#.data.sysUniverse;
    `.tickLF.pubUpd mock {[x;y] `.data.pubUpd insert y};
    `.tickLF.pubDel mock {[x;c;b;a] ![x;c;b;a]};
    `execute mock 0b;
    .tst.mockFunc[`.feedMng.plug.upd.universe;1;"execute::1b"];
    .tst.mockFunc[`.feedMng.load.upd;2;""];
    .tst.mockFunc[`.feedMng.plug.img.universe;1;"execute::1b"];
    .tst.mockFunc[`.feedMng.load.img;2;""];
    .tst.mockFunc[`.feedMng.plug.ups.universe;1;"execute::1b"];
    .tst.mockFunc[`.feedMng.load.ups;5;""];
    .tst.mockFunc[`.feedMng.plug.del.universe;1;"execute::1b"];
    .tst.mockFunc[`.feedMng.load.del;4;""];
    };
  should["test upd plugin"]{
    .tickLF.upd[`universe;`test];
    `test mustmatch first .tst.trace[`.feedMng.plug.upd.universe];
    1b mustmatch execute;
    `universe`test mustmatch first .tst.trace[`.feedMng.load.upd];
    };
  should["test case if upd plugin is not defined for table"]{
    .tickLF.upd[`sysUniverse][`test];
    () mustmatch first .tst.trace[`.feedMng.plug.upd.sysUniverse];
    0b mustmatch execute;
    `sysUniverse`test mustmatch first .tst.trace[`.feedMng.load.upd];
    };
  should["test img plugin"]{
    .tickLF.img[`universe][`test];
    `test mustmatch first .tst.trace[`.feedMng.plug.img.universe];
    1b mustmatch execute;
    `universe`test mustmatch first .tst.trace[`.feedMng.load.img];
    };
  should["test case if img plugin is not defined for table"]{
    .tickLF.img[`sysUniverse][`test];
    () mustmatch first .tst.trace[`.feedMng.plug.img.sysUniverse];
    0b mustmatch execute;
    `sysUniverse`test mustmatch first .tst.trace[`.feedMng.load.img];
    };
  should["test ups plugin"]{
    .tickLF.ups[`universe][`test;`c;`b;`a];
    `test`c`b`a mustmatch first .tst.trace[`.feedMng.plug.ups.universe];
    1b mustmatch execute;
    `universe`test`c`b`a mustmatch first .tst.trace[`.feedMng.load.ups];
    };
  should["test case if img plugin is not defined for table"]{
    .tickLF.ups[`sysUniverse][`test;`c;`b;`a];
    () mustmatch first .tst.trace[`.feedMng.plug.ups.sysUniverse];
    0b mustmatch execute;
    `sysUniverse`test`c`b`a mustmatch first .tst.trace[`.feedMng.load.ups];
    };
  should["test del plugin"]{
    .tickLF.del[`universe][`c;`b;`a];
    `c`b`a mustmatch first .tst.trace[`.feedMng.plug.del.universe];
    1b mustmatch execute;
    `universe`c`b`a mustmatch first .tst.trace[`.feedMng.load.del];
    };
  should["test case if img plugin is not defined for table"]{
    .tickLF.del[`sysUniverse][`c;`b;`a];
    () mustmatch first .tst.trace[`.feedMng.plug.del.sysUniverse];
    0b mustmatch execute;
    `sysUniverse`c`b`a mustmatch first .tst.trace[`.feedMng.load.del];
    };
  };

/
.tst.report
.hnd.status


