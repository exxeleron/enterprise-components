/L/ Copyright (c) 2011-2015 Exxeleron GmbH
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
/S/ qsl/tabs - data model validation toolkit

//----------------------------------------------------------------------------//
.tabs.cfg.typeMap:exec c!t from meta flip enlist each .cr.atomic.nulls;
.tabs.cfg.typeMap2:string exec t!c from meta flip enlist each .cr.atomic.nulls;

//----------------------------------------------------------------------------//
/S/ Validate the data model
/P/ expected - expected data model in one of the following formats:
/P/    as meta, e.g.: meta`trade
/P/    as cfg mode, e.g.: exec first finalValue from .cr.getCfgTab[`THIS;`table`sysTable;`model]
/P/ table - actual data that should be validate in terms of data model
/R/ - signal with the description of identified issue, including complete expected data model
/R/ table - if everything is OK
.tabs.validate:{[expected;table]
//  `expected set expected;`table set table;
  if[not type[expected] in 98 99h;
    '"expceted should be of type 98h"
    ];
  if[not type[table] in 0 98h;
    '"table should be of type 98h or 0h"
    ];
  if[type[table]=0h; //support for list of columns
    columns:cols[expected];
    receivedCnt:count[table];
    extraCnt:receivedCnt-count[columns];
    columns:$[extraCnt=0;columns;
      extraCnt>0;columns,`$"col",/:string count[columns]+til extraCnt;
      extraCnt _ columns];
    table:flip columns!table;
    ];

  dm:.mode.p.meta[table];
  em:$[type[expected]=98j;.mode.p.meta[expected];expected];
  if[em~dm;:table];

  cnt:min[count[em],count[dm]];
  if[count ids:where not (cnt#key[dm])=cnt#key[em];
    id:first ids;
    '"model: col",string[id]," \"",string[key[dm][id]],"(",.tabs.cfg.typeMap2[value[dm][id]],")\" should be \"",string[key[em][id]],"(",.tabs.cfg.typeMap2[value[em][id]],")\", expected model - ", .tabs.p.modelToStr em
    ];
  if[count ids:where not (cnt#value[dm])=cnt#value[em];
    id:first ids;
    '"model: col",string[id]," \"",string[key[dm][id]],"(",.tabs.cfg.typeMap2[value[dm][id]],")\" should be \"",string[key[em][id]],"(",.tabs.cfg.typeMap2[value[em][id]],")\", expected model - ", .tabs.p.modelToStr em
    ];
  if[cnt<count[dm];
    '"model: col",string[cnt]," \"",string[key[dm][cnt]],"(",.tabs.cfg.typeMap2[value[dm][cnt]],")\" is unexpected, expected model - ", .tabs.p.modelToStr em
    ];
  if[cnt<count[em];
    '"model: col",string[cnt]," \"",string[key[em][cnt]],"(",.tabs.cfg.typeMap2[value[em][cnt]],")\" is missing, expected model - ", .tabs.p.modelToStr em
    ];
  '"model: model does not match, unknown difference"
  };

//----------------------------------------------------------------------------//
.tabs.p.modelToStr:{[model]
  ","sv string[key model],'"(",'value[.tabs.cfg.typeMap2 model],\:")"
  };

//----------------------------------------------------------------------------//
.mode.p.meta:{[tab]
  .Q.ty each flip tab
  };

//----------------------------------------------------------------------------//
//                             tables status                                  //
//----------------------------------------------------------------------------//
/F/ get status of the table
//.tabs.status namespaces:`.,` sv/: `,/:key`
.tabs.status:{[namespaces]
  tabs:raze {([]ns:x;tab:$[x~`.;tables x;` sv/: x,/:tables[x]])} each (),namespaces;
  update format:.tabs.p.format'[tab], rowsCnt:.tabs.p.rowsCnt'[tab], err:.tabs.p.checkErr'[tab], columns:cols'[tab] from tabs
 };

//----------------------------------------------------------------------------//
.tabs.p.checkErr:{[tab] @[{count value x;`};tab;`$] };
//----------------------------------------------------------------------------//
.tabs.p.format:{((1b;0b;0)!`PARITIONED`SPLAYED`INMEM).Q.qp value x};
//----------------------------------------------------------------------------//
.tabs.p.rowsCnt:{[tab] @[{count value x};tab;0N]};

//----------------------------------------------------------------------------//
/
