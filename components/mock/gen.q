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

/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";

/------------------------------------------------------------------------------/
.sl.init[`gen];
.sl.lib[`$"qsl/handle"];
.sl.lib["cfgRdr/cfgRdr"];

/------------------------------------------------------------------------------/
/                             data generators                                  /
/------------------------------------------------------------------------------/
/G/ DICTIONARY(TYPE SYMBOL;FUNCTION) - Set of data generators, one for each type.
/-/ All of them take one parameter (number of requested elements)
.gen.generate:()!();
.gen.generate[`BOOLEAN]:{`boolean$x?2};
.gen.generate[`GUID]:?[;0Ng];
.gen.generate[`BYTE]:?[;0xFF];
.gen.generate[`SHORT]:?[;100h];
.gen.generate[`INT]:?[;1000i];
.gen.generate[`LONG]:?[;100j];
.gen.generate[`REAL]:?[;100e];
.gen.generate[`FLOAT]:?[;100f];
.gen.generate[`CHAR]:?[;.Q.A];
.gen.generate[`STRING]:{{5?.Q.A}each til x};
.gen.generate[`SYMBOL]:{x?.gen.uni};
.gen.generate[`TIMESTAMP]:?[;.z.p]; 
.gen.generate[`MONTH]:?[;`month$.z.d];
.gen.generate[`DATE]:?[;.z.d];
.gen.generate[`DATETIME]:?[;.z.z];
.gen.generate[`TIMESPAN]:?[;.z.n];
.gen.generate[`MINUTE]:?[;`minute$.z.t];
.gen.generate[`SECOND]:?[;`second$.z.t];
.gen.generate[`TIME]:{x#.z.t};

/------------------------------------------------------------------------------/
/                             publishing                                       /
/------------------------------------------------------------------------------/
/F/ Initializes the data generator.
/-/  - generation of the universe
/-/  - initialization of tables generators - each generator is stored under the name of table that it is generating
/-/  - loading of custom code
/-/  - initialization of the connection to destination server
/R/ no return value
/E/ .gen.init[]
.gen.init:{[]
  /G/ List of dummy instruments published via the generator.
  .gen.uni:`$"instr",/: string til .gen.cfg.uniSize;

  //tables generatos
  {x set value "{[ts] .gen.pubTabTrigger[`",string[x],";ts]}"}each key .gen.cfg.models;

  //allow to replace one generator functions
  .sl.libCmd[];  

  //initialize connection to the data destination
  .hnd.poAdd[.gen.cfg.dst;`.gen.po];
  .hnd.pcAdd[.gen.cfg.dst;`.gen.pc];
  .hnd.hopen[.gen.cfg.dst;1000i;`eager];
  };

/------------------------------------------------------------------------------/
/F/ Callback for destination server "port open".
/-/  - initialization of eod timer
/-/  - detection of destination server protocol
/-/  - initialization of publishing timers - one per each table
/P/ x:INT - handle
/R/ no return value
/E/ .gen.po[12i]
.gen.po:{[x]
  /G/ Destination server protocol.
  .gen.dstProtocol:first .hnd.h[.gen.cfg.dst]".sl.getSubProtocols[]";
  if[.gen.dstProtocol~`PROTOCOL_DIST;
    .log.info[`gen]"using DIST protocol, see .gen.dist namespace";
    /G/ Function name that should be executed to publish the table, dependent on .gen.dstProtocol.
    .gen.pubTabTrigger:`.gen.dist.pubTab;
    /G/ Function name that should be executed to publish the eod, dependent on .gen.dstProtocol.
    .gen.pubEodTrigger:`.gen.dist.pubEod;
    ];
  if[.gen.dstProtocol~`PROTOCOL_TICKHF;
    .log.info[`gen]"using tickHF protocol, see .gen.tickHF namespace";
    .gen.pubTabTrigger:`.gen.tickHF.pubTab;
    .gen.pubEodTrigger:`.gen.tickHF.pubEod;
    ];
  //initialize publishing timers
  select .tmr.start'[tab;period;tab] from .gen.cfg.tabs;
  //initialize eod timer
  .tmr.runAt[.gen.cfg.eodTime;.gen.pubEodTrigger;`pubEodTrigger];
  };

/------------------------------------------------------------------------------/
/F/ Callback for destination server "port close".
/P/ x:INT - handle
/R/ no return value
/E/ .gen.pc[12i]
.gen.pc:{[x]
  select .tmr.stop'[tab] from .gen.cfg.tabs
  };

/------------------------------------------------------------------------------/
/                              PROTOCOL_TICKHF                                 /
/------------------------------------------------------------------------------/
/F/ Triggers data publishing of one package for one table to the tickHF server.
/P/ tab:SYMBOL   - table name
/P/ ts:TIMESTAMP - timestamp of the package
/R/ no return value
/E/ .gen.tickHF.pubTab[`trade;.z.p]
.gen.tickHF.pubTab:{[tab;ts]
  data:.gen.generate[.gen.cfg.models[tab][`col2]] @ \: .gen.cfg.tabs[tab][`pkgSize];
  .hnd.h[.gen.cfg.dst](`.u.upd;tab;data);
  };

