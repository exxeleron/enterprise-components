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

/A/ DEVnet: Joanna Jarmulska, Pawel Hudak, Bartosz Kaliszuk
/V/ 3.0
/S/ Access point component:
/S/ Responsible for:
/S/ - providing abstraction level for users to effortlessly query both historical (<hdb.q>) and real-time data (<rdb.q>) using the same interface described in the <query.q> library
/S/ - applying user authorization performed by the <authorization.q> library
/S/ - providing access control by defining functions that are permitted to specific users, described in the <authorization.q> library
/S/ Adding new user, user groups, permitted namespaces, and security check levels should take place in global access.cfg file (see <access.qsd>).
/S/ Additional plugins should be specified on the command line using `-lib' switch (see <.sl.libCmd[]> in <sl.q>).

/T/ q accessPoint.q -lib demoExample -p 5020

/------------------------------------------------------------------------------/
/                               lib and etc                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`ap];

.sl.lib["cfgRdr/cfgRdr"];

/------------------------------------------------------------------------------/
/F/ Main initialization function for the component 
/F/ - loads configuration settings to namespace .ap.cfg
/E/ .sl.main[`];
.sl.main:{
  .ap.cfg.serverAux:.cr.getCfgField[`THIS;`group;`cfg.serverAux];
  .ap.cfg.timeout:.cr.getCfgField[`THIS;`group;`cfg.timeout];
  .ap.p.init[];
  };

.ap.p.init:{[params]
  .hnd.hopen[.ap.cfg.serverAux;.ap.cfg.timeout;`lazy];
  .sl.libCmd[];
  .auth.init[];
  .log.info[`ap] "Users ", .Q.s1[.auth.cfg.tab`users], " added.";
  };

/------------------------------------------------------------------------------/
.sl.run[`ap;`.sl.main;`];

/==============================================================================/
\