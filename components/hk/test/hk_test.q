// q test/hk_test.q --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q
\l lib/qsl/os.q

.sl.init[`test];

/------------ creates a date string tha is acceptable for touch on Linux and UnxUtil's touch on Windows
.tst.p.daysAgo:{[n]
    d:"." vs string .z.d-n;
	dstr:2_d[0],d[1],d[2];
    :$["w"~first string .z.o;"-d ",dstr;"-t ",dstr,"0000"];
    };

/F/ os dependent zip extension
.tst.p.zipExt:$["w"~first string .z.o;".zip";".tar.gz"];

.tst.desc["deleting and compressing"]{
  before{
    .sl.noinit:1b;
    @[system;"l hk.q";0N];
    `bigfiles mock `:test/datadir/bigfiles;
    `manyfiles mock `:test/datadir/manyfiles;
    `.hk.taskList mock ([] action:`delete`compress;dir:(bigfiles;manyfiles); age:4 8;pattern:(`$"*.bigs";`$"*.files");proc:`proc1`proc2);
    //preparation of files delete for delete 
    bigdata:`float$til 100000;
    smalldata:1 2 3;
    //0 are files to delete, 1 are files that stay after hk run (not meeting the age constraint)
    `bigfilelist mock 2 0N#` sv/:bigfiles,/:`$string[til 50],\:".bigs";
    `smallfilelist mock 2 0N#` sv/:manyfiles,/:`$string[til 50],\:".files";
    bigfilelist set\:\: bigdata;
    smallfilelist set\:\: smalldata;
    //alter timestamps
    system .os.slash "touch ",(.tst.p.daysAgo 5)," "," " sv 1_/:string bigfilelist[0];
    system .os.slash "touch ",(.tst.p.daysAgo 10)," "," "sv 1_/:string smallfilelist[0];
    };
  after{
    .os.rmdir "test/datadir";
    };
  should["perform full housekeeping"]{
    big:key bigfiles;
    many:key manyfiles;
    .hk.processAllTasks[.hk.taskList];
    count[big] mustgt count[key bigfiles];
    bigfilelist[1] mustmatch ` sv/:bigfiles,/:asc k:key bigfiles;

    count[many] musteq count[key manyfiles]; // fails
	
    25 musteq count k where (k:key manyfiles) like "*",.tst.p.zipExt;
    smallfilelist[1] mustmatch ` sv/:manyfiles,/:asc k where not (k:key manyfiles) like "*",.tst.p.zipExt;
    //system "touch -d '20 days ago' ", " " sv 1_/:string ` sv/:manyfiles,/:asc k where (k:key manyfiles) like "*",.tst.p.zipExt;
	system "touch ",(.tst.p.daysAgo 20)," "," " sv 1_/:string ` sv/:manyfiles,/:asc k where (k:key manyfiles) like "*",.tst.p.zipExt;
    .hk.processAllTasks[.hk.taskList];
    25 musteq count k where (k:key manyfiles) like "*",.tst.p.zipExt;
    0 musteq count k where (k:key manyfiles) like "*",.tst.p.zipExt,.tst.p.zipExt;
    };
  };
\
.hk.p.processOneTask:{[taskDef]
  plugin:` sv (`.hk.plug;taskDef[`action]);
  findCmd:"find ",1_string[taskDef[`dir]]," -mtime +",string[taskDef[`age]], " -name '",string[taskDef[`pattern]],"' -prune";
  files:`$.pe.at[system;findCmd;{[cmd;sig] .log.error[`hk] "error while calling \"",cmd,"\". Maybe invalid arguments?"; :()}[findCmd;]];
  \cd
  .log.info[`hk] "Running ",string[plugin], " for ", string[taskDef[`proc]], " on ",string[count files], " files";
  {[plugin;file] .pe.at[value plugin;file;{[plugin;file;sig] .log.error[`hk] raze "Signal on plugin: ",string[plugin],", file: ",string[file]," - ",string[sig]}[plugin;file;]]}[plugin;] each files;
  }
taskDef:last .hk.taskList