/------------------------------------------------------------------------------/
/F/ Triggers eod for tickHF server.
/P/ date:DATE - eod date
/R/ no return value
/E/ .gen.tickHF.pubEod[.z.d]
.gen.tickHF.pubEod:{[date]
  .log.info[`gen] "No eod action for tickHF";
  };

/------------------------------------------------------------------------------/
/                              PROTOCOL_DIST                                   /
/------------------------------------------------------------------------------/
/F/ Triggers data publishing of one package for one table to the dist server.
/P/ tab:SYMBOL   - table name
/P/ ts:TIMESTAMP - timestamp of the package
/R/ no return value
/E/ .gen.dist.pubTab[`trade;.z.p]
.gen.dist.pubTab:{[tab;ts]
  `tab set tab;`ts set ts;
  data:.gen.generate[.gen.cfg.models[tab][`col2]] @ \: .gen.cfg.tabs[tab][`pkgSize];
  sector:first 1?.gen.cfg.tabs[tab][`sectors];
  .hnd.h[.gen.cfg.dst](`.dist.pubOne;`upd;tab;sector;data);
  };

/------------------------------------------------------------------------------/
/F/ Triggers eod for dist server for one table-sector combination.
/P/ date:DATE - eod date
/R/ no return value
/E/ .gen.dist.pubEod[.z.d]
.gen.dist.pubEod:{[date]
  .log.info[`gen] "Eod action for Dist server";
  .event.dot[`gen;`.gen.dist.eodOne;;();`info`info`error;"EOD trigger"] each flip value flip ungroup 0!select date, tab, sectors from .gen.cfg.tabs;
  };

/------------------------------------------------------------------------------/
/F/ Triggers eod for dist server for one table-sector combination and trigger journal roll.
/P/ date:DATE     - eod date
/P/ tab:SYMBOL    - table name
/P/ sector:SYMBOL - sector name
/R/ no return value
/E/ .gen.dist.pubEod[.z.d;`trade;`SEC0]
.gen.dist.eodOne:{[date;tab;sector]
  .hnd.h[.gen.cfg.dst](`.dist.pubOne;`eod;tab;sector;date);
  .hnd.h[.gen.cfg.dst](`.dist.rollJrn;tab;sector;1b);
  };

/------------------------------------------------------------------------------/
/                                    main                                      /
/------------------------------------------------------------------------------/
/F/ Component initialization entry point.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]
  .gen.cfg.dst:      .cr.getCfgField[`THIS;`group;`cfg.dst];
  .gen.cfg.eodTime:  .cr.getCfgField[`THIS;`group;`cfg.eodTime];
  .gen.cfg.tabs:     1!select tab:sectionVal, period, pkgSize, sectors from .cr.getCfgPivot[`THIS;`table;`period`pkgSize`sectors]; 
  .gen.cfg.uniSize:  .cr.getCfgField[`THIS;`group;`cfg.uniSize];
  .gen.cfg.models:   exec sectionVal!model from .cr.getCfgPivot[`THIS;`table;`model];
  .gen.init[];
  };

/------------------------------------------------------------------------------/
.sl.run[`gen;`.sl.main;`];

/------------------------------------------------------------------------------/
