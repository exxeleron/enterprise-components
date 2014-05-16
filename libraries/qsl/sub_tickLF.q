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
/S/ This library should be used via qsl/sub library.
/S/ Provides API for subscription to data published in tickLF (<tickLF.q>) or tickHF (<tickHF.q>) protocols

/S/ Features:
/S/ - event based subscription and data replay from tickLF and tickHF components
/S/ - handling data updates in tickLF and tickHF protocols

/------------------------------------------------------------------------------/
/                      tickLF subscription                                     /
/------------------------------------------------------------------------------/
//F/ Subscription to using tickLF interface
//P/ server - logical name of the server that was initialized by .hnd.hopen
//P/ tabs - list of table to be subscribed
//P/ uni - list of universe to subscribe
//E/ tabs:enlist `universe
//E/ server:`tickLF1
//E/ uni:enlist `
.sub.tickLF.subscribe:{[server;tabs;uni]
  subDetails:{[server;table;uni].hnd.h[server](".tickLF.sub";table;uni)}[server;;]'[tabs;uni];
  .sub.tickLF.initAndReplayTab each subDetails;
  };

/------------------------------------------------------------------------------/
/F/ Initialize in memory and relay data for one table.
/P/ subDetail - data model and journal((table name;model);(number of entries to replay; journal name)
/E/ subDetail:(`universe;flip `time`sym`mat!(`time$();0#`;`date$());(1;`:jrn))
.sub.tickLF.initAndReplayTab:{[subDetail]
  .log.debug[`sub] "Set data model for table:", .Q.s1[subDetail[0;0]];
  .[;();:;]. subDetail[0];
  .event.at[`sub;`.Q.gc;();`;`info`info`error;"garbage collection"];
  .event.at[`sub;`.sub.tickLF.replayData; subDetail 1;`;`info`info`error;"replaying the data from journal", string[subDetail[1;1]]];
  };

/------------------------------------------------------------------------------/
/F/ Replay data from one tickLF journal.
/P/ jrn:(PAIR(INT;SYMBOL)) - pair with (number of entries to replay; journal name)
/E/ .sub.tickLF.replayData[(1;`:jrn)]
.sub.tickLF.replayData:{[jrn]
  .log.info[`sub] "Replaying ",string[jrn 0], " messages from: ",string[jrn 1];
  -11!jrn;
  };

/------------------------------------------------------------------------------/
/                      tickLF default callbacks                                /
/------------------------------------------------------------------------------/
/G/ default realtime callbacks for tickLF
.sub.tickLF.default:()!();

/------------------------------------------------------------------------------/
/F/ Function for receiving data updates from tickLF
/P/ x:SYMBOL - table name
/P/ y:TABLE - data
.sub.tickLF.default[`.tickLF.upd`.tickLF.jUpd]:{[x;y]
  if[0=type y;f:key flip value x;y:flip f!(),/:y];
  x upsert y;
  };

/------------------------------------------------------------------------------/
/F/ function for receiving data images from tickLF
/P/ x - table name (symbol)
/P/ y - data (table;list) 
.sub.tickLF.default[`.tickLF.img`.tickLF.jImg]:{[x;y]
  // check if y is a table or a list
  if[0=type y;f:key flip value x;y:flip f!(),/:y];
  x set @[;`sym;`g#]y;
  };

/------------------------------------------------------------------------------/
/F/ function for receiving data upserts from tickLF
/P/ x - table name (symbol)
/P/ d - data (table;list) 
/P/ c - list of constraints, 
/P/ b - dictionary of group-bys, 
/P/ a - dictionary of aggregates 
.sub.tickLF.default[`.tickLF.ups`.tickLF.jUps]:{[x;d;c;b;a]
  if[0=type d;f:key flip value x;d:flip f!(),/:d];
  dServer:?[x;c;b;a];
  dToUps:?[d;();b;a];
  toUps:$[count a;
    (key flip value x) xcols ungroup dServer upsert dToUps;
    (key flip value x) xcols 0!dServer upsert dToUps
    ];
  x set @[;`sym;`g#]toUps;
  };

/------------------------------------------------------------------------------/
/F/ function for receiving data deletes from tickLF
/P/ x - table name (symbol)
/P/ c - list of constraints, 
/P/ b - dictionary of group-bys, 
/P/ a - dictionary of aggregates 
.sub.tickLF.default[`.tickLF.del`.tickLF.jDel]:{[x;c;b;a]
  ![x;c;b;a];
  };
  
/==============================================================================/
/
.sub.p.cbDefined:{[cbName] @[{value x;`yes};cbName;`no]};
.sub.p.cbDefined each key .sub.tickLF.default,`a`b!1 2
value "ad"