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

/A/ DEVnet: Joanna Jarmulska
/V/ 3.0
/S/ Csv feed component:
/S/ Responsible for:
/S/ - providing fully customizable and configurable CSV file parser
/S/ - enabling automatic detection of CSV input files in specified locations, matching predefined pattern of the file names
/S/ - shielding system from corrupted data sets
/S/ - publishing parsed files to the TickerPlant in tickLF (<tickLF.q>) or tickHF (<tickHF.q>) protocol
/S/ - archiving processed files (optionally)
/S/ - parsing pending files - helpful when destination server is inactive and parsed files are marked as pending; in this case reconnecting procedure will try to establish new connection - after it's done pending files will be automatically processed
/S/ Note:
/S/ Depending on which component is triggered (*<.tickLF.pubUpd>* or *<.tickLF.pubImg>*), each file name should be preceded by either *upd* or *img* respectively. For example: YYYY.DD.MM.*upd*.table.csv, YYYY.DD.MM.*img*.table.csv.
/S/ Defining custom plugins:
/S/ Signature for plugin for data enrichment, returns TABLE
/S/ (start code)
/S/ .fcsv.plug.enrich[table(SYMBOL)][data(TABLE);fileName(SYMBOL)]
/S/ (end)
/S/ Example
/S/ (start code)
/S/ .fcsv.plug.enrich[`universe]:{[data;file] update time:file from data}
/S/ (end)
/S/ Signature for plugin for data validation, returns signal in case of failed validation
/S/ (start code)
/S/ .fcsv.plug.validate[tableName(SYMBOL)][data(TABLE);fileName(SYMBOL)]
/S/ (end)
/S/ Example
/S/ (start code)
/S/ .fcsv.plug.validate[`universe]:{[data;file] if[not meta[data]~meta universe;'failed]}
/S/ (end)

/T/ FeedCsv library doesn't contain any default protocol to publish parsed files, therefore feedCsv component should be started using following modes
/T/ - mode compatible with *tickLF* protocol
/T/ (start code)
/T/ q feedCsv.q -lib tickLFPublisher.q -p 5001
/T/ (end)
/T/ - mode compatible with *tickHF* protocol
/T/ (start code)
/T/ q feedCsv.q -lib tickHFPublisher.q -p 5001
/T/ (end)
/T/ - example of startup command with *plugins*
/T/ (start code)
/T/ q feedCsv.q -lib tickHFPublisher.q plugins/feedCsvPlugin.q -p 5001
/T/ (end)

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`feedCsv];

/------------------------------------------------------------------------------/
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/handle"];
.sl.lib["qsl/timer"];

/------------------------------------------------------------------------------/
/G/ initial definition for data enrichment
.fcsv.plug.enrich:()!();
/G/ initial definition for data validation
.fcsv.plug.validate:()!();
/G/ list of parsed files (used if cfg.filesMoving:0b)
.fcsv.parsedFiles:();
/G/ list of pending files (used if cfg.filesMoving:0b)
.fcsv.pendingFiles:();

/------------------------------------------------------------------------------/
/F/ main function for files processing that is called on timer
/F/ - files searching
/F/ - call .fcsv.processData
/F/ - files archiving
/P/ configTable - configuration from .fcsv.cfg.files
/E/ configTable:.fcsv.cfg.files
/E/ configTable:([] dir:`:test/tmp/universe`:test/tmp/underlying;
/E/     pattern:("*universe";"*underlying");
/E/     destTab:`universe`underlying;
/E/     fileFormat:("TSD"; "TSS");
/E/     separator:(";");
/E/     );
.fcsv.p.processFiles:{[configTable]
    if[not count configTable;
      .log.info[`feedCsv] "Empty configTable - nothing to process.";
      :()
      ];
    files0:.fcsv.p.find'[configTable`dirSrc;configTable`pattern];
    configTable:update ii:i from configTable,'files0;
    toRead:select from configTable where (0<count'[ok]),(not ok~'`);
    if[not count toRead;:()];
    files:.fcsv.processData'[toRead`ok;toRead];
    toRead:toRead,'([] ok:files`ok;corrupted1:files`corrupted; pending:files`pending);
    corrupted:select dirSrc,corrupted:(corrupted,'corrupted1),pending from configTable lj `ii xkey toRead;
    .fcsv.p.archiveFiles[(toRead;corrupted)];
    };

