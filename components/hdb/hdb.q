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

/A/ DEVnet: Pawel Hudak
/V/ 3.0

/S/ Historical database component, loading native kdb hdb directory.
/-/ Note: Process is changing current process directory to hdb directory. It must not be changed to any other location.

/------------------------------------------------------------------------------/
/                                 libraries                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";

.sl.init[`hdb];
.sl.lib["cfgRdr/cfgRdr"];

/------------------------------------------------------------------------------/
/                              interface functions                             /
/------------------------------------------------------------------------------/
.hdb.p.reload:{[]
  system "l .";
  };

/------------------------------------------------------------------------------/
.hdb.p.fillMissingTabs:{[]
  .Q.chk[`:.];
  };

/------------------------------------------------------------------------------/
/F/ Reloads hdb directory.
/R/ no return value
/E/ .hdb.reload[]
.hdb.reload:{[]
  .event.at[`hdb;`.hdb.p.reload;();`;`info`info`fatal;"hdb reloading, hdb dir:", system"cd"];
  };
  
/------------------------------------------------------------------------------/
/F/ Fills missing tables in all hdb partitions. 
/-/ Implementation based on .Q.chk[] q native function.
/R/ no return value
/E/ .hdb.fillMissingTabs[]
.hdb.fillMissingTabs:{[]
  .event.at[`hdb;`.hdb.p.fillMissingTabs;();`;`info`info`fatal;"fill missing tables, hdb dir:", system"cd"];
  };

