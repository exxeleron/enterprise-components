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

/A/ DEVnet:  Bartosz Dolecki
/V/ 3.0

/S/ Hdb synchronization tool:
/S/ Responsible for:
/S/ - performing file marshalling between the sites
/S/ - saving .sym file at backup location
/S/ - synchronization of partitions between hosts
/S/ - providing backward backup of new (freshly added) columns
/S/ 
/S/ Input parameters for the script:
/S/ hdbSync.q is invoked from eodMng.q process and receives following input parameters
/S/ source directory - source directory for synchronization
/S/ destination directory - destination directory for synchronization
/S/ partition - defines partition name, if unpartitioned please pass an empty string ("")
/S/ sym backup directory - backup directory for sym file
/S/ status file (optional) - path to the file where housekeeping status is stored (required for eodMng communication)
/S/ 
/S/ *Sample command using yak*
/S/ (start code)
/S/ yak start hdbSync.q -a "source:/hdb destination:/mirror/hdb 2001.04.23 /backups/hdbsym/ /comm/statusFile.out"
/S/ (end)
/S/ 
/S/ This command
/S/ - Performs backup of the sym file from destination
/S/ (start code)
/S/ /mirror/hdb/sym
/S/ (end)
/S/ to
/S/ (start code)
/S/ /backups/hdbsym/
/S/ (end)
/S/ - Copies partition 2001.04.23 source
/S/ (start code)
/S/ /hdb/2001.04.23
/S/ (end)
/S/ to destination
/S/ (start code)
/S/ /mirror/hdb
/S/ (end)
/S/ - Writes status (in this case 'successful') to 
/S/ (start code)
/S/ /comm/statusFile.out
/S/ (end)
/S/ 
/S/ Prerequisites:
/S/ 1. - rsync installed and available (used for all file transfers) 
/S/ 2. - ssh installed and available
/S/ 3. - Automatic ssh validation with remote host (no password required when connecting via ssh to remote host)
/S/ 4. - For synchronization, databases must have the same format (ie. both have to be partitioned or segmented)
/S/ 5. - Additionally segmented databases need to have the same amount of partitions on both sides (otherwise error will be reported)
/S/ 
/S/ Note:
/S/ As of now, both partitioned and segmented (with par.txt) databases are supported.

/------------------------------------------------------------------------------/

system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`hdbSync];

/------------------------------------------------------------------------------/
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/timer"];
.sl.lib["qsl/os"];

/------------------------------------------------------------------------------/
/G/ source directory for synchronization
.hdbSync.cfg.source:.z.x[0];
/G/ destination directory for synchronization
.hdbSync.cfg.destination:.z.x[1];
/G/ defines partition name, if unpartitioned please pass an empty string ("")
.hdbSync.cfg.partition:.z.x[2];
/G/ backup directory for sym file
.hdbSync.cfg.symDir:.z.x[3];
/G/ path to the file where status is stored (required for eodMng communication)
.hdbSync.cfg.statusFile:$[4 < count .z.x;hsym `$.z.x[4];`];

/F/ main function of the script; writes appropriate messages to the status file
/F/ while performing each of these major activities:
/F/   - backup of the sym file
/F/   - synchronization of the whole partition
/F/   - synchronization of the whole database if column / table was added / removed
/F/ 
/P/ sourceDir:STRING - source directory for synchronization
/P/ destDir:STRING - destination directory for synchronization
/P/ partition:STRING - defines partition name (if unpartitioned pass emmpty string : "")
.hdbSync.performSync:{[sourceDir;destDir;partition]
  .log.info[`hdbSync]"Start hdb synchronization with parameters: ", .Q.s1(sourceDir;destDir;partition);
  .hdbSync.p.saveStatus[`begin];
  
  parSrc:.hdbSync.p.getPar[sourceDir];
  parDest:.hdbSync.p.getPar[destDir];
  if[(parSrc~`error) or (parDest~`error);
    .log.error[`hdbSync] "There were host connectivity errors - hdbSync will finish now.";
    :();
    ];
  
  if[(count parSrc)<>(count parDest);
    .log.error[`hdbSync] "Number of partitions on hdb differ - hdbSync will finish now.";
    :();
    ];
  
  .hdbSync.source:?[partition~""; 
    sourceDir;
    .hdbSync.p.getDatePath[parSrc;"D"$partition]
    ];
  .hdbSync.dest:?[partition~""; 
    destDir;
    .hdbSync.p.getDatePath[parDest;"D"$partition]
    ];
  .os.mkdir .hdbSync.cfg.symDir;
  system "rsync -rvce ssh \"",destDir,"/sym\" \"", .hdbSync.cfg.symDir,"/",ssr[string .sl.zz[];":";"."],".sym\"";
  system "rsync -vce ssh \"",sourceDir,"/sym\" \"", destDir,"/sym\"";
  .hdbSync.p.saveStatus[`sync_partition];
  
  tbls:key hsym `$.hdbSync.dest;
  oldColumns: ({key hsym `$x,"/",string y}[.hdbSync.dest;] each tbls);
  
  system "rsync -rvce ssh \"",.hdbSync.source,"/\" \"", .hdbSync.dest,"/\"";
  .hdbSync.p.saveStatus[`sync_all];
  
  tbls:key hsym `$.hdbSync.dest;
  newColumns:({key hsym `$x,"/",string y}[.hdbSync.dest;] each tbls);

  addedColumns:newColumns except oldColumns;
  addedColumns,:oldColumns except newColumns;
  if[(0 < count addedColumns) & not partition~"";
    .log.info[`hdbSync] "   New columns added - synchronizing full base";
    parSrc {[src;dest] system "rsync -rve ssh \"",src,"/\" \"", dest,"\""}' parDest;
    ];

  .hdbSync.p.saveStatus[`success];
  .log.info[`hdbSync]"hdb synchronization completed";
  };

