/L/ Copyright (c) 2011-2014 Exxeleron GmbH
/-/
/-/ Licensed under the Apache License, Version 2.0 (the "License");
/-/ you may not use this file except in compliance with the License.
/-/ You may obtain a copy of the License at
/-/
/-/   http://www.apache.org/licenses/LICENSE-2.0
/-/
/-/ Unless required by applicable law or agreed to in writing, software
/-/ distributed under the License is distributed on an "AS IS" BASIS,
/-/ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/-/ See the License for the specific language governing permissions and
/-/ limitations under the License.

/A/ DEVnet:  Bartosz Dolecki
/V/ 3.0

/S/ Hdb synchronization tool:
/-/ Responsible for:
/-/ - performing file marshalling between the sites
/-/ - saving .sym file at backup location
/-/ - synchronization of partitions between hosts
/-/ - providing backward backup of new (freshly added) columns
/-/ 
/-/ Input parameters for the script:
/-/ hdbSync.q is invoked from eodMng.q process and receives following input parameters
/-/ source directory - source directory for synchronization
/-/ destination directory - destination directory for synchronization
/-/ partition - defines partition name, if unpartitioned please pass an empty string ("")
/-/ sym backup directory - backup directory for sym file
/-/ status file (optional) - path to the file where housekeeping status is stored (required for eodMng communication)
/-/ 
/-/ *Sample command using yak*
/-/ (start code)
/-/ yak start hdbSync.q -a "source:/hdb destination:/mirror/hdb 2001.04.23 /backups/hdbsym/ /comm/statusFile.out"
/-/ (end)
/-/ 
/-/ This command
/-/ - Performs backup of the sym file from destination
/-/ (start code)
/-/ /mirror/hdb/sym
/-/ (end)
/-/ to
/-/ (start code)
/-/ /backups/hdbsym/
/-/ (end)
/-/ - Copies partition 2001.04.23 source
/-/ (start code)
/-/ /hdb/2001.04.23
/-/ (end)
/-/ to destination
/-/ (start code)
/-/ /mirror/hdb
/-/ (end)
/-/ - Writes status (in this case 'successful') to 
/-/ (start code)
/-/ /comm/statusFile.out
/-/ (end)
/-/ 
/-/ Prerequisites:
/-/ 1. - rsync installed and available (used for all file transfers) 
/-/ 2. - ssh installed and available
/-/ 3. - Automatic ssh validation with remote host (no password required when connecting via ssh to remote host)
/-/ 4. - For synchronization, databases must have the same format (ie. both have to be partitioned or segmented)
/-/ 5. - Additionally segmented databases need to have the same amount of partitions on both sides (otherwise error will be reported)
/-/ 
/-/ Note:
/-/ As of now, both partitioned and segmented (with par.txt) databases are supported.

/------------------------------------------------------------------------------/

system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`hdbSync];

/------------------------------------------------------------------------------/
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/timer"];
.sl.lib["qsl/os"];

/------------------------------------------------------------------------------/
/G/ Source directory for synchronization, loaded from 1st cmd line argument.
.hdbSync.cfg.source:.z.x[0];

/G/ Destination directory for synchronization, loaded from 2nd cmd line argument.
.hdbSync.cfg.destination:.z.x[1];

/G/ Partition name, if unpartitioned please pass an empty string (""), loaded from 3rd cmd line argument.
.hdbSync.cfg.partition:.z.x[2];

/G/ Backup directory for sym file, loaded from 4th cmd line argument.
.hdbSync.cfg.symDir:.z.x[3];

/G/ Path to the file where status is stored (required for eodMng communication).
.hdbSync.cfg.statusFile:$[4 < count .z.x;hsym `$.z.x[4];`];

/------------------------------------------------------------------------------/
/F/ Performs synchronization of two hdb dirctories. Backups sym file.
/-/ Main function of the script; writes appropriate messages to the status file while performing each of these major activities
/-/   - backup of the sym file
/-/   - synchronization of the whole partition
/-/   - synchronization of the whole database if column / table was added / removed
/P/ sourceDir:STRING - source directory for synchronization
/P/ destDir:STRING   - destination directory for synchronization
/P/ partition:STRING - defines partition name (if unpartitioned pass emmpty string : "")
/R/ no return value
/E/ .hdbSync.performSync[.hdbSync.cfg.source;.hdbSync.cfg.destination;.hdbSync.cfg.partition];
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

/------------------------------------------------------------------------------/
/F/ Returns path to segmented hdb for given date.
/P/ pars:LIST STRING - list of paths to segments (contents of par.txt)
/P/ date:DATE - date for which path should be computed
.hdbSync.p.getDatePath:{[pars;date]
  :pars[date mod count pars],"/",string[date];
  };

/------------------------------------------------------------------------------/
/F/ Reads and returns par.txt content.
/P/ path:STRING - path (optionally with hostname) where par.txt is located
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
    
    
/------------------------------------------------------------------------------/
/F/ Saves status to file.
/P/ status:SYMBOL - status to write
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