/------------------------------------------------------------------------------/
/F/ Check whether hdb table is loaded without errors
/P/ tab:SYMBOL - table name
/R/ SYMBOL - error msg or empty symbol
.hdb.p.checkErr:{[tab] @[{count value x;`};tab;`$] };

/------------------------------------------------------------------------------/
/F/ Check table format - one of `PARTITIONED`SPLAYED`INMEM
/P/ tab:SYMBOL - table name
/R/ SYMBOL - `PARTITIONED`SPLAYED or `INMEM
.hdb.p.format:{((1b;0b;0)!`PARTITIONED`SPLAYED`INMEM).Q.qp value x};

/------------------------------------------------------------------------------/
/F/ Total rows count of the table
/P/ tab:SYMBOL - table name
/R/ LONG - Total rows count of the table, null in case of error
.hdb.p.rowsCnt:{[tab] @[{count value x};tab;0N]};

/------------------------------------------------------------------------------/
/F/ Returns current status of all hdb tables.
/R/ Table with one row for each table available in the global namespace.
/-/ tab:SYMBOL          - table name
/-/ format:SYMBOL       - format of the table - one of PARTITIONED`SPLAYED`INMEM
/-/ rowsCnt:LONG        - total rows count of the table, null in case of error
/-/ err:SYMBOL          - error in case table wasn't loaded properly
/-/ columns:SYMBOL LIST - list of columns in the table
/E/ .hdb.status[]
.hdb.status:{[]update format:.hdb.p.format'[tab], rowsCnt:.hdb.p.rowsCnt'[tab], err:.hdb.p.checkErr'[tab], columns:cols'[tab] from ([]tab:tables[])}

/------------------------------------------------------------------------------/
/F/ Returns status of all partitioned tables in the hdb
/R/ Table with one row for each partition, and with one dedicated column for each table.
/-/  -- date:DATE           - partition 
/-/  -- parDir:SYMBOL       - partition directory
/-/  -- [tabName]:LONG      - Count of the table within the partition. One column for each partitioned table.
/E/ .hdb.statusByPar[]
.hdb.statusByPar:{[]
  if[not `pf in key `.Q;:([]parDir:`symbol$())];
  flip {$[count[x];x;0N]}each((.Q.pf;`parDir)!(.Q.PV;.Q.PD)),.Q.pn
  };

/------------------------------------------------------------------------------/
/F/ Retrieves statistics about the data volumes in hdb. Statistics are based on hourly aggregation. 
/-/ - If there is a "time" column, it will be used for the aggregation.
/-/ - If there is no "time" column in the table, then the statistics will be calculated per whole day (not per hour).
/P/ tab:SYMBOL - name of the table in hdb for requested statistics
/P/ day:DATE - date for requested statistics
/R/ Table with content statistics.
/-/  -- hdbDate:DATE            - hdb date for which the statistics are calculated
/-/  -- hour:TIME               - hdb hour for which the statistics are calculated, or null value in case there was no "time" column in the table
/-/  -- table:SYMBOL            - table name
/-/  -- totalRowsCnt:LONG       - number of rows within an hour (or in the whole day if there was no "time" column)
/-/  -- minRowsPerSec:LONG      - minimal of [number of rows per second] within an hour (or in the whole day if there was no "time" column)
/-/  -- avgRowsPerSec:LONG      - average of [number of rows per second] within an hour (or in the whole day if there was no "time" column)
/-/  -- medRowsPerSec:LONG      - median of [number of rows per second] within an hour (or in the whole day if there was no "time" column)
/-/  -- maxRowsPerSec:LONG      - maximum of [number of rows per second] within an hour (or in the whole day if there was no "time" column)
/-/  -- dailyMedRowsPerSec:LONG - number of rows within an hour (or in the whole day if there was no "time" column)
/E/ .hdb.dataVolumeHourly[`trade;2015.02.01]
.hdb.dataVolumeHourly:{[tab;day]
  if[not -11h=type tab;
    '"invalid tab type (",.Q.s1[type tab],"), should be SYMBOL type (-11h)";
    ];
  if[not -14h=type day;
    '"invalid day type (",.Q.s1[type day],"), should be DATE type (-14h)";
    ];
  chunkSize:5000000j;
  if[`time in cols[tab]; // hourly statistics
    //day of data will be divided into number of chunks with size up to 5mio rows
    chunks:ceiling (exec first cnt from select cnt:count i from tab where date=day)%chunkSize;
    //statistics calculated for each chunk independly -> in order to limit mem usage
    res0:{[tab;day;chunkSize;x]`time xkey select cnt:`long$count i by time:`time$time.second from tab where date=day, i within (x*chunkSize)+(0;chunkSize-1)}[tab;day;chunkSize]each til chunks;
    if[0=count res0;res0:enlist ([time:`time$()]cnt:`long$())];
    //aggregation of statistics from chunks
    res1:1!`time xasc (asc distinct raze key each res0) pj/ res0;
    res2:`time xasc ([]time:`time$1000*til 60*60*24; hdbDate:day)lj res1;
    dailyMed:`long$first exec med cnt from res2;
    :`hdbDate`hour`table xcols 0!select table:tab,
    totalRowsCnt:`long$sum cnt, minRowsPerSec:`long$min cnt, avgRowsPerSec:`long$avg cnt, medRowsPerSec:`long$med cnt, maxRowsPerSec:`long$max cnt, dailyMedRowsPerSec:dailyMed
    by hdbDate, hour:`time$`minute$60*time.hh from res2;
    ];
  //daily statistics
  cnt:count ?[tab;enlist(=;`date;day);0b;(enlist `x)!enlist `i]; // select from tab where date=day
  : `hdbDate`hour`table xcols ([] table:enlist tab; totalRowsCnt:enlist `long$cnt; minRowsPerSec:enlist 0Nj; avgRowsPerSec:enlist 0Nj; medRowsPerSec:enlist 0Nj; maxRowsPerSec:enlist 0Nj; hdbDate:enlist day; hour:enlist 0Nt; dailyMedRowsPerSec:enlist 0Nj);
  };

/------------------------------------------------------------------------------/
/F/ initialization and reload
.hdb.p.init:{[]
  system "cd ",1_string .hdb.cfg.hdbPath;
  .hdb.reload[];
  };

/==============================================================================/
/F/ Main function for the hdb component.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main `
.sl.main:{[flags]
  /G/ Path to the actual hdb directory.
  .hdb.cfg.hdbPath:.cr.getCfgField[`THIS;`group;`cfg.hdbPath];

  .sl.libCmd[];

  .hdb.p.init[];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`hdb;`.sl.main;`];

/------------------------------------------------------------------------------/
\
