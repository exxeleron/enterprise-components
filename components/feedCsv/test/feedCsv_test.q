// q test/feedCsv_test.q --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q
.sl.init[`test];
.sl.lib["cfgRdr/cfgRdr"];


mockFiles:{
  `data1 set ([] time:2#.z.t; sym:`a`b;mat:2#.z.d);
  `data_1 set ([] time:2#.z.t; sym:`a`b;under:`u1`u2;flag:("flag1";"flag2"));
  `file1 set `:test/tmp/universe/2011.01.01T01.01.01.000.img.universe;
  `file2 set `:test/tmp/universe/2011.01.01T01.01.01.000.upd.universe;
  `file3 set `:test/tmp/universe/2011.01.01T01.01.01.000.ups.universe;
  `file4 set `:test/tmp/universe/2011.01.01T01.01.01.000.universe1;
  `file5 set `:test/tmp/underlying/2011.01.01T01.01.01.000.underlying1;
  `file6 set `:test/tmp/universe/2011.01.01T02.01.01.000.img.universe;
  `file_1 set `:test/tmp/universe1/2011.01.01T01.01.01.000.img.universe;
  `file_2 set `:test/tmp/universe2/2011.01.01T01.01.01.000.img.universe;
  `file_3 set `:test/tmp/universe3/2011.01.01T01.01.01.000.img.universe;
  `file_4 set `:test/tmp/universe4/2011.01.01T01.01.01.000.img.universe;
  `file_5 set `:test/tmp/universe5/2011.01.01T01.01.01.000.img.universe;
  `file_6 set `:test/tmp/universe6/2011.01.01T01.01.01.000.img.universe;
  `file_7 set `:test/tmp/universe7/2011.01.01T01.01.01.000.img.universe;
  `file_8 set `:test/tmp/universe8/2011.01.01T01.01.01.000.img.universe;
  `file_9 set `:test/tmp/universe9/2011.01.01T01.01.01.000.img.universe;
  file1 0:";"0: data1;
  file2 0:";"0: data1;
  file3 0:";"0: data1;
  file4 0:";"0: data1;
  file5 0:";"0: data1;
  file6 set `a`b`c!1 2 3;
  // new configuration
  file_1 0:";"0: data_1;
  file_2 0:";"0: `time`under xcols data_1;
  file_3 0:";"0: `time`test1`sym xcols update test1:1, test2:2 from data_1;
  file_4 0:";"0: `time`test1 xcol  data_1;
  file_5 0:";"0: `time`test1`test2 xcols `time`sym`test1 xcol update test2:2,test3:3 from data_1;
  file_6 0:1_";"0: data_1;
  file_7 0:1_";"0: `time`under xcols data_1;
  file_8 0:1_";"0: `time`test1`sym xcols update test1:1, test2:2 from data_1;
  file_9 0:1_";"0: `time`test1`test2 xcols `time`sym`test1 xcol update test2:2,test3:3 from data_1;
  };

/------------------------------------------------------------------------------/
// functions used on the client site
.depricted.processData:{[files;config]
  //    ff::files;cc::config;
  .log.info[`LFPub] "Start processing #files:",string[count files]," for table ", string config`destTab;
  status:();
  status:status,{[f;config] 
    .event.dot[`LFPub;`.fcsv.p.processOneFile;(f;config);`error;`info`debug`warn;
      "Process data from file ",string[f]]}[;config]each files;
  corruptedFiles:files where status~\:`error;
  okFiles:files except corruptedFiles;
  :`ok`corrupted!(okFiles;corruptedFiles);
  };

/------------------------------------------------------------------------------/
.depricted.p.processOneFile:{[file;config]
  format:config`fileFormat;separator:config`separator;destTab:config`destTab;
  func:first .fcsv.p.supportedFunc@where .fcsv.p.supportedFunc in `$"." vs string last ` vs file;
  if[`~func;
    m:"file: ",string[file]," is not matching supported pattern ", .Q.s1[.fcsv.p.supportedFunc];
    'm
    ];
  data:.fcsv.p.read[file;format;separator;destTab];
  if[not count data;
    '"Any data couldn't be parsed from file ",string file;
    ];
  // convert to tickPlus format - list
  data2pub:value flip data;
  // convert to tickPlus func
  fsnames:string func;
  fsnames:upper[fsnames[0]],1_fsnames;
  func2pub:`$".tickLF.pub",fsnames;
  .fcsv.p.pub[func2pub;destTab;data2pub];
  };
/------------------------------------------------------------------------------/

.tst.desc["test .fcsv.p.processFiles published in tikcLF format"]{
  before{
    //        .t.hopen:.q.hopen
    .sl.noinit:1b;
    `.q.hopen mock {[x] 0};
    @[system;"l feedCsv.q";0N];
    @[system;"l tickLFPublisher.q";0N];
    .sl.relib[`$"qsl/handle"];
    // mock enrich and validate functions
    `destTab mock `$"universe",/: string 1+til 9;
    .fcsv.plug.enrich:()!();.fcsv.plug.validate:()!();
    .fcsv.plug.enrich[destTab,`universe`underlying]:{[x;y] x};
    .fcsv.plug.validate[destTab,`universe`underlying]:{[x;y]};
    .fcsv.p.archiveFiles:.fcsv.p.moveFiles;
    // mock connection
    `.fcsv.connName mock `in.tickLF;
    `.fcsv.cfg.serverDst mock `in.tickLF;
    .hnd.hopen:{[x;y;z] `.hnd.status upsert ([server:enlist x] timeout:enlist y; handle:enlist 0)};
    .hnd.hopen[`in.tickLF;100i;`lazy];
    `.tickLF.pubUpd`.tickLF.pubImg mock\: {x insert y};
    // mock models
    .fcsv.cfg.models:()!();
    `universe mock ([] time:`time$(); sym:`symbol$(); mat:`date$());
    destTab mock\: ([] time:`time$();sym:`symbol$(); under:`symbol$(); flag:());
    {.fcsv.cfg.models[x]:universe1} each destTab;
    // mock configuration
    // old configuration
    `.fcsv.cfg.files mock ([] dirSrc:`:test/tmp/universe`:test/tmp/underlying`:test/tmp/test;
      pattern:("*universe";"*underlying";"");
      destTab:`universe`underlying`;
      fileFormat:("TSD";"TSD";"");
      separator:(enlist each 3#";");
      upsertFormat:`
      );

    // new configuration
    `.fcsv.cfg.files_new mock ([] dirSrc:`:test/tmp/universe1`:test/tmp/universe2`:test/tmp/universe3,
      `:test/tmp/universe4`:test/tmp/universe5`:test/tmp/universe6,
      `:test/tmp/universe7`:test/tmp/universe8`:test/tmp/universe9;
      pattern:9#enlist"*universe";
      destTab:`$"universe",/: string 1+til 9;
      separator:(enlist each 9#";");
      fileFormat:(9#enlist "deprecated");
      headerInFile:(5#1b),4#0b;
      fileModel:(
        flip `col1`col2!(0#`;0#`);
        // reorder
        flip `col1`col2!(`time`under`sym`flag;`TIME`SYMBOL`SYMBOL`CHAR);
        // to many columns file:time test1 sym under;flag;test2
        flip `col1`col2!(`time`sym`under`flag;`TIME`SYMBOL`SYMBOL`CHAR);
        // rename
        flip `col1`col2!(`time`test1`under`flag;`TIME`SYMBOL`SYMBOL`CHAR);
        // to many columns, reorder, rename file:time test1 test2 sym ;flag;test3
        flip `col1`col2!(`time`test1`sym`flag;`TIME`SYMBOL`SYMBOL`CHAR);
        flip `col1`col2!(0#`;0#`);
        // reorder
        flip `col1`col2!(`col1`col2`col3`col4;`TIME`SYMBOL`SYMBOL`CHAR);
        // to many columns file:time test1 sym under;flag;test2
        flip `col1`col2!(`col1`col3`col4`col5;`TIME`SYMBOL`SYMBOL`CHAR);
        // to many columns, reorder, rename file:time test1 test2 sym ;flag;test3
        flip `col1`col2!(`col1`col2`col4`col5;`TIME`SYMBOL`SYMBOL`CHAR)
        );
      file2Tab:(
        flip `col1`col2!(0#`;0#`);
        flip `col1`col2!(`time`sym`under`flag;`time`sym`under`flag);
        flip `col1`col2!(`time`sym`under`flag;`time`sym`under`flag);
        flip `col1`col2!(`time`sym`under`flag;`time`test1`under`flag);
        flip `col1`col2!(`time`sym`under`flag;`time`sym`test1`flag);
        // no header
        flip `col1`col2!(0#`;0#`);
        flip `col1`col2!(`time`sym`under`flag;`col1`col3`col2`col4);
        flip `col1`col2!(`time`sym`under`flag;`col1`col3`col4`col5);
        flip `col1`col2!(`time`sym`under`flag;`col1`col4`col2`col5)
        )
      );

    mockFiles[];
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["find files"]{
    files:.fcsv.p.find[`:test/tmp/universe;"*universe"];
    count[files`ok] mustmatch 4;
    count[files`corrupted] mustmatch 1;
    };
  should["read file"]{
    res:.fcsv.p.read[file1;"TSD";enlist";";`universe];
    res mustmatch data1;
    };
  should["read2 file: with header that is matching data model"]{
    res:.fcsv.processData[files:enlist file:file_1;config:.fcsv.cfg.files_new[0]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe1;
    };
  should["read2 file: with header that is not matching data model, use build-in reorder"]{
    res:.fcsv.processData[files:enlist file:file_2;config:.fcsv.cfg.files_new[1]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe2;
    };
  should["read2 file: with header that is not matching data model, use build-in column selecting"]{
    res:.fcsv.processData[files:enlist file:file_3;config:.fcsv.cfg.files_new[2]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe3;
    };
  should["read2 file: with header that is not matching data model, use rename"]{
    res:.fcsv.processData[files:enlist file:file_4;config:.fcsv.cfg.files_new[3]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe4;
    };
  should["read2 file: with header that is not matching data model, use build-in column selecting, reorder, rename"]{
    res:.fcsv.processData[files:enlist file:file_5;config:.fcsv.cfg.files_new[4]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe5;
    };
  should["read2 file: with no header that is matching data model"]{
    res:.fcsv.processData[files:enlist file:file_6;config:.fcsv.cfg.files_new[5]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe6;
    };
  should["read2 file: with no header that is not matching data model, use build-in reorder"]{
    res:.fcsv.processData[files:enlist file:file_7;config:.fcsv.cfg.files_new[6]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe7;
    };
  should["read2 file: with no header that is not matching data model, use build-in column selecting"]{
    res:.fcsv.processData[files:enlist file:file_8;config:.fcsv.cfg.files_new[7]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe8;
    };
  should["read2 file: with no header that is not matching data model, use build-in column selecting, reorder, rename"]{
    res:.fcsv.processData[files:enlist file:file_9;config:.fcsv.cfg.files_new[8]];
    0 mustlt count res[`ok];
    data_1 mustmatch universe9;
    };
  should["enrich data"]{
    .fcsv.plug.enrich[`universe]:{[x;y] update col1:`test from x};
    res:.fcsv.p.read[file1;"TSD";enlist ";";`universe];
    res mustmatch  update col1:`test from data1;
    };
  should["enrich data with fileName"]{
    .fcsv.plug.enrich[`universe]:{[x;y] update col1:y from x};
    res:.fcsv.p.read[file1;"TSD";enlist";";`universe];
    res mustmatch  update col1:file1 from data1;
    };
  should["validate data"]{
    .fcsv.plug.validate[`universe]:{[x;y] 'stop};
    mustthrow["stop";{.fcsv.p.read[file1;"TSD";enlist";";`universe]}];
    };
  should["process data and publish in tickLF format"]{
    files:`:test/tmp/.img.test,.fcsv.p.find[`:test/tmp/universe;"*universe"][`ok];
    res:.fcsv.processData[files;`fileFormat`separator`destTab!("TSD";enlist";";`universe)];
    (file1,file2) mustmatch res`ok;
    (`:test/tmp/.img.test,file3,file6) mustmatch  res`corrupted;
    };
  should["process files: archive"]{
    .fcsv.p.processFiles[.fcsv.cfg.files];
    (0#`) mustmatch key `:test/tmp/universe;
    (0#`) mustmatch key `:test/tmp/underlying;
    d:`$string `month$.z.d;
    (`2011.01.01T01.01.01.000.img.universe`2011.01.01T01.01.01.000.upd.universe) mustmatch key ` sv`:test/tmp/archive/universe,d;
    (`2011.01.01T01.01.01.000.universe1`2011.01.01T01.01.01.000.ups.universe`2011.01.01T02.01.01.000.img.universe) mustmatch key ` sv`:test/tmp/corrupted/universe,d;
    () mustmatch key ` sv`:test/tmp/archive/underlying,d;
    (enlist `2011.01.01T01.01.01.000.underlying1) mustmatch key ` sv`:test/tmp/corrupted/underlying,d;
    };
  should["process files: publish data"]{
    .fcsv.p.processFiles[.fcsv.cfg.files];
    4 mustmatch count universe;
    `file7 mock `:test/tmp/universe/2011.01.01T01.01.01.000.img.universe;
    `data2 mock ([] time:2#.z.t; sym:`a`b;mat:2#.z.d);
    file7 0:";"0: data2;
    `universe mock ([] time:`time$(); sym:`symbol$(); mat:`date$(); a:());
    .fcsv.p.processFiles[.fcsv.cfg.files];
    0 mustmatch count universe;
    };
  should["process files with depricted functions: publish data"]{
    `.fcsv.processData mock .depricted.processData;
    `.fcsv.p.processOneFile mock .depricted.p.processOneFile;
    .fcsv.p.processFiles[.fcsv.cfg.files];
    4 mustmatch count universe;
    `file7 mock `:test/tmp/universe/2011.01.01T01.01.01.000.img.universe;
    `data2 mock ([] time:2#.z.t; sym:`a`b;mat:2#.z.d);
    file7 0:";"0: data2;
    `universe mock ([] time:`time$(); sym:`symbol$(); mat:`date$(); a:());
    .fcsv.p.processFiles[.fcsv.cfg.files];
    0 mustmatch count universe;
    };
  should["process files: test pending state"]{
    `.q.hopen mock {[x] '"hop: Connection refused"};
    .sl.relib[`$"qsl/handle"];
    .hnd.hclose enlist `in.tickLF;
    delete from `.hnd.status where server=`in.tickLF;
    .fcsv.p.processFiles[.fcsv.cfg.files_new];
    0 mustmatch/:count each value each destTab;
    `2011.01.01T01.01.01.000.img.universe mustmatch/: raze key each ` sv/:`:test/tmp/pending/,/: destTab;
    };
  should["process files: from pending state to ok state"]{
    `.hnd.h mock {[x;y] '"can't open connection to ",string[x],", error: hop: Connection refused"};
    .sl.relib[`$"qsl/handle"];
    .fcsv.p.processFiles[configTable:.fcsv.cfg.files_new];
    `2011.01.01T01.01.01.000.img.universe mustmatch/: raze key each ` sv/:`:test/tmp/pending/,/: destTab;
    `.hnd.h mock {[x;y] 0};
    .fcsv.cfg.files:.fcsv.cfg.files_new;
    .fcsv.p.movePendingFiles[];
    `2011.01.01T01.01.01.000.img.universe mustmatch/: raze key each ` sv/:(`:test/tmp/archive/,`$string[`month$.z.d]),/: destTab;
    };
  should["process files: test corrupted state"]{
    `.tickLF.pubUpd`.tickLF.pubImg mock\: {[x;y] 'remoteError};
    .fcsv.p.processFiles[configTable:.fcsv.cfg.files_new];
    `2011.01.01T01.01.01.000.img.universe mustmatch/: raze key each ` sv/:(`:test/tmp/corrupted/,`$string[`month$.z.d]),/: destTab;
    };
  should["process files: test ok state"]{
    .fcsv.p.processFiles[configTable:.fcsv.cfg.files_new];
    `2011.01.01T01.01.01.000.img.universe mustmatch/: raze key each ` sv/:(`:test/tmp/archive/,`$string[`month$.z.d]),/: destTab;
    };

  };

.tst.desc["test init"]{
  before{
    .sl.noinit:1b;
    .fcsv.plug.enrich:()!();.fcsv.plug.validate:()!();
    @[system;"l feedCsv.q";0N];
    @[system;"l etc/feedCsv_cfg.q";0N];
    `.fcsv.cfg.files mock ([] dirSrc:`:test/tmp/universe`:test/tmp/underlying`:test/tmp/test;
      pattern:("*universe*";"*underlying";"");
      destTab:`universe`underlying`;
      fileFormat:("TSD";"TSD";"");
      separator:(";");
      upsertFormat:`
      );
    `.fcsv.cfg.serverDst mock `.in.tickLF;
    `.fcsv.cfg.filesMoving mock 1b;
    `.fcsv.cfg.timer mock 1000i;
    `.fcsv.cfg.timeout mock 100i;
    `config mock .fcsv.cfg;
    .fcsv.plug.enrich[`universe`universe1`universe2]:{[x;y] x};
    .fcsv.plug.validate[`universe`universe1`universe2]:{[x;y]};
    .hnd.hopen:{[x;y;z] `.hnd.status upsert ([server:enlist x] timeout:enlist y; handle:enlist 0)};
    };
  after{
    system "t 0";
    };
  should["init and set timer"]{
    .fcsv.p.init[config];
    config[`timer] mustmatch  system"t";
    };
  should["set proper archive function"]{
    .tmr.reset[];
    .fcsv.p.init[config];
    .fcsv.p.archiveFiles mustmatch .fcsv.p.moveFiles;
    .tmr.reset[];
    .fcsv.cfg.parsedFiles:`:test/tmp/parsedFiles.txt;
    .fcsv.cfg.pendingFiles:`:test/tmp/pendingFiles.txt;
    .fcsv.cfg.filesMoving:0b;
    .fcsv.p.init[.fcsv.cfg];
    .fcsv.p.archiveFiles mustmatch .fcsv.p.updateParsedFiles;
    .fcsv.p.processPending mustmatch .fcsv.p.updatePendingFiles;
    () mustmatch .fcsv.parsedFiles;
    .tmr.reset[];
    .fcsv.cfg.parsedFiles 0: enlist "test";
    .fcsv.cfg.pendingFiles 0: enlist "test";
    .fcsv.p.init[.fcsv.cfg];
    enlist["test"] mustmatch .fcsv.parsedFiles;
    enlist["test"] mustmatch .fcsv.pendingFiles;
    config[`timer] mustmatch  system"t";
    };
  };


.tst.desc["test .fcsv.p.processFiles in tickHF mode"]{
  before{
    //        .t.hopen:.q.hopen
    .sl.noinit:1b;
    `.q.hopen mock {[x] 0};
    @[system;"l feedCsv.q";0N];
    @[system;"l tickHFPublisher.q";0N];
    `destTab mock `$"universe",/: string 1+til 2;
    .fcsv.plug.enrich:()!();.fcsv.plug.validate:()!();
    .fcsv.plug.enrich[destTab,`universe`underlying]:{[x;y] x};
    .fcsv.plug.validate[destTab,`universe`underlying]:{[x;y]};
    // mock connection
    .hnd.hopen:{[x;y;z] `.hnd.status upsert ([server:enlist x] timeout:enlist y; handle:enlist 0)};
    `.fcsv.connName mock `in.tickHF;
    `.fcsv.cfg.serverDst mock `in.tickHF;
    .hnd.hopen[`in.tickHF;100i;`lazy];
    `.u.upd mock {x insert y};
    // mock models
    .fcsv.cfg.models:()!();
    `universe mock ([] time:`time$(); sym:`symbol$(); mat:`date$());
    destTab mock\: ([] time:`time$();sym:`symbol$(); under:`symbol$(); flag:());
    {.fcsv.cfg.models[x]:universe1} each destTab;
    `.fcsv.cfg.files mock ([] didirSrcr:`:test/tmp/universe`:test/tmp/underlying`:test/tmp/test;
      pattern:("*universe";"*underlying";"");
      destTab:`universe`underlying`;
      fileFormat:("TSD";"TSD";"");
      separator:(enlist each 3#";");
      upsertFormat:`
      );

    `.fcsv.cfg.files_new mock ([] dirSrc:`:test/tmp/universe1`:test/tmp/universe2;
      pattern:2#enlist"*universe";
      destTab:`$"universe",/: string 1+til 2;
      separator:(enlist each 2#";");
      fileFormat:(2#enlist "deprecated");
      headerInFile:(2#1b);
      fileModel:(
        flip `col1`col2!(0#`;0#`);
        // reorder
        flip `col1`col2!(`time`under`sym`flag;`TIME`SYMBOL`SYMBOL`CHAR)
        );
      file2Tab:(
        flip `col1`col2!(0#`;0#`);
        flip `col1`col2!(`time`sym`under`flag;`time`sym`under`flag)
        )
      );
    mockFiles[];
    };
  after{
    .tst.rm[`:test/tmp];
    };

  should["process data and publish in tick format"]{
    files:`:test/tmp/.img.test,.fcsv.p.find[`:test/tmp/universe;"*universe"][`ok];
    res:.fcsv.processData[files;`fileFormat`separator`destTab!("TSD";enlist";";`universe)];
    (file1,file2,file3) mustmatch res`ok;
    (`:test/tmp/.img.test,file6) mustmatch  res`corrupted;
    };

  should["process data and publish in tick format with configuration that contains fields (file2Tab,fileModel)"]{
    files:`:test/tmp/.img.test,.fcsv.p.find[`:test/tmp/universe1;"*universe"][`ok];
    res:.fcsv.processData[files;first .fcsv.cfg.files_new];
    (enlist file_1) mustmatch res`ok;
    (enlist `:test/tmp/.img.test) mustmatch  res`corrupted;
    2 mustmatch count universe1 ;
    };
  };



.tst.desc["test .fcsv.p.processFiles with storing parsed files to txt file"]{
  before{
    //        .t.hopen:.q.hopen
    .sl.noinit:1b;
    `.q.hopen mock {[x] 0};
    @[system;"l feedCsv.q";0N];
    @[system;"l tickLFPublisher.q";0N];
    .sl.relib[`$"qsl/handle"];
    // mock enrich and validate functions
    `destTab mock `$"universe",/: string 1+til 2;
    .fcsv.plug.enrich:()!();.fcsv.plug.validate:()!();
    .fcsv.plug.enrich[destTab,`universe`underlying]:{[x;y] x};
    .fcsv.plug.validate[destTab,`universe`underlying]:{[x;y]};
    .fcsv.p.processPending:.fcsv.p.updatePendingFiles;
    .fcsv.p.archiveFiles:.fcsv.p.updateParsedFiles;
    .fcsv.cfg.filesMoving:0b;
    .fcsv.cfg.parsedFiles:`:test/tmp/parsedFiles.txt;
    // mock connection
    .hnd.hopen:{[x;y;z] `.hnd.status upsert ([server:enlist x] timeout:enlist y; handle:enlist 0)};
    `.fcsv.connName mock `in.tickLF;
    `.fcsv.cfg.serverDst mock `in.tickLF;
    .hnd.hopen[`in.tickLF;100i;`lazy];
    `.tickLF.pubUpd`.tickLF.pubImg mock\: {x insert y};
    // mock models
    .fcsv.cfg.models:()!();
    `universe mock ([] time:`time$(); sym:`symbol$(); mat:`date$());
    destTab mock\: ([] time:`time$();sym:`symbol$(); under:`symbol$(); flag:());
    {.fcsv.cfg.models[x]:universe1} each destTab;
    // mock configuration
    // old configuration
    `.fcsv.cfg.files mock ([] dirSrc:`:test/tmp/universe`:test/tmp/underlying`:test/tmp/test;
      pattern:("*universe";"*underlying";"");
      destTab:`universe`underlying`;
      fileFormat:("TSD";"TSD";"");
      separator:(enlist each 3#";");
      upsertFormat:`
      );
    `.fcsv.cfg.files_new mock ([] dirSrc:`:test/tmp/universe1`:test/tmp/universe2;
      pattern:2#enlist"*universe";
      destTab:`$"universe",/: string 1+til 2;
      separator:(enlist each 2#";");
      fileFormat:(2#enlist "deprecated");
      headerInFile:(2#1b);
      fileModel:(
        flip `col1`col2!(0#`;0#`);
        // reorder
        flip `col1`col2!(`time`under`sym`flag;`TIME`SYMBOL`SYMBOL`CHAR)
        );
      file2Tab:(
        flip `col1`col2!(0#`;0#`);
        flip `col1`col2!(`time`sym`under`flag;`time`sym`under`flag)
        )
      );
    mockFiles[];
    };
  after{
    .tst.rm[`:test/tmp];
    };

  should["update txt file"]{
    .tst.rm[`:test/tmp];
    .fcsv.parsedFiles:();
    file1 0:";"0: data1;
    .fcsv.p.processFiles[.fcsv.cfg.files];
    2 mustmatch count universe;
    file1 mustin`$read0 .fcsv.cfg.parsedFiles;
    .fcsv.p.processFiles[.fcsv.cfg.files];
    2 mustmatch count universe;
    file2 0:";"0: data1;
    .fcsv.p.processFiles[.fcsv.cfg.files];
    (file1,file2) mustmatch`$read0 .fcsv.cfg.parsedFiles;
    4 mustmatch count universe;        
    file3 0:";"0: data1;
    .fcsv.p.processFiles[.fcsv.cfg.files];
    (file1,file2,file3) mustmatch`$read0 .fcsv.cfg.parsedFiles;
    };
  should["update txt file with configuration that contains fields (file2Tab,fileModel)"]{
    `.fcsv.cfg.files mock .fcsv.cfg.files_new;
    .tst.rm[`:test/tmp];
    .fcsv.parsedFiles:.fcsv.pendingFiles:();
    // ok state
    file_1 0:";"0: data_1;
    .fcsv.p.processFiles[.fcsv.cfg.files_new];
    2 mustmatch count universe1;
    file_1 mustin`$read0 .fcsv.cfg.parsedFiles;
    // pending state
    `.hnd.h mock {[x;y] '"can't open connection to ",string[x],", error: hop: Connection refused"};
    file_2 0:";"0: data_1;
    .fcsv.p.processFiles[configTable:.fcsv.cfg.files_new];
    0 mustmatch count universe2;
    file_2 mustnin`$read0 .fcsv.cfg.parsedFiles;
    file_2 mustin`$read0 `:test/tmp/pendingFiles.txt;
    `.hnd.h mock {[x;y] 0 y};
    // process pending files
    .fcsv.p.updatePendingFiles[];
    (file_1,file_2) mustmatch`$read0 .fcsv.cfg.parsedFiles;
    (0#`) mustmatch`$read0 .fcsv.cfg.pendingFiles;
    2 mustmatch count universe2;
    };

  should["update txt file"]{
    .tst.rm[`:test/tmp];
    .fcsv.parsedFiles:();
    file1 0:";"0: data1;
    file2 0:";"0: data1;
    file3 0:";"0: data1;
    file4 0:";"0: data1;
    file5 0:";"0: data1;
    file6 set `a`b`c!1 2 3;
    .fcsv.p.processFiles[.fcsv.cfg.files];
    4 mustmatch count universe;
    (file1,file2,file4,file3,file6,file5) mustmatch`$read0 .fcsv.cfg.parsedFiles;
    .fcsv.p.processFiles[.fcsv.cfg.files];
    (file1,file2,file4,file3,file6,file5) mustmatch`$read0 .fcsv.cfg.parsedFiles;
    };
  };
/
.event.hist
.tst.report
.tmr.status

