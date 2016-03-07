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

/A/ DEVnet: Joanna Jarmulska
/V/ 3.0

/S/ Csv feed component:
/-/ Responsible for:
/-/ - providing fully customizable and configurable CSV file parser
/-/ - enabling automatic detection of CSV input files in specified locations, matching predefined pattern of the file names
/-/ - shielding system from corrupted data sets
/-/ - publishing parsed files to the TickerPlant in tickLF (<tickLF.q>) or tickHF (<tickHF.q>) protocol
/-/ - archiving processed files (optionally)
/-/ - parsing pending files - helpful when destination server is inactive and parsed files are marked as pending; in this case reconnecting procedure will try to establish new connection - after it's done pending files will be automatically processed
/-/ Note:
/-/ Depending on which component is triggered (*<.tickLF.pubUpd>* or *<.tickLF.pubImg>*), each file name should be preceded by either *upd* or *img* respectively. For example: YYYY.DD.MM.*upd*.table.csv, YYYY.DD.MM.*img*.table.csv.
/-/ Defining custom plugins:
/-/ Signature for plugin for data enrichment, returns TABLE
/-/ (start code)
/-/ .fcsv.plug.enrich[table(SYMBOL)][data(TABLE);fileName(SYMBOL)]
/-/ (end)
/-/ Example
/-/ (start code)
/-/ .fcsv.plug.enrich[`universe]:{[data;file] update time:file from data}
/-/ (end)
/-/ Signature for plugin for data validation, returns signal in case of failed validation
/-/ (start code)
/-/ .fcsv.plug.validate[tableName(SYMBOL)][data(TABLE);fileName(SYMBOL)]
/-/ (end)
/-/ Example
/-/ (start code)
/-/ .fcsv.plug.validate[`universe]:{[data;file] if[not meta[data]~meta universe;'failed]}
/-/ (end)
/-/
/-/ FeedCsv library doesn't contain any default protocol to publish parsed files, therefore feedCsv component should be started using following modes
/-/ - mode compatible with *tickLF* protocol
/-/ (start code)
/-/ q feedCsv.q -lib tickLFPublisher.q -p 5001
/-/ (end)
/-/ - mode compatible with *tickHF* protocol
/-/ (start code)
/-/ q feedCsv.q -lib tickHFPublisher.q -p 5001
/-/ (end)
/-/ - example of startup command with *plugins*
/-/ (start code)
/-/ q feedCsv.q -lib tickHFPublisher.q plugins/feedCsvPlugin.q -p 5001
/-/ (end)

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`feedCsv];

/------------------------------------------------------------------------------/
.sl.lib["cfgRdr/cfgRdr"];
.sl.lib["qsl/handle"];
.sl.lib["qsl/timer"];

/------------------------------------------------------------------------------/
/G/ Dictionary with data enrichment plugins.
.fcsv.plug.enrich:()!();

/G/ Dictionary with data validation plugins.
.fcsv.plug.validate:()!();

/G/ List of parsed files (used if cfg.filesMoving:0b).
.fcsv.parsedFiles:();

/G/ List of pending files (used if cfg.filesMoving:0b).
.fcsv.pendingFiles:();

/------------------------------------------------------------------------------/
/F/ Main function for files processing that is called on timer.
/-/  - files searching
/-/  - call .fcsv.processData
/-/  - files archiving
/P/ configTable:TABLE - configuration from .fcsv.cfg.files
/-/    -- dir:SYMBOL        - full path to the input directory
/-/    -- pattern:STRING    - like-style regular expression to find files in the input dir
/-/    -- destTab:SYMBOL    - destination table name
/-/    -- fileFormat:STRING - file format in form of type-letters
/-/    -- separator:CHAR    - fields separator
/E/ .fcsv.p.processFiles .fcsv.cfg.files
/E/ .fcsv.p.processFiles  ([] dir:`:test/tmp/universe`:test/tmp/underlying; pattern:("*universe";"*underlying");
/-/     destTab:`universe`underlying; fileFormat:("TSD"; "TSS");separator:(";"));
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
/F/ Moves files to archive, corrupted directories.
/E/ .fcsv.p.moveFiles (toRead;corrupted)
.fcsv.p.moveFiles:{[info]
    {[dir;f].pe.dotLog[`fCsv;`.fcsv.p.storeFiles;(f;`archive;dir;`$string`month$.sl.zd[]);();`warn]}./:
        flip value flip ungroup select dirSrc,ok from info[0] where (0<count'[ok]),(not ok~'`);
    {[dir;f].pe.dotLog[`fCsv;`.fcsv.p.storeFiles;(f;`corrupted;dir;`$string`month$.sl.zd[]);();`warn]}./:
        flip value flip ungroup select dirSrc,corrupted from info[1] where (0<count'[corrupted]),(not corrupted~'`);
    {[dir;f].pe.dotLog[`fCsv;`.fcsv.p.storeFiles;(f;`pending;dir;`);();`warn]}./:
        flip value flip ungroup select  dirSrc,pending from info[1] where (0<count'[pending]),(not pending~'`);
    };

/------------------------------------------------------------------------------/
/F/ Updates txt file (.fcsv.cfg.parsedFiles) with parsed files.
/E/ .fcsv.p.updateParsedFiles (toRead;corrupted)
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
/F/ Finds files in the directory matching given pattern
/E/ .fcsv.p.find[`:test/tmp/underlying;"*underlying"]
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
/F/ Archives parsed files in directories archive and corrupted, create directories if they are not existing.
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
/F/ Creates directory for w*,s*,l*.
/E/ .fcsv.p.createDir `:test/tmp/universe/archive/2011.10
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
/F/ Moves files.
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
/F/ Parses data using (format;enlist separator) 0:file.
.fcsv.p.parse:{[file;format;separator]
    d:(format;separator) 0:file;
    .log.debug[`fCsv] "Read #data:", string count d;
    :d;
    };