/F/ function that returns path to segmented hdb for given date
/P/ pars : STRING LIST - list of paths to segments (contents of par.txt)
/P/ date : DATE - date for which path should be computed
.hdbSync.p.getDatePath:{[pars;date]
  :pars[date mod count pars],"/",string[date];
  };

/F/ function that reads and returns par.txt content
/P/ path : STRING - path (optionally with hostname) where par.txt is located
.hdbSync.p.getPar:{[path]
  urls:":" vs path;
  host:first urls;
  hdbPath:last urls;
  cmdExists:"test -e ",hdbPath,"/par.txt";
  cmdCat:"cat ",hdbPath,"/par.txt";

  if[1<count urls; //remote
    cmdExists:"ssh ",host," \"",cmdExists,"\"";
    cmdCat:"ssh ",host," \"",cmdCat,"\"";
    ];
  
  if[`notExists~.pe.at[system;cmdExists;{[s] `notExists}]; // no par.txt
    :enlist path;
    ];
  
  // par.txt.present
  pars:.pe.at[system;cmdCat;{[s] `netowrkError}];
  if[`networkError~pars;
    log.error[`hdbSync] "Error when calling ",cmdCat,". Further sync won't be performed";
    :`error;
    ];
  
  if[1<count urls; //remote
    pars:(host,":"),/:pars;
    ];
  :pars;
  };
    
    
/F/ function that saves status to file
/P/ status : Symbol - status to write
.hdbSync.p.saveStatus:{[status]
  if[not `~ .hdbSync.cfg.statusFile;
    .pe.at[.hdbSync.cfg.statusFile 0: enlist (string status)," ",(string .sl.zz[])];
    ];
  };

/------------------------------------------------------------------------------/
if[0~count .z.x;
  .log.error[`hdbHk]"Missing input parameters. Source, destination, partition name and sym backup directory are obligatory";
  .log.info[`hdbHk]"Usage example: yak start batch.core_hdbSync -a \"source:/hdb destination:/mirror/hdb 2001.04.23 /backups/hdbsym/ [/comm/statusFile.out]\"";
  exit 0;
  ];


.sl.main:{[flags]
  if["w"~first string .z.o;.log.fatal[`hk] "hdbSync.q has not been ported to Windows yet";'`$"nyi"];
  };

.sl.run[`hdbSync;`.sl.main;`];    
.hdbSync.performSync[.hdbSync.cfg.source;.hdbSync.cfg.destination;.hdbSync.cfg.partition];
exit 0;
