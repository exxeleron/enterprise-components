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

/A/ DEVnet:  Joanna Jarmulska, Pawel Hudak.
/V/ 3.0

/S/ Subscription management library:
/S/ Provides API for subscription to data published in tickLF (<tickLF.q>) or tickHF (<tickHF.q>) protocols

/S/ Features:
/S/ - event based subscription and data replay from tickLF and tickHF components
/S/ - handling data updates in tickLF and tickHF protocols

/S/ TickHF subscription library:
/S/ Proxy for subscription to data published using tickHF (<tickHF.q>) protocol

/S/ Features:
/S/ - definition of default callbacks upd and jUpd
/S/ - functions for subscription and replay of the data from tickHF

/------------------------------------------------------------------------------/
/                      tickHF subscription                                     /
/------------------------------------------------------------------------------/
//F/ subscription using tickHF interface
//P/ server - logical name of the server that was initialized by .hnd.hopen
//P/ tabs - list of table to be subscribed
//P/ uni - list of universe to subscribe
//E/ tabs:enlist `trade
//E/ server:`tick1
//E/ uni:enlist `
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
//F/ function for replay data for mode tickHF
//P/ jrn - number of entries to replay and journal name
//E/ jrn:(1;`:jrn)
.sub.tickHF.replayData:{[jrn]
  .log.info[`sub] "Replaying ",string[jrn 0], " messages from: ",string[jrn 1];

  -11!(type[0]$string jrn 0;jrn 1); // dirty hack to support both ints for q2.7 and longs for q3.0+
  };

/------------------------------------------------------------------------------/
/                      tickHF default realtime callbacks                       /
/------------------------------------------------------------------------------/
/G/ default realtime callbacks for tickLF
.sub.tickHF.default:()!();

/------------------------------------------------------------------------------/
/F/ initialize data model using schema from subscription callback
.sub.tickHF.default[`sub]:{[server;schema] (set) ./: schema};

/------------------------------------------------------------------------------/
/F/ insert data on updates from tickHF
.sub.tickHF.default[`upd]:insert;

/------------------------------------------------------------------------------/
/F/ insert data on tickHF journal replay
.sub.tickHF.default[`jUpd]:{[t;d]
  if[t in .sub.subListOfJrnTabs;
    t insert d;
    ];
  };
   

/==============================================================================/
/

sub
{key[x]}.sub.tickHF.default

sub