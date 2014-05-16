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
/G/ All of them take one parameter (number of requested elements)
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
/F/ Initialization of the data generator
/F/ - generation of the universe
/F/ - initialization of tables generators - each generator is stored under the name of table that it is generating
/F/ - loading of custom code
/F/ - initialization of the connection to destination server
.gen.init:{[]
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
/F/ callback for destination server "port open"
/F/ - initialization of eod timer
/F/ - detection of destination server protocol
/F/ - initialization of publishing timers - one per each table
.gen.po:{
  //detect protocol
  .gen.dstProtocol:first .hnd.h[.gen.cfg.dst]".sl.getSubProtocols[]";
  if[.gen.dstProtocol~`PROTOCOL_DIST;
    .log.info[`gen]"using DIST protocol, see .gen.dist namespace";
    .gen.pubTabTrigger:`.gen.dist.pubTab;
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
/F/ callback for destination server "port close"
.gen.pc:{
  select .tmr.stop'[tab] from .gen.cfg.tabs
  };

/------------------------------------------------------------------------------/
/                              PROTOCOL_TICKHF                                 /
/------------------------------------------------------------------------------/
/F/ trigger data publishing of one package for one table to the tickHF server.
/P/ tab:SYMBOL - table name
/P/ ts:TIMESTAMP - time of the package
.gen.tickHF.pubTab:{[tab;ts]
  data:.gen.generate[.gen.cfg.models[tab][`col2]] @ \: .gen.cfg.tabs[tab][`pkgSize];
  .hnd.h[.gen.cfg.dst](`.u.upd;tab;data);
  };

/------------------------------------------------------------------------------/
/F/ trigger eod for tickHF server
/P/ date:DATE - eod date
.gen.tickHF.pubEod:{[date]
  .log.info[`gen] "No eod action for tickHF";
  };

/------------------------------------------------------------------------------/
/                              PROTOCOL_DIST                                   /
/------------------------------------------------------------------------------/
/F/ trigger data publishing of one package for one table to the dist server.
/P/ tab:SYMBOL - table name
/P/ ts:TIMESTAMP - time of the package
.gen.dist.pubTab:{[tab;ts]
  `tab set tab;`ts set ts;
  data:.gen.generate[.gen.cfg.models[tab][`col2]] @ \: .gen.cfg.tabs[tab][`pkgSize];
  sector:first 1?.gen.cfg.tabs[tab][`sectors];
  .hnd.h[.gen.cfg.dst](`.dist.pubOne;`upd;tab;sector;data);
  };

/------------------------------------------------------------------------------/
/F/ trigger eod for dist server for one table-sector combination
/P/ date:DATE - eod date
.gen.dist.pubEod:{[date]
  .log.info[`gen] "Eod action for Dist server";
  .event.dot[`gen;`.gen.dist.eodOne;;();`info`info`error;"EOD trigger"] each flip value flip ungroup 0!select date, tab, sectors from .gen.cfg.tabs;
  };

/------------------------------------------------------------------------------/
/F/ trigger eod for dist server for one table-sector combination and trigger journal roll
/P/ date:DATE - eod date
/P/ tab:SYMBOL - table name
/P/ sector:SYMBOL - sector name
.gen.dist.eodOne:{[date;tab;sector]
  .hnd.h[.gen.cfg.dst](`.dist.pubOne;`eod;tab;sector;date);
  .hnd.h[.gen.cfg.dst](`.dist.rollJrn;tab;sector;1b);
  };

/------------------------------------------------------------------------------/
/                                    main                                      /
/------------------------------------------------------------------------------/
.sl.main:{[]
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
