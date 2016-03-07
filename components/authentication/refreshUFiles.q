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

/V/ 3.0

/S/ Refresh permissions component:
/-/ Responsible for:
/-/ - regeneration of user access files (used with -u/-U options)
/-/ Notes:
/-/ - this script generates one file for each component with permitted users information taken from access.cfg file.
/-/ - files are generated in cfg.userTxtPath specified directory.

/------------------------------------------------------------------------------/
/                               lib and etc                                    /
/------------------------------------------------------------------------------/
system"l ",getenv[`EC_QSL_PATH],"/sl.q";
.sl.init[`refUFiles];
.sl.lib["cfgRdr/cfgRdr"];

/------------------------------------------------------------------------------/
/F/ Component initialization entry point.
/P/ flags:LIST - nyi
/R/ no return value
/E/ .sl.main`
.sl.main:{[flags]
  .cr.loadCfg[`ALL];
  .ru.p.init[];
  exit[0];
  };

/------------------------------------------------------------------------------/
.ru.p.init:{[params]
  // define users
  .log.info[`ru] "Refreshing user access files...";
  dx:{[x;y] `char$0b sv/:y<>/:0b vs/:`int$x}[;.sl.p.m];
  groups:select ug:sectionVal, procname:subsection from .cr.getCfgTab[`ALL; `userGroup;`namespaces];
  cfggroups:distinct groups`ug;
  groupsn:(ungroup update procname:count[g]#enlist .cr.p.procNames except `ALL from g:select from groups where procname=`ALL),select from groups where procname<>`ALL;
  users:ungroup select user:sectionVal,pass:(count'[usergroups])#'enlist each value each pass, ug:usergroups from .cr.getGroupCfgPivot[`user`technicalUser;`pass`usergroups];
  ugroups:distinct users`ug;
  /groups that are missing user mappings
  if[count nousers:cfggroups where not cfggroups in ugroups;
    .log.warn[`ru] "There are groups without any users assigned: ", .Q.s1[nousers], ". Skipping group configuration.";
    ];
  /groups that were assigned to users but do not exist
  if[count nonexistent:ugroups where not ugroups in cfggroups;
    .log.warn[`ru] "Users are configured with non-existent groups: ", .Q.s1[nonexistent], ". Skipping group configuration.";
    ]; 
  joined:(select from groupsn where not ug in nousers) lj `ug xgroup select from users where not ug in nonexistent;
  matched:distinct delete usergroups from ungroup joined;
  umatched: matched lj `procname xcol select from .cr.getByProc[enlist `uFile] where not uFile=`$":";
  / fetch only non-empty configurations
  umatched: delete from umatched where null uFile;
  .ru.p.verify[umatched];
  d: exec flip `user`pass!(user;""sv/:string md5 each dx each pass) by uFile from umatched;
  .ru.p.genUfiles'[key d;value d];
  .log.info[`ru] "Refresh completed";
  };

/------------------------------------------------------------------------------/
.ru.p.genUfiles:{[path;u]
 users:distinct u;
 .log.info[`ru]"Creating security context with #users: ",string[count users], " in file:";
 .log.info[`ru] 1_string[path];
 path 0:1_":" 0:users;
 };

/------------------------------------------------------------------------------/
.ru.p.verify:{[umatched]
  / check user count per process vs count per distinct u file
  perproc:select pucnt:count i by procname, uFile  from umatched;
  perfile:select fucnt:count distinct user  by uFile from umatched;
  /find not equal counts in files
  faultyFiles:exec distinct uFile from (perproc lj perfile) where pucnt<>fucnt;
  /find processes providing more users
  faultyProcs:exec procname!uFile from (perproc lj perfile) where uFile in faultyFiles,pucnt=fucnt;
  .log.warn[`ru] "Some processes (", (", " sv string key faultyProcs), ") provide additional users to a \"shared\" user files ", 
                   "(", (", " sv string value faultyProcs), ").";
  .log.info[`ru] "Please provide separate user files for processes: ", .Q.s1 key faultyProcs;
  }

/------------------------------------------------------------------------------/
.sl.run[`ru;`.sl.main;`];

/==============================================================================/
