// q test/hdbSync_test.q noexit source dest partition --noquit -p 5001

\l lib/qspec/qspec.q


.tst.desc[".hdbSync.performSync"]{
  before{
    `table1 mock ([] sym:`a`a`b; time:`time$00:00 00:01 00:00; col1:1 2 1;col2:1 2 1);
    `table2 mock ([] sym:`a`a`b; time:`time$00:00 00:01 00:00; col1:1 2 1;col2:1 2 1);
    .Q.dpft[`:test/tmp/hdb/;2012.01.01;`sym;`table1];
    .Q.dpft[`:test/tmp/hdb/;2012.01.01;`sym;`table2];
    `table1 mock ([] sym:`a`a`b; time:`time$00:00 00:01 00:00; col1:3 3 3; col2:3 3 3);
    `table2 mock ([] sym:`a`a`b; time:`time$00:00 00:01 00:00; col1:3 3 3);
    .Q.dpft[`:test/tmp/hdb1/;2012.01.01;`sym;`table1];
    .Q.dpft[`:test/tmp/hdb1/;2012.01.01;`sym;`table2];
    `.hdbSync.cfg.symDir mock "test/tmp/symDir";
    `.hdbSync.cfg.statusFile mock `:test/tmp/statusFile;
    cd:system"cd";
    .sl.noinit:1b;
    @[system;"l hdbSync.q";0N];
    `sourceDir mock string[.z.h],":", cd,"/test/tmp/hdb";
    `destDir mock cd,"/test/tmp/hdb1";
    `partition mock "2012.01.01";
    };
  after{
    .tst.rm[`:test/tmp];
    };
  should["perform sync"]{
    .hdbSync.performSync[sourceDir;destDir;partition];
    1 2 1 mustmatch  get`:test/tmp/hdb1/2012.01.01/table1/col1;
    1 2 1 mustmatch  get`:test/tmp/hdb1/2012.01.01/table2/col1;
    1 2 1 mustmatch  get`:test/tmp/hdb1/2012.01.01/table1/col2;
    1 2 1 mustmatch  get`:test/tmp/hdb1/2012.01.01/table2/col2;
    };
  };

/
.tst.report