/L/ Copyright (c) 2011-2015 Exxeleron GmbH
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
/S/ qsl/tabs - data model validation toolkit

//----------------------------------------------------------------------------//
/G/ Configuration map containing mapping between symbolic type name and type-letter.
/-/ Reversed .tabs.cfg.typeMap2.
.tabs.cfg.typeMap:exec c!t from meta flip enlist each .cr.atomic.nulls;

/G/ Configuration map containing mapping between type-letter and symbolic type name. 
/-/ Reversed .tabs.cfg.typeMap.
.tabs.cfg.typeMap2:string exec t!c from meta flip enlist each .cr.atomic.nulls;

//----------------------------------------------------------------------------//
/F/ Validates the data model. Thows signal or returns validated TABLE. (Input in form of list of columns is automatically converted to table form)
/P/ expected:TABLE | meta[TABLE] - expected data model in one of the following formats:
/-/    as meta, e.g.: meta`trade
/-/    as cfg mode, e.g.: exec first finalValue from .cr.getCfgTab[`THIS;`table`sysTable;`model]
/P/ table:TABLE | LIST - actual data that should be validate in terms of data model
/R/ :TABLE - if everything is OK returns table.
/-/    If the input was vaild and was if form of list of columns, then the result is anyway in a table format.
/-/    In case of invalid data model - signals with the description of identified issue, including complete expected data model table 
/E/ .tabs.validate[([]price:`float$(); size:`long$()); ([]price:11.1 11.2 11.2; size:100 100 200)]
/-/     - input as: .tabs.validate[empsty table; table]
/-/     - model is valid 
/-/     - returns  ([]price:11.1 11.2 11.2; size:100 100 200)  (=table argument)
/E/ .tabs.validate[([]price:`float$(); size:`long$()); (11.1 11.2 11.2;100 100 200)]
/-/     - input as: .tabs.validate[empsty table; table]
/-/     - detects missing column, throws signal as following:
/-/       model: col1 "size(LONG)" is missing, expected model - price(FLOAT),size(LONG) 
/E/ .tabs.validate[([]price:`float$()); (11.1 11.2 11.2;100 100 200)]
/-/     - input as: .tabs.validate[empsty table; table]
/-/     - detects missing column, throws signal as following:
/-/       model: col1 "col1(LONG)" is unexpected, expected model - price(FLOAT)
/E/ .tabs.validate[([]price:`float$(); size:`long$()); ([]price:11.1 11.2 11.2; size:`100`100`200)]
/-/     - input as: .tabs.validate[empsty table; table]
/-/     - detects invalid column type, throws signal as following:
/-/       model: col1 "size(SYMBOL)" should be "size(LONG)", expected model - price(FLOAT),size(LONG)
.tabs.validate:{[expected;table]
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
/F/ Returns status of all the tables in the given namespaces.
/P/ namespaces:LIST[SYMBOL] - list of namespaces
/R/ :TABLE - status of all tables in given namespaces:
/-/  -- ns:SYMBOL            - namespace in which the table is defined
/-/  -- tab:SYMBOL           - table name
/-/  -- format:SYMBOL        - format of the table, one of `PARTITIONED`SPLAYED`INMEM
/-/  -- rowsCnt:SYMBOL       - number of rows currently available
/-/  -- err:SYMBOL           - error connected with the table, e.g. missing partition in case of PARTITIONED table
/-/  -- columns:LIST[SYMBOL] - 
/E/ .tabs.status `.
/-/     - display status of all tables which exists in the top level namespace
/E/ .tabs.status `.,` sv/: `,/:key`
/-/     - display status of all tables in all namespaces with single nesting level
.tabs.status:{[namespaces]
  tabs:raze {([]ns:x;tab:$[x~`.;tables x;` sv/: x,/:tables[x]])} each (),namespaces;
  update format:.tabs.p.format'[tab], rowsCnt:.tabs.p.rowsCnt'[tab], err:.tabs.p.checkErr'[tab], columns:cols'[tab] from tabs
  };

//----------------------------------------------------------------------------//
//                          private functions                                 //
//----------------------------------------------------------------------------//
/F/ Prints model in a form of human-friendly string.
/P/ model:DICT[SYMBOL;CHAR] - column->type letter, format returned by .mode.p.meta[]
/R/ :STRING - human-friendly model representation
.tabs.p.modelToStr:{[model]
  ","sv string[key model],'"(",'value[.tabs.cfg.typeMap2 model],\:")"
  };

//----------------------------------------------------------------------------//
/F/ Creates dictionary column->type letter of the actual table
/P/ tab:TABLE - actual table
/R/ DICT[SYMBOL;CHAR] - column->type letter
/E/ .mode.p.meta trade
.mode.p.meta:{[tab]
  .Q.ty each flip tab
  };

//----------------------------------------------------------------------------//
/F/ Checks if the table can be accessed without any errors.
/P/ tab:SYMBOL - table name
/R/ SYMBOL - error message, or empty backtick (`) if no error detected
/E/ .mode.p.meta `trade
.tabs.p.checkErr:{[tab] 
  @[{count value x;`};tab;`$] 
  };

//----------------------------------------------------------------------------//
/F/ Detects table format.
/P/ tab:SYMBOL - table name
/R/ SYMBOL - one of `PARTITIONED`SPLAYED`INMEM
/E/ .mode.p.format `trade
.tabs.p.format:{[tab] 
  ((1b;0b;0)!`PARTITIONED`SPLAYED`INMEM).Q.qp value tab
  };

//----------------------------------------------------------------------------//
/F/ Calculates rows in the table.
/P/ tab:SYMBOL - table name
/R/ LONG - number of records in the table
/E/ .mode.p.rowsCnt `trade
.tabs.p.rowsCnt:{[tab] 
  @[{count value x};tab;0N]
  };

//----------------------------------------------------------------------------//
/
