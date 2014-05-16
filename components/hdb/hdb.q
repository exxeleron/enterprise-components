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

/A/ DEVnet: Pawel Hudak
/V/ 3.0
/S/ Historical database component:
/S/ Responsible for:
/S/ - loading native kdb hdb directory
/S/ Note: 
/S/ - Process is changing current process directory to hdb directory. It must not be changed to any other location.
/T/ q hdb.q

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

.hdb.p.fillMissingTabs:{[]
  .Q.chk[`:.];
  };

/F/ reload hdb directory
.hdb.reload:{[]
  .event.at[`hdb;`.hdb.p.reload;();`;`info`info`fatal;"hdb reloading, hdb dir:", system"cd"];
  };
  
/F/ fill missing tables in partitions
.hdb.fillMissingTabs:{[]
  .event.at[`hdb;`.hdb.p.fillMissingTabs;();`;`info`info`fatal;"fill missing tables, hdb dir:", system"cd"];
  };

/F/ Check whether hdb table is loaded without errors
/P/ tab:SYMBOL - table name
/R/ SYMBOL - error msg or empty symbol
.hdb.p.checkErr:{[tab] @[{count value x;`};tab;`$] };

/F/ Check table format - one of `PARITIONED`SPLAYED`INMEM
/P/ tab:SYMBOL - table name
/R/ SYMBOL - `PARITIONED`SPLAYED or `INMEM
.hdb.p.format:{((1b;0b;0)!`PARITIONED`SPLAYED`INMEM).Q.qp value x};

/F/ Total rows count of the table
/P/ tab:SYMBOL - table name
/R/ LONG - Total rows count of the table, null in case of error
.hdb.p.rowsCnt:{[tab] @[{count value x};tab;0N]};

/F/ Status of all hdb tables
/R/ table with following columns:
/R/ (start code)
/R/ tab:SYMBOL          - table name
/R/ format:SYMBOL       - format of the table - one of PARITIONED`SPLAYED`INMEM
/R/ rowsCnt:LONG        - total rows count of the table, null in case of error
/R/ err:SYMBOL          - error in case table wasn't loaded properly
/R/ columns:SYMBOL LIST - list of columns in the table
/R/ (end)
/E/ .hdb.status[]
.hdb.status:{[]update format:.hdb.p.format'[tab], rowsCnt:.hdb.p.rowsCnt'[tab], err:.hdb.p.checkErr'[tab], columns:cols'[tab] from ([]tab:tables[])}

/F/ Status of all partitioned tables in the hdb
/R/ table with following columns:
/R/ (start code)
/R/ date:DATE           - partition 
/R/ parDir:SYMBOL       - partition directory
/R/ [tabName]:LONG      - Count of the table within the partition. One column for each partitioned table.
/R/ (end)
/E/ .hdb.statusByPar[]
.hdb.statusByPar:{[]flip {$[count[x];x;0N]}each((.Q.pf;`parDir)!(.Q.PV;.Q.PD)),.Q.pn};

/F/ Retrieve statistics about the data volumes in hdb. Statistics are based on hourly aggregation. Please note that
/F/ - If there is a "time" column, it will be used for the aggregation.
/F/ - If there is no "time" column in the table, then the statistics will be calculated per whole day (not per hour).
/P/ tab:SYMBOL - name of the table in hdb for requested statistics
/P/ day:DATE - date for requested statistics
/R/ table with following columns:
/R/ (start code)
/R/ hdbDate:DATE            - hdb date for which the statistics are calculated
/R/ hour:TIME               - hdb hour for which the statistics are calculated, or null value in case there was no "time" column in the table
/R/ table:SYMBOL            - table name
/R/ totalRowsCnt:LONG       - number of rows within an hour (or in the whole day if there was no "time" column)
/R/ minRowsPerSec:LONG      - minimal of [number of rows per second] within an hour (or in the whole day if there was no "time" column)
/R/ avgRowsPerSec:LONG      - average of [number of rows per second] within an hour (or in the whole day if there was no "time" column)
/R/ medRowsPerSec:LONG      - median of [number of rows per second] within an hour (or in the whole day if there was no "time" column)
/R/ maxRowsPerSec:LONG      - maximum of [number of rows per second] within an hour (or in the whole day if there was no "time" column)
/R/ dailyMedRowsPerSec:LONG - number of rows within an hour (or in the whole day if there was no "time" column)
/R/ (end)
.hdb.dataVolumeHourly:{[tab;day]
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
.sl.main:{[flags]

  .hdb.cfg.hdbPath:.cr.getCfgField[`THIS;`group;`cfg.hdbPath];

  .sl.libCmd[];

  .hdb.p.init[];
  };

/------------------------------------------------------------------------------/
//initialization
.sl.run[`hdb;`.sl.main;`];

/------------------------------------------------------------------------------/
\
