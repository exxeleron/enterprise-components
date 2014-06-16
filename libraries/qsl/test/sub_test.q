/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/L/
/L/ Licensed under the Apache License, Version 2.0 (the "License");
/L/ you may not use this file except in compliance with the License.
/L/ You may obtain a copy of the License at
/L/
/L/   http://www.apache.org/licenses/LICENSE-2.0
/L/
/L/ Unless required by applicable law or agreed to in writing, software
/L/ distributed under the License is distributed on an "AS IS" BASIS,
/L/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/L/ See the License for the specific language governing permissions and
/L/ limitations under the License.

// Usage:
//q test/sub_test.q --noquit -p 9009

\l lib/qspec/qspec.q
`EC_EVENT_PATH setenv "FAILDUMP";
system"l sl.q";
system"l pe.q";
.sl.init[`test];
system"l sub.q";
system"l sub_tickLF.q";
system"l sub_tickHF.q";
system"l event.q";


/system"l handle.q";
/system"l sub.q";

.tst.desc["[sub.q] Return protocol name"]{
  before{
    `.hnd.h mock `tickHF`tickLF!0 0;
    };
  after{};
  should["return tickHF protocol - .sub.p.getSubProtocol"]{
    `.sl.getSubProtocols mock {[] enlist`PROTOCOL_TICKHF};
    enlist[`PROTOCOL_TICKHF] mustmatch .sub.p.getSubProtocol[`tickHF];
    };

  should["return tickLF protocol - .sub.p.getSubProtocol"]{
    `.sl.getSubProtocols mock {[] enlist`PROTOCOL_TICKLF};
    enlist[`PROTOCOL_TICKLF] mustmatch .sub.p.getSubProtocol[`tickLF];
    };
  };

.tst.desc["[sub.q] Replay journals"]{
  before{
    .sub.initCallbacks[`PROTOCOL_TICKHF];
    // setup mock journals
    `jrn1 mock (2;`:test/sub_test.jrn1);
    jrn1[1] set ();
    `jrnh1 mock hopen jrn1 1;
    jrnh1 enlist (`upd; `ttable;(1; 2; `three));
    jrnh1 enlist (`upd; `ttable;(10; 20; `thirty));
    hclose jrnh1;
    `ttable mock ([] a:(); b:(); c:());
    };
  after{
    .tst.rm jrn1[1];
    /.tst.rm jrn2[1];
    };
  should["replay tickHF journal - .sub.tickHF.replayData[]"]{
    .sub.tickHF.replayData[jrn1];
    jrn1[0] musteq count ttable;
    };

  should["replay tickLF journal - .sub.tickLF.replayData[]"]{
    .sub.tickLF.replayData[jrn1];
    jrn1[0] musteq count ttable;
    };
  should["set model and replay one table - .sub.tickHF.replayData[]"]{
    .sub.tickLF.replayData[jrn1];
    subDetail:((`ttable;flip `a`b`c!(`long$();`int$();0#`));(1;jrn1[1]));
    .sub.tickLF.initAndReplayTab[subDetail];
    1 musteq count ttable;
    "i" musteq meta[ttable][`b][`t];
    };
  };
.tst.desc["[sub.q] Subscription via tickLF protocol"]{
  before{
    .sub.initCallbacks[`PROTOCOL_TICKLF];

    // setup mock journals
    `jrn1 mock (2;`:test/sub_test.jrn1);
    `jrn2 mock (3;`:test/sub_test.jrn2);
    jrn1[1] set ();
    jrn2[1] set ();
    // populate journal file with data for ttable
    `jrnh1 mock hopen jrn1 1;
    jrnh1 enlist (`upd; `ttable;(1; 2; `three));
    jrnh1 enlist (`upd; `ttable;(10; 20; `thirty));
    hclose jrnh1;
    
    // populate journal file with data for ttable2
    `jrnh2 mock hopen jrn2 1;
    jrnh2 enlist (`upd; `ttable2;(3; 4i; `un));
    jrnh2 enlist (`upd; `ttable2;(30; 40i; `dos));
    jrnh2 enlist (`upd; `ttable2;(300; 400i; `tres));
    hclose jrnh2;
    
    `.hnd.h mock enlist[`test]!enlist 0;
    .tst.mockFunc[`.tickLF.sub;2;"sds first where sds[;0;0]=a0"];
    //.u::`i`L!(3;jrn2[1]);

    `sds mock (((`ttable;flip `a`b`c!(`long$();`long$();0#`));jrn1);
      ((`ttable2;flip `a`b`c!(`long$();`int$();0#`));jrn2));

    `ttable mock ([] a:(); b:(); c:());
    `ttable2 mock ([] a:(); b:(); c:());

    };
  after{
    .tst.rm jrn1[1];
    .tst.rm jrn2[1];
    };
  should["subscribe using tickLF protocol - .sub.tickLF.subscribe[]"]{
    .sub.tickLF.subscribe[`test;`ttable`ttable2;``];
    2 musteq count ttable;                        
    3 musteq count ttable2;
    "j" musteq meta[ttable][`b][`t];
    "i" musteq meta[ttable2][`b][`t];
    (2;2) musteq count each .tst.trace[`.tickLF.sub];
    };
  };

.tst.desc["[sub.q] Subscription via tickHF protocol"]{
  before{
    .sub.initCallbacks[`PROTOCOL_TICKHF];

    // setup mock journal
    `jrnt mock (2;`:test/sub_test_trade.jrn);
    `jrnq mock (2;`:test/sub_test_quote.jrn);
    `jrnhf mock (5;`:test/sub_test_tickHF.jrn);

    jrnt[1] set ();
    jrnq[1] set ();
    jrnhf[1] set ();

    jrnth:hopen jrnt[1];
    jrnhq:hopen jrnq[1];
    jrnhfh:hopen jrnhf[1];

    jrnth enlist (`upd; `trade;(1; 2i; `three));
    jrnth enlist (`upd; `trade;(10; 20i; `thirty));
    jrnhfh enlist (`upd; `trade;(1; 2i; `three));
    jrnhfh enlist (`upd; `trade;(10; 20i; `thirty));
    hclose jrnth;

    jrnhq enlist (`upd;`quote;(1 2i; 3 4i; `a`b));
    jrnhfh enlist (`upd;`quote;(1 2i; 3 4i; `a`b));
    hclose jrnhq;
    hclose jrnhfh;

    `.hnd.h mock enlist[`tick1]!enlist 0;
    .tst.mockFunc[`.u.sub;2;"(a0;0#value a0)"];
    `.u.i mock 3;
    `.u.L mock `:test/sub_test_tickHF.jrn;
    `trade mock ([] a:`long$(); b:`int$(); c:0#`);
    `quote mock ([] a:`int$(); b:`int$(); c:0#`);
    .tst.mockFunc[`sub;2;""];
    };
  after{
    .tst.rm jrnt[1];
    .tst.rm jrnq[1];
    .tst.rm jrnhf[1];
    };

  should["subscribe using tickHF protocol - one table - .sub.tickHF.subscribe[]"]{
    .sub.tickHF.subscribe[`tick1;enlist `trade;`];
    //.hnd.h[`test] "(.u.sub[`trade;`];`.u `i`L)";
    1 musteq count .tst.trace[`.u.sub];
    enlist[(`tick1;enlist(`trade;0#trade))] mustmatch .tst.trace[`sub];
    2 musteq count trade;
    };

  should["subscribe using tickHF protocol - two tables - .sub.tickHF.subscribe[]"]{
    .sub.tickHF.subscribe[`tick1;`trade`quote;``];
    //.hnd.h[`test] "(.u.sub[`ttable;`];`.u `i`L)";
    2 musteq count .tst.trace[`.u.sub];
    enlist[(`tick1;((`trade;0#trade);(`quote;0#quote)))] mustmatch .tst.trace[`sub];
    2 musteq count trade;
    2 musteq count quote;
    };
  
  };
.tst.desc["[sub.q] tickLF delivered data capture"]{
  before{
    .sub.initCallbacks[`PROTOCOL_TICKLF];
    `table mock ([] sym:`a`b`c`d; b:1 2 3 4; c:0N 0N 0N 0N);
    `universe mock ([]time:`time$();sym:`symbol$();mat:`date$());
    `inputlst mock (`a`e; 10 5; 1 2);
    `inputtbl mock ([] sym:`a`e; b:10 5; c: 1 2);
    `dt0 mock ([] time:(),.z.t;sym:(),`a;mat:(),.z.d);
    `dt1 mock ([] time:(),.z.t;sym:(),`b;mat:(),.z.d);
    `dt2 mock ([] time:(),.z.t;sym:(),`b;mat:(),.z.d+1);
    `dl0 mock (.z.t ;`a; .z.d);
    `dl1 mock (.z.t ;`b; .z.d);
    `dl2 mock (.z.t ;`b; .z.d+1);
    };
  after{
    };
  should["update data with table - .tickLF.upd[]"]{
    .tickLF.upd[`table; inputtbl];
    6 musteq count table;
    2 musteq count select from table where sym=`a;
    `e mustin exec sym from table;
    `a`b`c`d`e mustmatch distinct exec sym from table;
    };
  should["update data with lists - .tickLF.upd[]"]{
    .tickLF.upd[`table; inputlst];
    6 musteq count table;
    2 musteq count select from table where sym=`a;
    `e mustin exec sym from table;
    `a`b`c`d`e mustmatch distinct exec sym from table;
    };
  should["image data with lists - .tickLF.img[]"]{
    .tickLF.img[`table; inputlst];
    2 musteq count table;
    1 musteq count select from table where sym=`a;
    `b mustnin exec sym from table;
    `g musteq attr exec sym from table;
    `a`e mustmatch exec sym from table;
    `u musteq attr distinct exec sym from table;
    };
  should["image data with table - .tickLF.img[]"]{
    .tickLF.img[`table; inputtbl];
    2 musteq count table;
    1 musteq count select from table where sym=`a;
    `b mustnin exec sym from table;
    `g musteq attr exec sym from table;
    `a`e mustmatch exec sym from table;
    `u musteq attr distinct exec sym from table;
    };
  should["upsert data lists - .tickLF.ups[]"]{
    .tickLF.ups[`universe;dl0; c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    dl0 mustmatch raze value flip universe;
    .tickLF.ups[`universe;dl1; c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    (dl0,dl1) mustmatch  raze flip value flip universe;
    .tickLF.ups[`universe;dl2; c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    (dl0,dl2) mustmatch raze flip value flip universe;
    .tickLF.ups[`universe;dl2; c:();b:(enlist `sym)!enlist `sym;a:()];
    (dl0,dl2) mustmatch raze flip value flip universe;
    };
  should["upsert data tables - .tickLF.ups[]"]{
    .tickLF.ups[`universe;dt0; c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    dt0 mustmatch universe;
    .tickLF.ups[`universe;dt1; c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    (dt0,dt1) mustmatch universe;
    .tickLF.ups[`universe;dt2; c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    (dt0,dt2) mustmatch universe;
    .tickLF.ups[`universe;dt2; c:();b:(enlist `sym)!enlist `sym;a:()];
    (dt0,dt2) mustmatch universe;
    };
  should["delete data - .tickLF.del[]"]{
    .tickLF.ups[`universe;dt0; c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    .tickLF.ups[`universe;dt1; c:();b:(enlist `sym)!enlist `sym;a:(`time`mat!`time`mat)];
    2 musteq count universe;
    .tickLF.del[`universe;((in ;`sym;enlist `a);(>=;`mat;.z.d));0b;0#`];
    1 musteq count universe;
    .tickLF.del[`universe;((in ;`sym;enlist `b);(>=;`mat;.z.d));0b;0#`];
    0 musteq count universe;
    };
  };


/subDets where subDets[;0;0]=`ttable2
/
