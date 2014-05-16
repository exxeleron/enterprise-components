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
/S/ tickHF adapter library for feedCsv:
/S/ Responsible for:
/S/ - publishing data in tickHF protocol 
/S/ Note:
/S/ Parsed data is published to tickHF component using .u.upd interface function (<tickLF.q>)

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";

.sl.init[`tickHFPublisher];

/------------------------------------------------------------------------------/
/F/ parse and publish data in tickHF format
/P/ files:LIST PATH - list of files to be parsed
/P/ config:DICTIONARY - with fileFormat, destTab, separator
/R/ :DICTIONARY - with ok, corrupted and pending files: `ok`corrupted`pending!(enlist `:data/file1;enlist `:data/file2;enlist `:data/file3)
/E/ config:`fileFormat`destTab`separator!("TSD";`universe;";")
/E/ .fcsv.processData[`:data/file1`:data/file2`:data/file3;config]
//files:ff;config:cc
.fcsv.processData:{[files;config]
  //    ff::files;cc::config;
  .log.info[`HFPub] "Start processing #files:",string[count files]," for table ", string config`destTab;
  status:();
  status:status,{[f;config]
    .event.dot[`HFPub;`.fcsv.p.processOneFile;(f;config);`error;`info`debug`warn;
      "Process data from file ",string[f]]}[;config]each files;
  pendingFiles:files where status ~\: pendingStatus:`$"can't open connection to ",string[.fcsv.cfg`serverDst],", error: hop: Connection refused";
  status:status where not status ~\: pendingStatus;
  corruptedFiles:(files except pendingFiles) where (status~\:`error) or (not status~\:(::));
  okFiles:files except corruptedFiles,pendingFiles;
  :`ok`corrupted`pending!(okFiles;corruptedFiles;pendingFiles);
  };

/------------------------------------------------------------------------------/
/F/ process one file
/P/ file - file name
/P/ config - row from .fcsv.cfg.files
.fcsv.p.processOneFile:{[file;config]
  //    f::file; c::config;
  format:config`fileFormat;separator:config`separator;destTab:config`destTab;
  data:$[not format~"deprecated"; .fcsv.p.read[file;format;separator;destTab];.fcsv.p.read2[file;config]];
  if[not count data;
    '"Any data couldn't be parsed from file ",string file;
    ];
  // convert to tickPlus format - list
  data2pub:value flip data;
  // convert to tickPlus func
  status:.pe.dot[.fcsv.p.pub;(`.u.upd;destTab;data2pub);{[x] .log.warn[`LFPub]"Error during data publishing",x;`$x}];
  status
  };

