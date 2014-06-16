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

//
/A/ DEVnet: Pawel Hudak
/D/ 2012.06.29
/V/ 1.2
/S/ Unit tests for protected evaluation (protect.q)
/E/ q test/event_test.q --noquit -p 5001


\l lib/qspec/qspec.q

/------------------------------------------------------------------------------/
.tst.desc["[events.q] events"]{
  before{
    .tst.mockFunc[`monadic;1;"`r"];
    .tst.mockFunc[`monadicFail;1;"'`fail"];
    .tst.mockFunc[`dyadic;2;"`r"];
    .tst.mockFunc[`dyadicFail;2;"'`fail"];
    .tst.mockFunc[`.log.debug;2;""];
    .tst.mockFunc[`.log.info;2;""];
    .tst.mockFunc[`.log.warn;2;""];
    .tst.mockFunc[`.log.error;2;""];
    `.sl.zp mock {.z.p};
    system"l pe.q";
    system"l event.q";
    `.sl.componentId mock `myComponent;
    };
  after{
    delete initialized from `.event.p; 
    .tst.rm[`:test/data];
    };
  should["initialize event library - .event.p.init[]"]{
    .event.p.initialized mustmatch 1b;
    .event.p.monitorEventDumpPath mustmatch "";
    .event.p.sig mustmatch 0b;
    .event.at mustmatch .event.p.exec[`at];
    .event.dot mustmatch .event.p.exec[`dot];
    };
  should["generate event filename - .event.p.fileBase[]"]{
    res:.event.p.fileBase[2012.01.01T12:00:00.000000;`aModule];
    res mustmatch "myComponent.2012.01.01T12.00.00.000.aModule_";
    };
  should["execute event with monadic function (`info`info`error levels) - .event.at[]"]{
    res:.event.at[`module;`monadic;1 2 3;`def;`info`info`error;"important task"];
    res mustmatch `r;

    2 mustmatch count .tst.trace[`.log.info];
    b:.tst.trace[`.log.info][0];
    b[0] mustmatch `module;
    (`tsId _ b[1]) mustmatch `status`descr`funcName`arg`defVal!(`EVENT_STARTED;"important task";`monadic;1 2 3j;`def);
    -12h mustmatch type b[1][`tsId];

    .tst.trace[`monadic] mustmatch enlist 1 2 3j;

    e:.tst.trace[`.log.info][1];
    e[0] mustmatch `module;
    (`tsId _ e[1]) mustmatch `status`descr`funcName`resType`resCnt!(`EVENT_COMPLETED;"important task";`monadic;-11h;1);
    -12h mustmatch type e[1][`tsId];

    1b mustmatch b[1][`tsId] <= e[1][`tsId];
    };
  should["execute event with failing monadic function (`info`info`error levels) - .event.at[]"]{
    res:.event.at[`module;`monadicFail;1 2 3;`def;`info`info`error;"important task"];
    res mustmatch `def;

    1 mustmatch count .tst.trace[`.log.info];
    b:.tst.trace[`.log.info][0];
    b[0] mustmatch `module;
    (`tsId _ b[1]) mustmatch `status`descr`funcName`arg`defVal!(`EVENT_STARTED;"important task";`monadicFail;1 2 3j;`def);
    -12h mustmatch type b[1][`tsId];

    .tst.trace[`monadicFail] mustmatch enlist 1 2 3j;

    1 mustmatch count .tst.trace[`.log.error];
    e:.tst.trace[`.log.error][0];
    e[0] mustmatch `module;
    (`tsId _ e[1]) mustmatch `status`descr`funcName`signal!(`EVENT_FAILED;"important task";`monadicFail;"fail");
    -12h mustmatch type e[1][`tsId];

    1b mustmatch b[1][`tsId] <= e[1][`tsId];
    };
  should["execute event with multiarg function (`debug`info`warn levels) - .event.dot[]"]{
    res:.event.dot[`module;`dyadic;(`1;2.0);`def;`debug`info`warn;"minor task"];
    res mustmatch `r;

    1 mustmatch count .tst.trace[`.log.debug];
    b:.tst.trace[`.log.debug][0];
    b[0] mustmatch `module;
    (`tsId _ b[1]) mustmatch `status`descr`funcName`arg`defVal!(`EVENT_STARTED;"minor task";`dyadic;(`1;2.0);`def);
    -12h mustmatch type b[1][`tsId];

    .tst.trace[`dyadic] mustmatch enlist (`1;2.0);

    1 mustmatch count .tst.trace[`.log.info];
    e:.tst.trace[`.log.info][0];
    e[0] mustmatch `module;
    (`tsId _ e[1]) mustmatch `status`descr`funcName`resType`resCnt!(`EVENT_COMPLETED;"minor task";`dyadic;-11h;1);
    -12h mustmatch type e[1][`tsId];

    1b mustmatch b[1][`tsId] <= e[1][`tsId];
    };
  should["execute event with failing multiarg function (`debug`info`warn levels) - .event.dot[]"]{
    res:.event.dot[`module;`dyadicFail;(`1;2.0);`def;`debug`info`warn;"minor task"];
    res mustmatch `def;

    1 mustmatch count .tst.trace[`.log.debug];
    b:.tst.trace[`.log.debug][0];
    b[0] mustmatch `module;
    (`tsId _ b[1]) mustmatch `status`descr`funcName`arg`defVal!(`EVENT_STARTED;"minor task";`dyadicFail;(`1; 2.0f);`def);
    -12h mustmatch type b[1][`tsId];

    .tst.trace[`dyadicFail] mustmatch enlist (`1; 2.0f);

    1 mustmatch count .tst.trace[`.log.warn];
    e:.tst.trace[`.log.warn][0];
    e[0] mustmatch `module;
    (`tsId _ e[1]) mustmatch `status`descr`funcName`signal!(`EVENT_FAILED;"minor task";`dyadicFail;"fail");
    -12h mustmatch type e[1][`tsId];

    1b mustmatch b[1][`tsId] <= e[1][`tsId];
    };
  should["fail executing event with multiarg function (`debug`info`warn levels) to many args - .event.dot[]"]{
    res:.event.dot[`module;`dyadic;(`1;2.0;3j);`def;`debug`info`warn;"minor task"];
    res mustmatch `def;

    .tst.trace[`.log.debug][0;1][`status`descr`funcName`arg`defVal] mustmatch (`EVENT_STARTED;"minor task";`dyadic;(`1; 2.0f;3j);`def);
    .tst.trace[`dyadicFail] mustmatch ();
    .tst.trace[`.log.warn][0;1][`status`descr`funcName`signal] mustmatch (`EVENT_FAILED;"minor task";`dyadic;"rank");
    };
  should["fail executing event with multiarg function (`debug`info`warn levels) to little args - .event.dot[]"]{
    res:.event.dot[`module;`dyadic;enlist `1;`def;`debug`info`warn;"minor task"];
    res mustmatch `def;
    .tst.trace[`.log.debug][0;1][`status`descr`funcName`arg`defVal] mustmatch (`EVENT_STARTED;"minor task";`dyadic;enlist `1;`def);
    .tst.trace[`.log.info] mustmatch ();
    .tst.trace[`.log.warn][0;1][`status`descr`funcName`signal] mustmatch (`EVENT_FAILED;"minor task";`dyadic;"too little arguments");
    };
  should["fail executing event with missing function - .event.dot[]"]{
    mustthrow["missingFunc";{.event.dot[`module;`missingFunc;enlist `1;`def;`debug`info`warn;"minor task"]}];
    .tst.trace[`.log.debug][0;1][`status`descr`funcName`arg`defVal] mustmatch (`EVENT_STARTED;"minor task";`missingFunc;enlist `1;`def);
    .tst.trace[`.log.info] mustmatch ();
    .tst.trace[`.log.error] mustmatch (); //NO ERROR message -> responsibility of the user to pass existing function
    };
  should["fail executing event with function body - .event.dot[]"]{
    mustthrow["type";{.event.dot[`module;{x+y};1 2;`def;`debug`info`warn;"minor task"]}];
    .tst.trace[`.log.debug][0;1][`status`descr`funcName`arg`defVal] mustmatch (`EVENT_STARTED;"minor task";{x+y};1 2j;`def);
    .tst.trace[`.log.info] mustmatch ();
    .tst.trace[`.log.error] mustmatch (); //NO ERROR message -> responsibility of the user to pass correct function type
    };
  should["fail executing event with multiarg function (`debug`info`warn levels) with non-list arg - .event.dot[]"]{
    mustthrow["type";{.event.dot[`module;`dyadic;1;`def;`debug`info`warn;"minor task"]}];
    .tst.trace[`.log.debug][0;1][`status`descr`funcName`arg`defVal] mustmatch (`EVENT_STARTED;"minor task";`dyadic;1;`def);
    .tst.trace[`.log.info] mustmatch ();
    .tst.trace[`.log.error] mustmatch (); //NO ERROR message -> responsibility of the user to pass correct number of arguments
    };
  should["fail executing event with projection function - .event.at[]"]{
    mustthrow["dyadic[1]";{.event.at[`module;`$"dyadic[1]";2;`def;`debug`info`warn;"minor task"]}];
    .tst.trace[`.log.debug][0;1][`status`descr`funcName`arg`defVal] mustmatch (`EVENT_STARTED;"minor task";`$"dyadic[1]";2j;`def);
    .tst.trace[`.log.info] mustmatch ();
    .tst.trace[`.log.error] mustmatch (); //NO ERROR message -> responsibility of the user to pass correct function type
    };
  should["record event progress - .event.progress[]"]{
    .tst.mockFunc[`monadicProgr;1;".event.progress[`module;`monadicProgr;10.;100;\"running\"];`r"];
    res:.event.at[`module;`monadicProgr;1 2 3;`def;`info`info`error;"important task"];
    .tst.trace[`.log.warn] mustmatch ();
    .tst.trace[`.log.info][0;1][`status`descr`funcName`arg`defVal] mustmatch' (`EVENT_STARTED; "important task";`monadicProgr;1 2 3;`def);
    .tst.trace[`.log.info][1;1][`status`descr`funcName`progress`timeLeft] mustmatch' (`EVENT_PROGRESS;"running";`monadicProgr;10f;100);
    .tst.trace[`.log.info][2;1][`status`descr`funcName`resType`resCnt] mustmatch' (`EVENT_COMPLETED; "important task";`monadicProgr;-11h;1);
    };
  should["record event progress of non-existing event - .event.progress[]"]{
    .event.progress[`module;`monadic;10.;100;"running"];
    .tst.trace[`.log.warn] mustmatch enlist (`module;"event progress: no matching event for func monadic module module");
    .tst.trace[`.log.info] mustmatch enlist (`module;`status`descr`funcName`progress`timeLeft`tsId!(`EVENT_PROGRESS;"running";`monadic;10.0f;100j;()));
    };
  };

.tst.desc["[event.q] events with transfer files for MONITOR"]{
  before{
    `EC_EVENT_PATH setenv "test/data/";
    .tst.mockFunc[`monadic;1;"`r"];
    .tst.mockFunc[`monadicFail;1;"'`fail"];
    .tst.mockFunc[`dyadic;2;"`r"];
    .tst.mockFunc[`dyadicFail;2;"'`fail"];
    .tst.mockFunc[`.log.debug;2;""];
    .tst.mockFunc[`.log.info;2;""];
    .tst.mockFunc[`.log.warn;2;""];
    .tst.mockFunc[`.log.error;2;""];
    `.sl.componentId mock `myComponent;
    `.log.status mock `info`warn`error!1 0 0j;
    `.sl.zp mock {.z.p};
    system"l pe.q";
    system"l event.q";
    };
  after{
    delete initialized from `.event.p; 
    .tst.rm[`:test/data];
    };
  should["execute event with dyadic function (`info`info`error levels) - .event.at[]"]{
    res:.event.dot[`module;`dyadic;(`1;2.0);`def;`debug`info`warn;"minor task"];
    res mustmatch `r;

    .tst.trace[`.log.debug][0;1][`status`descr`funcName`arg`defVal] mustmatch (`EVENT_STARTED;"minor task";`dyadic;(`1; 2.0f);`def);
    .tst.trace[`dyadic] mustmatch enlist (`1;2.0);
    .tst.trace[`.log.info][0;1][`status`descr`funcName`resType`resCnt] mustmatch (`EVENT_COMPLETED;"minor task";`dyadic;-11h;1j);

    files:key hsym`$.event.p.monitorEventDumpPath;
    2 mustmatch count files;
    files[0] mustlike "myComponent.*.module_e1_begin.event";
    files[1] mustlike "myComponent.*.module_e3_end.event";

    file0:get[` sv(hsym`$.event.p.monitorEventDumpPath),files[0]];
    file0[`status`descr`funcName`arg`defVal`module`level`componentId] mustmatch' (`EVENT_STARTED;"minor task";`dyadic;(`1;2.0f);`def;`module;`debug;`myComponent);

    file1:get[` sv(hsym`$.event.p.monitorEventDumpPath),files[1]];
    file1[`status`descr`funcName`resType`resCnt`module`level`componentId] mustmatch' (`EVENT_COMPLETED;"minor task";`dyadic;-11h;1j;`module;`info;`myComponent);
    };
  should["execute event with monadic failing function (`info`info`error levels) - .event.at[]"]{
    res:.event.at[`module;`monadicFail;(`1);`def;`debug`info`warn;"minor task"];
    res mustmatch `def;

    .tst.trace[`.log.debug][0;1][`status`descr`funcName`arg`defVal] mustmatch' (`EVENT_STARTED;"minor task";`monadicFail;(`1);`def);
    .tst.trace[`monadicFail] mustmatch enlist`1;
    .tst.trace[`.log.warn][0;1][`status`descr`funcName`signal] mustmatch' (`EVENT_FAILED;"minor task";`monadicFail;"fail");

    files:key hsym`$.event.p.monitorEventDumpPath;
    2 mustmatch count files;
    files[0] mustlike "myComponent.*.module_e1_begin.event";
    files[1] mustlike "myComponent.*.module_e3_signal.event";

    file0:get[` sv(hsym`$.event.p.monitorEventDumpPath),files[0]];
    file0[`status`descr`funcName`arg`defVal`module`level`componentId] mustmatch' (`EVENT_STARTED;"minor task";`monadicFail;(`1);`def;`module;`debug;`myComponent);

    file1:get[` sv(hsym`$.event.p.monitorEventDumpPath),files[1]];
    file1[`status`descr`funcName`signal`module`level`componentId] mustmatch' (`EVENT_FAILED;"minor task";`monadicFail;"fail";`module;`warn;`myComponent);
    };
  should["record event progress - .event.progress[]"]{
    .tst.mockFunc[`monadicProgr;1;".event.progress[`module;`monadicProgr;10.;100;\"running\"];`r"];
    res:.event.at[`module;`monadicProgr;1 2 3;`def;`info`info`error;"important task"];
    .tst.trace[`.log.warn] mustmatch ();
    .tst.trace[`.log.info][0;1][`status`descr`funcName`arg`defVal] mustmatch' (`EVENT_STARTED; "important task";`monadicProgr;1 2 3;`def);
    .tst.trace[`.log.info][1;1][`status`descr`funcName`progress`timeLeft] mustmatch' (`EVENT_PROGRESS;"running";`monadicProgr;10f;100);
    .tst.trace[`.log.info][2;1][`status`descr`funcName`resType`resCnt] mustmatch' (`EVENT_COMPLETED; "important task";`monadicProgr;-11h;1);

    files:key hsym`$.event.p.monitorEventDumpPath;
    3 mustmatch count files;
    files[0] mustlike "myComponent.*.module_e1_begin.event";
    files[1] mustlike "myComponent.*.module_e3_end.event";
    files[2] mustlike "myComponent.*.module_e2_progress.event";

    file0:get[` sv(hsym`$.event.p.monitorEventDumpPath),files[0]];
    file0[`status`descr`funcName`arg`defVal`module`level`componentId] mustmatch' (`EVENT_STARTED;"important task";`monadicProgr;1 2 3;`def;`module;`info;`myComponent);

    file1:get[` sv(hsym`$.event.p.monitorEventDumpPath),files[1]];
    file1[`status`descr`funcName`resType`resCnt`module`level`componentId] mustmatch' (`EVENT_COMPLETED;"important task";`monadicProgr;-11h;1;`module;`info;`myComponent);

    file2:get[` sv(hsym`$.event.p.monitorEventDumpPath),files[2]];
    file2[`status`descr`funcName`progress`timeLeft`module`level`componentId] mustmatch' (`EVENT_PROGRESS;"running";`monadicProgr;10f;100;`module;`info;`myComponent);
    };
  };