/------------------------------------------------------------------------------/
/F/ move files to archive, corrupted directories
/E/ info:(toRead;corrupted)
.fcsv.p.moveFiles:{[info]
    {[dir;f].pe.dotLog[`fCsv;`.fcsv.p.storeFiles;(f;`archive;dir;`$string`month$.sl.zd[]);();`warn]}./:
        flip value flip ungroup select dirSrc,ok from info[0] where (0<count'[ok]),(not ok~'`);
    {[dir;f].pe.dotLog[`fCsv;`.fcsv.p.storeFiles;(f;`corrupted;dir;`$string`month$.sl.zd[]);();`warn]}./:
        flip value flip ungroup select dirSrc,corrupted from info[1] where (0<count'[corrupted]),(not corrupted~'`);
    {[dir;f].pe.dotLog[`fCsv;`.fcsv.p.storeFiles;(f;`pending;dir;`);();`warn]}./:
        flip value flip ungroup select  dirSrc,pending from info[1] where (0<count'[pending]),(not pending~'`);
    };

/------------------------------------------------------------------------------/
/F/ update txt file (.fcsv.cfg.parsedFiles) with parsed files
/E/ info:(toRead;corrupted)
.fcsv.p.updateParsedFiles:{[info]
    ok:exec ok from info[0] where (0<count'[ok]),(not ok~'`);
    corrupted:exec corrupted from info[1] where (0<count'[corrupted]),(not corrupted~'`);
    pending:exec pending from info[1] where (0<count'[pending]),(not pending~'`);
    .fcsv.parsedFiles:distinct .fcsv.parsedFiles,raze string ok,corrupted;
    .fcsv.pendingFiles:distinct .fcsv.pendingFiles,raze string pending;
    .log.debug[`fCsv] "Save loaded files on disk ",string .fcsv.cfg.parsedFiles;
    .fcsv.cfg.parsedFiles 0: .fcsv.parsedFiles;
    .log.debug[`fCsv] "Save pending files on disk ",string .fcsv.cfg.pendingFiles;
    .fcsv.cfg.pendingFiles 0: .fcsv.pendingFiles;
    };

/------------------------------------------------------------------------------/
/F/ files searching
/E/ dir:`:test/tmp/underlying
/E/ pattern:"*underlying"
.fcsv.p.find:{[dir;pattern]
    .log.debug[`fCsv] "Searching for files in directory ",string[dir], " that are maching the pattern: ", pattern;
    files:f where(f:key dir) like pattern;
    corrupted:` sv/:dir,/: f except files;
    corrupted:corrupted except `$.fcsv.parsedFiles,.fcsv.pendingFiles;
    files:` sv/:dir,/:files;
    files:files except `$.fcsv.parsedFiles,.fcsv.pendingFiles;
    .log.debug[`fCsv] "  --Found #files:", string count files;
    :`ok`corrupted!(files;corrupted);
    };

/------------------------------------------------------------------------------/
/F/ archive parsed files in directories archive and corrupted, 
/F/ create directories if they are not existing
/E/ dir/archive/`month$(.z.d)
/E/ dir/corrupted/`month$(.z.d)
/E/ files:files`ok
/E/ fileType:`archive
/E/ dir:`:test/tmp/universe
/E/ archiveDir:`$string`month$.z.d
/E/ archiveDir:`
// files:pp 0;fileType:pp 1;dir:pp 2
.fcsv.p.storeFiles:{[files;fileType;dir;archiveDir]
    // if file type is pending and it's taken already from pending directory, then do nothing
    if[(`pending~fileType) and dir like "*pending*";:()];
    dirName:last` vs dir;
    // if files are taken from pending directory, cut pending from the directory path
    dirSrc:$[dir like "*pending*";
            first` vs  first` vs dir;
            first ` vs dir
            ];
    dest:` sv dirSrc, fileType, dirName,archiveDir;
    .log.info[`fCsv] "Move to ", string[fileType], " #files:", string[count files], " to directory: ", string dest;
    if[()~key dest;
        .fcsv.p.createDir[dest];
        ];
    .fcsv.p.moveFile[;dest] each files;
    };

/------------------------------------------------------------------------------/
/F/ create directory for w*,s*,l*
/E/ dest:`:test/tmp/universe/archive/2011.10
.fcsv.p.createDir:{[dest]
    if["w"~first string .z.o;
          cmd:"mkdir ", ssr[1_string dest;"/";"\\"];
          .log.debug[`fCsv] "Call command ", cmd;
          system cmd;
          ];
    if[first[ string .z.o] in "sl";
        cmd:"mkdir -p ", 1_string dest;
        .log.debug[`fCsv] "Call command ", cmd;
        system cmd;
        ];
    };

/------------------------------------------------------------------------------/
/F/ files moving for w*,s*,l*
/E/dest:`:test/tmp/universe/archive
.fcsv.p.moveFile:{[file;dest]
    if["w"~first string .z.o;
          mv:(1_string file), " ", 1_string dest;
          cmd:"move /Y ", ssr[mv;"/";"\\"];
          .log.debug[`fCsv] "Call command ", cmd;
          system cmd;
          ];
    if[first[ string .z.o] in "sl";
        cmd:"mv ",(1_string file), " ", 1_string dest;
        .log.debug[`fCsv] "Call command ", cmd;
        system cmd;
        ];
    };

/------------------------------------------------------------------------------/
/F/ parsing data using (format;enlist separator) 0:file
.fcsv.p.parse:{[file;format;separator]
    d:(format;separator) 0:file;
    .log.debug[`fCsv] "Read #data:", string count d;
    :d;
    };
.fcsv.p.simpleDataTypes:.cr.p.simpleDataTypes;
.fcsv.p.simpleDataTypes[`CHAR]:`$"*";
.fcsv.p.simpleDataTypes[`SYMBOL]:`$"S";

/------------------------------------------------------------------------------/
/F/ parse, enrich and validate read data
/F/ - call enrich plugin .fcsv.plug.enrich[destTab;d;file]
/F/ - call validate plugin .fcsv.plug.validate[destTab;d;file]
//files0:.fcsv.p.find'[configTable`dirSrc;configTable`pattern];
//configTable:update ii:i from configTable,'files0;
//toRead:select from configTable where (0<count'[ok]),(not ok~'`);
//file:first files:(toRead`ok) 6;config: toRead 6;
// files:raze (toRead`ok)

//config:first .fcsv.cfg.files
.fcsv.p.read2:{[file;config]
    format:config`fileFormat;separator:config`separator;destTab:config`destTab;headerInFile:config`headerInFile;file2Tab:config`file2Tab;fileModel:config`fileModel;
    .log.info[`fCsv]"Read file: ", string[file],", table: ", string[destTab];
    raw0:separator vs/: read0 file;
    $[headerInFile;
            [header:(`$first raw0); raw:flip header!flip 1_raw0];
            [header:`$"col",/:string 1+til count first raw0; raw:flip header!flip raw0]
            ];
    // take columns names and order from model
    if[0~count file2Tab;
        if[not count[cols .fcsv.cfg.models[destTab]]~count[header];'"Columns are not matching the model. Please specify file2Tab and fileModel fields in dataflow.cfg"];
        columnsOrder:cols[.fcsv.cfg.models[destTab]]!header];
    if[0<count file2Tab;columnsOrder: file2Tab[`col1]!file2Tab[`col2]];
    // take info how to parse columns
    if[0~count fileModel;columnType:upper exec t from 0!meta .fcsv.cfg.models[destTab]];
    if[0<count fileModel;columnType:raze string .fcsv.p.simpleDataTypes (fileModel[`col1]!fileModel[`col2])[value columnsOrder] ];
    columnType:ssr[columnType;" ";"*"];
    // take info how to parse columns
    excpetedCols:?[raw;();0b;columnsOrder];
    d:flip key[columnsOrder]!columnType$value flip excpetedCols;
    .log.debug[`fCsv] "Read #data:", string count d;
    d:.fcsv.plug.enrich[destTab;d;file];
    .fcsv.plug.validate[destTab;d;file]; 
    :d;
    };

.fcsv.p.read:{[file;format;separator;destTab]
    .log.info[`fCsv]"Read file: ", string[file],", table: ", string[destTab];
    d:.fcsv.p.parse[file;format;separator];
    .log.debug[`fCsv]"Parse #data:", string[count d];
    d:.fcsv.plug.enrich[destTab;d;file];
    .fcsv.plug.validate[destTab;d;file]; 
    :d;
   };
   
    

/------------------------------------------------------------------------------/
/F/ data publishing to .fcsv.connName
/E/ func:`.tp.pubImg
/E/ table:`universe
/E/ data:(1 2;1 2; 3 4)
.fcsv.p.pub:{[func;table;data]
    .log.info[`fCsv]"Publishing data #count: ", string[count first data],", func: ",string[func], ", table: ", string[table];
    .hnd.h[.fcsv.connName](func;table;data);
    };

/------------------------------------------------------------------------------/
/F/ setup function that is managing parsed files
/P/ config - dictionary with flag config`filesMoving (01b)
.fcsv.p.setupFilesMoving:{[config]
    if[config`filesMoving;
        .fcsv.p.archiveFiles:.fcsv.p.moveFiles;
        .fcsv.p.processPending:.fcsv.p.movePendingFiles;
        :();
        ];
    
    if[count key config`parsedFiles;.fcsv.parsedFiles:read0 config`parsedFiles];
    if[`pendingFiles in key config;
        if[count key config`pendingFiles;.fcsv.pendingFiles:read0 config`pendingFiles];
        ];
    .fcsv.p.archiveFiles:.fcsv.p.updateParsedFiles;
    .fcsv.p.processPending:.fcsv.p.updatePendingFiles;
    }; 

/------------------------------------------------------------------------------/
/F/ internal timer function that is calling .fcsv.processFiles
.fcsv.p.ts:{.fcsv.p.processFiles .fcsv.cfg.files};

/------------------------------------------------------------------------------/
/F/ initialization
/F/ - setup enrich,validate plugins
/F/ - setup timer for files processing
/F/ - open connection to server that is receiving data
/P/ config - dictionary with variables from .fcsv.cfg
/E/ config:.fcsv.cfg
/E/ .fcsv.p.init[config]
.fcsv.p.init:{[config]
  .sl.libCmd[];
  tabs:exec distinct destTab from config`files;
  // create default functions
  .fcsv.plug.enrich[tabs where not tabs in key .fcsv.plug.enrich]:{[x;y] x};
  .fcsv.plug.validate[tabs where not tabs in key .fcsv.plug.validate]:{[x;y]};
  .fcsv.p.setupFilesMoving[config];
  .log.info[`fCsv] "Set timer to ", string t:config`timer;
  .tmr.start[`.fcsv.p.ts;t;`.fcsv.ts];
  .fcsv.connName:$[99h~type config`serverDst;first key  config`serverDst; config`serverDst];
  .hnd.hopen[config`serverDst; config`timeout;`eager];
  // add callback for po, for process pending files
  .hnd.poAdd[config`serverDst;`.fcsv.p.processPending];
  };

.fcsv.p.movePendingFiles:{[]
  .log.info[`fCsv]"Start pending files processing";
  // call process files on pending dir
  configTable:update dirSrc:` sv/:((first each ` vs/:dirSrc),'(`pending,'last each ` vs/:dirSrc)) from .fcsv.cfg.files;
  .fcsv.p.processFiles[configTable];
  };

.fcsv.p.updatePendingFiles:{[]
  .log.info[`fCsv]"Start pending files processing, #files: ", string count .fcsv.pendingFiles;
  .fcsv.pendingFiles:();
  .log.debug[`fCsv] "Save pending files on disk ",string .fcsv.cfg.pendingFiles;
  .fcsv.cfg.pendingFiles 0: .fcsv.pendingFiles;
  .fcsv.p.processFiles[.fcsv.cfg.files];
  };

/==============================================================================/
.sl.main:{[flags]
  .fcsv.cfg.serverDst:   .cr.getCfgField[`THIS;`group;`cfg.serverDst];
  .fcsv.cfg.timeout:     .cr.getCfgField[`THIS;`group;`cfg.timeout];
  .fcsv.cfg.timer:       .cr.getCfgField[`THIS;`group;`cfg.timer];
  .fcsv.cfg.filesMoving: .cr.getCfgField[`THIS;`group;`cfg.filesMoving];
  .fcsv.cfg.parsedFiles: .cr.getCfgField[`THIS;`group;`cfg.parsedFiles];
  .fcsv.cfg.pendingFiles:.cr.getCfgField[`THIS;`group;`cfg.pendingFiles];
  .fcsv.cfg.files:       `destTab xcol 0!.cr.getCfgPivot[`THIS;`table`sysTable;`dirSrc`pattern`fileFormat`separator`headerInFile`file2Tab`fileModel];
  
  t:.cr.getModel[`THIS];
  .fcsv.cfg.models:t[;0]!t[;1];
  .sl.libCmd[];

  .fcsv.p.init[.fcsv.cfg];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`feedCsv;`.sl.main;`];

/------------------------------------------------------------------------------/
\
