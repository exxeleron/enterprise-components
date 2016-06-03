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

/A/ DEVnet: Joanna Jarmulska, Pawel Hudak, Bartosz Kaliszuk
/V/ 3.0
/S/ Access point component:
/-/ Responsible for:
/-/ - providing abstraction level for users to effortlessly query both historical (<hdb.q>) and real-time data (<rdb.q>) using the same interface described in the <query.q> library
/-/ - applying user authorization performed by the <authorization.q> library
/-/ - providing access control by defining functions that are permitted to specific users, described in the <authorization.q> library
/-/ Adding new user, user groups, permitted namespaces, and security check levels should take place in global access.cfg file (see <access.qsd>).
/-/ Additional plugins should be specified on the command line using `-lib' switch (see <.sl.libCmd[]> in <sl.q>).

/T/ q accessPoint.q -lib demoExample -p 5020

/------------------------------------------------------------------------------/
/                               lib and etc                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`ap];

.sl.lib["cfgRdr/cfgRdr"];

/------------------------------------------------------------------------------/
/F/ Main initialization function for the component.
/-/ - loads configuration settings to namespace .ap.cfg
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]
  /G/ List of aux servers, loaded from cfg.serverAux field from system.cfg.
  .ap.cfg.serverAux:.cr.getCfgField[`THIS;`group;`cfg.serverAux];
  /G/ Connections timeout, loaded from cfg.timeout field from system.cfg.
  .ap.cfg.timeout:.cr.getCfgField[`THIS;`group;`cfg.timeout];
  .ap.p.init[];
  };

/------------------------------------------------------------------------------/
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