.fcsv.p.simpleDataTypes:.cr.p.simpleDataTypes;
.fcsv.p.simpleDataTypes[`CHAR]:`$"*";
.fcsv.p.simpleDataTypes[`SYMBOL]:`$"S";

/------------------------------------------------------------------------------/
/F/ Parses, enriches and validates the data
/-/  - call enrich plugin .fcsv.plug.enrich[destTab;d;file]
/-/  - call validate plugin .fcsv.plug.validate[destTab;d;file]
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
/F/ Publishes data to .fcsv.connName.
/E/ .fcsv.p.pub[`.tp.pubImg;`universe;(1 2;1 2; 3 4)]
.fcsv.p.pub:{[func;table;data]
    .log.info[`fCsv]"Publishing data #count: ", string[count first data],", func: ",string[func], ", table: ", string[table];
    .hnd.h[.fcsv.connName](func;table;data);
    };

/------------------------------------------------------------------------------/
/F/ Setups function that is managing parsed files.
/P/ config:DICT - dictionary with flag config`filesMoving (01b)
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
/F/ Internal timer function that is calling .fcsv.processFiles.
.fcsv.p.ts:{.fcsv.p.processFiles .fcsv.cfg.files};

/------------------------------------------------------------------------------/
/F/ FeedCsv initialization.
/-/ - setup enrich,validate plugins
/-/ - setup timer for files processing
/-/ - open connection to server that is receiving data
/P/ config:DICT - dictionary with variables from .fcsv.cfg
/E/ .fcsv.p.init .fcsv.cfg
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
/F/ Component initialization entry point.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]  
  /G/ Destination server name, loaded from cfg.serverDst field from system.cfg.
  .fcsv.cfg.serverDst:   .cr.getCfgField[`THIS;`group;`cfg.serverDst];
  /G/ Connection opening timeout, loaded from cfg.timeout field from system.cfg.
  .fcsv.cfg.timeout:     .cr.getCfgField[`THIS;`group;`cfg.timeout];
  /G/ New files searching timer frequency, loaded from cfg.timer field from system.cfg.
  .fcsv.cfg.timer:       .cr.getCfgField[`THIS;`group;`cfg.timer];
  /G/ Flag for files archiving, files can be either moved to archive directory or marked as parsed in cfg.parsedFiles.
  /-/ Loaded from cfg.parsedFiles field from system.cfg
  .fcsv.cfg.filesMoving: .cr.getCfgField[`THIS;`group;`cfg.filesMoving];
  /G/ Location of txt file with parsed file, loaded from cfg.parsedFiles field from system.cfg
  .fcsv.cfg.parsedFiles: .cr.getCfgField[`THIS;`group;`cfg.parsedFiles];
  /G/ Location of txt file with pending file, loaded from cfg.parsedFiles field from system.cfg
  .fcsv.cfg.pendingFiles:.cr.getCfgField[`THIS;`group;`cfg.pendingFiles];
  /G/ Table with csv loading configuration, based on dataflow.cfg
  /-/  -- table:SYMBOL         - table name
  /-/  -- dirSrc:SYMBOL        - full path to the input directory
  /-/  -- pattern:STRING       - like-style regular expression to find files in the input dir
  /-/  -- fileFormat:STRING    - file format in form of type-letters
  /-/  -- separator:CHAR       - fields separator
  /-/  -- headerInFile:BOOLEAN - flag to indicate if csv file contains header
  /-/  -- file2tab:BOOLEAN     - mapping for columns in data model and csv file as list of pairs
  /-/                          column name from data model and column from csv file, if default is used, then order is taken from csv file as it is
  /-/  -- fileModel:BOOLEAN    - format definition of file as list of pairs: column name and format; 
  /-/                          if default is used, then order is taken from csv file as it is
  .fcsv.cfg.files:       `destTab xcol 0!.cr.getCfgPivot[`THIS;`table`sysTable;`dirSrc`pattern`fileFormat`separator`headerInFile`file2Tab`fileModel];
  
  t:.cr.getModel[`THIS];

  /G/ Dictionary with data model (tabName -> model)
  .fcsv.cfg.models:t[;0]!t[;1];
  .sl.libCmd[];

  .fcsv.p.init[.fcsv.cfg];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`feedCsv;`.sl.main;`];

/------------------------------------------------------------------------------/
\
