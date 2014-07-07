// q test/hk_test.q --noquit -p 5001

\l lib/qspec/qspec.q
\l lib/qsl/sl.q

.sl.init[`test];

.tst.desc["test initialization"]{
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
    system "touch -d '5 days ago' "," " sv 1_/:string bigfilelist[0];
    system "touch -d '10 days ago' "," " sv 1_/:string smallfilelist[0];
    };
  after{
    .tst.rm `:test/datadir;
    };
  should["perform full housekeepeing"]{
    big:key bigfiles;
    many:key manyfiles;
    .hk.processAllTasks[.hk.taskList];
    count[big] mustgt count[key bigfiles];
    bigfilelist[1] mustmatch ` sv/:bigfiles,/:asc k:key bigfiles;

    count[many] musteq count[key manyfiles];
    25 musteq count k where (k:key manyfiles) like "*.tar.gz";
    smallfilelist[1] mustmatch ` sv/:manyfiles,/:asc k where not (k:key manyfiles) like "*.tar.gz";
    system "touch -d '20 days ago' ", " " sv 1_/:string ` sv/:manyfiles,/:asc k where (k:key manyfiles) like "*.tar.gz"
    .hk.processAllTasks[.hk.taskList];
    25 musteq count k where (k:key manyfiles) like "*.tar.gz";
    0 musteq count k where (k:key manyfiles) like "*.tar.gz.tar.gz";
    };
  }
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