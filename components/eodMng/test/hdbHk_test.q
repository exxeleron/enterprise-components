// q test/hdbHk_test.q noexit -hdb -hdbConn --noquit  -p 5001

\l lib/qspec/qspec.q

.tst.desc[".hdbHk.p.saveStatus"]{
  before{
    .sl.noinit:1b;
    @[system;"l hdbHk.q";0N];
    `.hdbHk.cfg.statusFile mock `:test/tmp/status/hkStatus;
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["create status file"]{
    .hdbHk.p.saveStatus[`test];
    1 mustmatch count read0 .hdbHk.cfg.statusFile;
    };
  should["failed when creating status file"]{
    .tst.mockFunc[`.log.warn;2;""];
    .hdbHk.p.saveStatus["test"];
    () mustmatch key .hdbHk.cfg.statusFile;
    .tst.trace[`.log.warn] mustmatch enlist(`hdbHk;"Save status file:test/tmp/status/hkStatus failed with: type");
    };
  };

.tst.desc[".hdbHk.p.deleteOldBackups"]{
  before{
    .sl.noinit:1b;
    @[system;"l hdbHk.q";0N];
    `.hdbHk.cfg.hdbConn mock `core.hdb;
    `.hdbHk.cfg.bckDays mock 1;
    `date mock .z.d;
    `bckdir mock `$":test/tmp/bckdir/";
    (`$string[bckdir],"core.hdb",string[date-1],"/par/table") set 1;
    (`$string[bckdir],"core.hdb",string[date-2],"/par/table") set 1;
    (`$string[bckdir],"core.hdb",string[`test],"/par/table") set 1;
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["delete backup files"]{
    .hdbHk.p.deleteOldBackups[date;bckdir];
    ((`$"core.hdb",string[.z.d-1]),`core.hdbtest) mustmatch key bckdir;
    };
  should["failed when deleting backup files"]{
    .tst.mockFunc[`.hdbHk.p.deleteOneDir;2;"'stop"];
    .hdbHk.p.deleteOldBackups[date;bckdir];
    3 mustmatch count key bckdir;
    };
  };

.tst.desc[".hdbHk.p.getPartsHdb"]{
  before{
    .sl.noinit:1b;
    @[system;"l hdbHk.q";0N];
    `.hdbHk.cfg.hdbPath mock `:test/tmp/hdb;
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["return dirs from par.txt"]{
    `par mock ("test/tmp/par1/";"test/tmp/par2/");
    `:test/tmp/hdb/par.txt 0: par;
    par mustmatch .hdbHk.p.getPartsHdb[.hdbHk.cfg.hdbPath];
    };
  should["return empty list if par.txt doesn't exist"]{
    () mustmatch .hdbHk.p.getPartsHdb[.hdbHk.cfg.hdbPath];
    };
  };

.tst.desc[".hdbHk.getDateHnd"]{
  before{
    .sl.noinit:1b;
    @[system;"l hdbHk.q";0N];
    `.hdbHk.cfg.hdbPath mock `:test/tmp/hdb;
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["return dirs from par.txt"]{
    `.hdbHk.cfg.hdbPars mock ("test/tmp/par1/";"test/tmp/par2/");
    `:test/tmp/par2//2012.01.01 mustmatch .hdbHk.getDateHnd[2012.01.01];
    `:test/tmp/par1//2012.01.02 mustmatch .hdbHk.getDateHnd[2012.01.02];
    };
  should["return one dir par.txt doesn't exist"]{
    `.hdbHk.cfg.hdbPars mock ();
    `:test/tmp/hdb/2012.01.01 mustmatch .hdbHk.getDateHnd[2012.01.01];
    };
  };


.tst.desc[".hdbHk.p.pluginAct"]{
  before{
    .sl.noinit:1b;
    @[system;"l hdbHk.q";0N];
    `.hdbHk.cfg.bckDir mock `:test/tmp/backup;
    `.hdbHk.cfg.hdbPath mock `:test/tmp/hdb;
    `.hdbHk.cfg.hdbPars mock ();
    .tst.mockFunc[`.hdbHk.plug.action.test;3;""];
    `:test/tmp/hdb/2012.01.01/table1 set 1;
    `:test/tmp/hdb/2012.01.01/table2 set 1;
    
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["exit if partition doesn't exist"]{
    `.hdbHk.getDateHnd mock {[x] `:tmp};
    .tst.mockFunc[`.log.warn;2;""];
    () mustmatch .hdbHk.p.pluginAct[date:2012.01.01;plugin:`a;tabs:`a;when:1;args:()];
    .tst.trace[`.log.warn] mustmatch enlist((`hdbHk;"Partition :tmp does not exist"));
    };
  should["perform plugin and create a backup"]{
    .hdbHk.p.pluginAct[2012.01.02;`test;`table1`table2;1;()];
    enlist[`2012.01.01] mustmatch key .hdbHk.cfg.bckDir;
    `table1`table2 mustmatch   key `:test/tmp/backup/2012.01.01;
    2 mustmatch count .tst.trace[`.hdbHk.plug.action.test];
    };
  should["failed while performing the plugin"]{
    .tst.mockFunc[`.hdbHk.plug.action.test;3;"'stop"];
    .tst.mockFunc[`.log.error;2;""];
    .hdbHk.p.pluginAct[2012.01.02;`test;`table1`table2;when:1;()];
    enlist[`2012.01.01] mustmatch key .hdbHk.cfg.bckDir;
    `table1`table2 mustmatch   key `:test/tmp/backup/2012.01.01;
    2 mustmatch count .tst.trace[`.hdbHk.plug.action.test];
    2 mustmatch count .tst.trace[`.log.error];
    };
  };

.tst.desc["test plugins"]{
  before{
    .sl.noinit:1b;
    @[system;"l hdbHk.q";0N];
    `table1 mock ([] sym:`a`a`b; time:`time$00:00 00:01 00:00; col1:1 2 1;col2:1 2 1);
    .Q.dpft[`:test/tmp/hdb/;2012.01.01;`sym;`table1];
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["perform .hdbHk.plug.action[`compress]"]{
    .hdbHk.plug.action[`compress][date:2012.01.01;tableHnd:`:test/tmp/hdb/2012.01.01/table1;args:(12;2;7)];
    5 mustmatch count (-21!`:test/tmp/hdb/2012.01.01/table1/col1);
    };
  should["perform .hdbHk.plug.action[`delete]"]{
    .hdbHk.plug.action[`delete][date:2012.01.01;tableHnd:`:test/tmp/hdb/2012.01.01/table1;args:()];
    (0#0nj) mustmatch  get `:test/tmp/hdb/2012.01.01/table1/col1;
    };
  should["perform .hdbHk.plug.action[`conflate]"]{
    .hdbHk.plug.action[`conflate][date:2012.01.01;tableHnd:`:test/tmp/hdb/2012.01.01/table1;args:enlist `60000];
    (2 1) mustmatch  get `:test/tmp/hdb/2012.01.01/table1/col1;
    };
  should["perform .hdbHk.plug.action[`mrvs]"]{
    .hdbHk.plug.action[`mrvs][date:2012.01.01;tableHnd:`:test/tmp/hdb/2012.01.01/table1;args:()];
    (2 1) mustmatch  get `:test/tmp/hdb/2012.01.01/table1/col1;
    };

  };

.tst.desc[".hdbHk.performHk"]{
  before{
    .sl.noinit:1b;
    @[system;"l hdbHk.q";0N];
    `table1 mock ([] sym:`a`a`b; time:`time$00:00 00:01 00:00; col1:1 2 1;col2:1 2 1);
    `table2 mock ([] sym:`a`a`b; time:`time$00:00 00:01 00:00; col1:1 2 1;col2:1 2 1);
    .Q.dpft[`:test/tmp/hdb/;2012.01.03;`sym;`table1];
    .Q.dpft[`:test/tmp/hdb/;2012.01.02;`sym;`table1];
    .Q.dpft[`:test/tmp/hdb/;2012.01.01;`sym;`table2];
    .Q.chk[`:test/tmp/hdb/];
    .tst.mockFunc[`.hnd.hopen;3;""];
    `.hnd.ah mock {[x;y]};
    
    
    cmdParams:enlist each `hdb`hdbConn`date`status!("test/tmp/hdb";"core.hdb";"2012.01.01";"test/tmp/status/hkStatus");
    /cmdParams:`hdb`hdbConn!("test/tmp/hdb";"core.hdb");

    `.hdbHk.cfg.hdbPath mock hsym `$first cmdParams`hdb;
    `.hdbHk.cfg.hdbPars mock .hdbHk.p.getPartsHdb[.hdbHk.cfg.hdbPath];
    `.hdbHk.cfg.hdbConn mock`$first cmdParams`hdbConn;

    `.hdbHk.cfg.statusFile mock $[`status in key cmdParams;hsym `$first cmdParams`status;`];
    `.hdbHk.cfg.date mock $[`date in key cmdParams;"D"$first cmdParams`date;.sl.eodSyncedDate[]];
    `.hdbHk.cfg.bckDir mock `:test/tmp/bckDir/;
    `.hdbHk.cfg.bckDays mock 1;
    `.hdbHk.cfg.raportDir mock `:test/tmp/raportDir/;
    `.hdbHk.cfg.taskList mock flip `action`table`dayInPast`param1`param2`param3`param4`param5`param6!(`compress`delete`conflate;`table1`table1`ALL;1 2 3;`12``60000;`2``;`7``;```;```;```);
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["perform hk"]{
    .hdbHk.performHk[date:2012.01.04];
    5 mustmatch count -21!`:test/tmp/hdb/2012.01.03/table1/col1;
    0 mustmatch count get`:test/tmp/hdb/2012.01.02/table1/col1;
    (2 1) mustmatch get`:test/tmp/hdb/2012.01.01/table2/col1;
    };
  };

/
.tst.report
