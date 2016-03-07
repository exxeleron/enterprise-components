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

/A/ DEVnet:  Joanna Jarmulska, Pawel Hudak.
/V/ 3.0

/S/ Subscription management library:
/-/ Provides API for subscription to data published in tickLF (<tickLF.q>) or tickHF (<tickHF.q>) protocols

/-/ Features:
/-/ - event based subscription and data replay from tickLF and tickHF components
/-/ - handling data updates in tickLF and tickHF protocols

/-/ TickHF subscription library:
/-/ Proxy for subscription to data published using tickHF (<tickHF.q>) protocol

/-/ Features:
/-/ - definition of default callbacks upd and jUpd
/-/ - functions for subscription and replay of the data from tickHF

/------------------------------------------------------------------------------/
/                      tickHF subscription                                     /
/------------------------------------------------------------------------------/
/F/ Subscribes to tickHF-like data source.
/P/ server:SYMBOL - logical name of the server that was initialized by .hnd.hopen
/P/ tabs:SYMBOL | LIST SYMBOL - list of tables requested for subscribtion, ` for ALL
/P/ uni:SYMBOL | LIST SYMBOL - list of universe entries requested for subscription, ` for ALL
/R/ no return value
/E/ .sub.tickHF.subscribe[`core.tickHF; `; `]
/-/   - subscribes for all tables, full universe from core.tickHF server
/E/ .sub.tickHF.subscribe[`core.tickHF; enlist `trade; `]
/-/   - subscribes for `trade table, full universe from core.tickHF server
.sub.tickHF.subscribe:{[server;tabs;uni]
  subDetails:.hnd.h[server]"(.u.sub'[`",("`" sv string[tabs]),";`",("`" sv string[(),uni]), "];`.u `i`L)";
  .log.debug[`sub] "Set data model for tables: `","`" sv string[tabs];
  if[1~count tabs;subDetails[0]:enlist subDetails[0]];
  .log.debug[`sub] "Garbage collection";
  .pe.atLog[`sub;`.Q.gc;();`;`error];
  .event.dot[`sub;`sub;(server;subDetails 0);`;`info`info`error;"sub[x;y] callback"];  //callback
  .sub.subListOfJrnTabs:tabs; //Note: tmp variable used in jUpd to limit loaded tables
  .event.at[`sub;`.sub.tickHF.replayData; subDetails 1;`;`info`info`error;"replaying the data from ", string[server]];
  delete subListOfJrnTabs from `.sub;
  };

/------------------------------------------------------------------------------/
/F/ Replays data from tickHF source.
/P/ jrn:PAIR(LONG;SYMBOL) - number of entries to replay and journal name
/R/ no return value
/E/ .sub.tickHF.replayData(100j;`:jrn)
/-/  - replay 100 entries from `:jrn
.sub.tickHF.replayData:{[jrn]
  .log.info[`sub] "Replaying ",string[jrn 0], " messages from: ",string[jrn 1];

  -11!(type[0]$string jrn 0;jrn 1); // dirty hack to support both ints for q2.7 and longs for q3.0+
  };

/------------------------------------------------------------------------------/
/                      tickHF default realtime callbacks                       /
/------------------------------------------------------------------------------/
/G/ Default realtime callbacks for tickHF.
.sub.tickHF.default:()!();

/------------------------------------------------------------------------------/
/F/ Initialize data model using schema from subscription callback.
.sub.tickHF.default[`sub]:{[server;schema] (set) ./: schema};

/------------------------------------------------------------------------------/
/F/ Insert data on updates from tickHF.
.sub.tickHF.default[`upd]:insert;

/------------------------------------------------------------------------------/
/F/ Insert data on tickHF journal replay.
.sub.tickHF.default[`jUpd]:{[t;d]
  if[t in .sub.subListOfJrnTabs;
    t insert d;
    ];
  };
   
/==============================================================================/
/

