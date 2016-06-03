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

/A/ DEVnet: Pawel Hudak, Joanna Jarmulska
/V/ 3.0

/S/ Authorization library:
/-/ - providing authorization by validating incoming function calls against allowed namespaces and forbidden keywords (stop words); authorization configuration is described in access.cfg schema file (see <access.qsd>)
/-/ - logging access and function calls facilities (audit view) - logging of incoming synchronous and asynchronous function calls and user login/logout; audit view configuration is described in access.cfg schema file (see <access.qsd>)

//----------------------------------------------------------------------------//
//                          interface functions                               //
//----------------------------------------------------------------------------//
/F/ Changes authorization and/or auditView settings in the run-time. Note: The change will not persist after the restart.
/-/  access.cfg file must be modified manually in order to make persistent authorization configuration change.
/P/ cfg:TABLE - authorization configuration table with columns:
/-/  -- users:SYMBOL - user name
/-/  -- auditView:ENUM[``CONNECTIONS_INFO`SYNC_ACCESS_INFO`ASYNC_ACCESS_INFO] - audit view
/-/  -- checkLevel:ENUM[`NONE`STRICT`FLEX] - authorization level
/R/ TABLE - new, currently activ configuration
/E/ .auth.setAuth ([] users: enlist`adminUser; auditView: enlist`CONNECTIONS_INFO`SYNC_ACCESS_INFO; checkLevel: enlist`NONE)
/-/    - overwrites authorization settings with the specified configuration table 
/E/ .auth.setAuth .auth.cfg.tab
/-/     - sets authorization back to the settings in .auth.cfg.tab
.auth.setAuth:{[cfg]
  // turn on `CONNECTIONS_INFO
  connOn:exec users from  cfg where `CONNECTIONS_INFO in/:auditView;
  .auth.p.poUser[connOn]:.auth.p.poCall;
  connOff:exec users from  cfg where not `CONNECTIONS_INFO in/:auditView;
  .log.debug[`auth]"Turn off audit view CONNECTIONS_INFO for users:",.Q.s1[distinct connOff];
  .auth.p.poUser:connOff _.auth.p.poUser;
  $[not count connOn;
    [.log.debug[`auth]"Audit view CONNECTIONS_INFO is turned off";
      .cb.del[`.z.po;`.auth.p.po];
      .cb.del[`.z.pc;`.auth.p.pc]];
    [.log.info[`auth]"Turn on audit view CONNECTIONS_INFO for users:",.Q.s1[distinct connOn];
      .cb.add[`.z.po;`.auth.p.po];
      .cb.add[`.z.pc;`.auth.p.pc]]
    ];
  cfg:update auth:0b from   cfg where checkLevel=`NONE;
  cfg:update auth:1b from   cfg where checkLevel in `FLEX`STRICT;
  cfg:update authSignal:1b from  cfg where  not checkLevel in `FLEX`STRICT`NONE;
  cfg:update auditSync:1b from cfg where `SYNC_ACCESS_INFO in/:auditView;
  cfg:update pgFunction:`.auth.p.pgAudit from cfg where auditSync=1b, auth=0b,authSignal=0b ;
  cfg:update pgFunction:`.auth.p.pgAuth from cfg where auditSync=0b, auth=1b;
  cfg:update pgFunction:`.auth.p.pgAuthAudit from cfg where (auditSync=1b) and auth=1b;
  cfg:0!update pgFunction:`.auth.p.pgOff from cfg where (auditSync=0b) and (auth=0b) and authSignal=0b;
  cfg:0!update pgFunction:`.auth.p.pgAuthSignal from cfg where authSignal=1b;

  .auth.p.pgUser[cfg`users]:value each cfg`pgFunction;
  $[all 0b=raze cfg[`auth`auditSync`authSignal];
    [.log.debug[`auth]"Authorization and audit is turned off";
      .cb.del[`.z.pg;`.auth.p.pg]];
    [
      if[count u:exec users from cfg where pgFunction=`.auth.p.pgAudit;
        .log.info[`auth]"Turn on audit view SYNC_ACCESS_INFO for users:",.Q.s1[distinct u];
        ];
      if[count u:exec users from cfg where pgFunction=`.auth.p.pgAuth;
        .log.info[`auth]"Turn on authorization for users:",.Q.s1[u];
        ];
      if[count u:exec users from cfg where pgFunction=`.auth.p.pgAuthAudit;
        .log.info[`auth]"Turn on authorization and audit view SYNC_ACCESS_INFO for users:",.Q.s1[distinct u];
        ];
      .cb.add[`.z.pg;`.auth.p.pg]]
    ];

  psOn:exec users from  cfg where `ASYNC_ACCESS_INFO in/:auditView;
  .auth.p.psUser[psOn]:.auth.p.psCall;
  psOff:exec users from  cfg where not `ASYNC_ACCESS_INFO in/:auditView;
  .log.debug[`auth]"Turn off audit view ASYNC_ACCESS_INFO for users:",.Q.s1[distinct psOff];
  .auth.p.psUser[psOff]:.auth.p.psDef;
  $[not count psOn;  
    [.log.debug[`auth]"Audit view ASYNC_ACCESS_INFO is turned off";
      .cb.del[`.z.ps;`.auth.p.ps]];
    [.log.info[`auth]"Turn on audit view ASYNC_ACCESS_INFO for users:",.Q.s1[distinct psOn];
      .cb.add[`.z.ps;`.auth.p.ps]]
    ];
  cfg
  };

/------------------------------------------------------------------------------/
/F/ Refreshes authorization data structures, in particular activates access for newly added functions.
/-/  Access to functions is configured on the level of namespaces (see namespaces field in the access.cfg file). 
/-/  Authorization library maintains internal data structure, which contains mapping of each user to a set of allowed functions - .auth.user2nm.
/-/  Functions added in the runtime, after the authorization library as initialized, are not included in the .auth.user2nm.
/-/  .auth.updateAuthFunctions[] refreshes content of the .auth.user2nm basing on the functions currently available in memory.
/R/ TABLE - new, currently activ user2nm configuration, content of the .auth.user2nm global variable
/E/ .auth.updateAuthFunctions[]
.auth.updateAuthFunctions:{[]
  auth:update functions:namespaces from .auth.cfg.tab;
  nmAdded:update functions:raze each .auth.p.getNs''[namespaces] from  auth  where not `ALL in/:namespaces;
  validNm:update validNm:{[p]{[x;y]1b}[p;]} each functions from nmAdded where `ALL in/: functions;
  validNm:update validNm:{[p]{[x;y]y in x}[p;]} each functions from  validNm where not `ALL in/: functions;

  /G/ Authorization configuration, loaded from access.cfg.
  /-/  -- users:SYMBOL                       - user name
  /-/  -- usergroups:SYMBOL                  - user group
  /-/  -- userType:ENUM(user, technicalUser) - type of the user
  /-/  -- pass:STRING                        - encoded password
  /-/  -- auditView:LIST SYMBOL              - currently active audit view - based on auditView field in the access.cfg
  /-/  -- namespaces:LIST SYMBOL             - list of namespaces allowed for the given user
  /-/  -- stopWords:LIST STRING              - list of stop words, used to block queries in case of FLEX access
  /-/  -- functions:LIST SYMBOL              - list of functions allowed in the queries
  /-/  -- validNm:LAMBDA                     - namespace validation
  .auth.cfg.tab:validNm;
  /G/ Dictionary with function level restrictions per user, loaded from access.cfg.
  /-/  -- key:SYMBOL - user name
  /-/  -- val:LAMBDA - lambda returning allowed function names
  .auth.user2nm:exec users!validNm from  .auth.cfg.tab;
  .auth.user2nm
  };

//----------------------------------------------------------------------------//
//                            private functions                               //
//----------------------------------------------------------------------------//
/F/ Logging user logout.
/P/ h:SHORT - connection handle
/R/ no return value
.auth.p.pc:{[h]
  if[not count u:exec user from .auth.status where hnd~\:h;:()];
  u:first u;
  delete from `.auth.status where hnd=h;
  .log.info[`auth] `action`user`hnd!(`USER_LOGOUT;u;h);
  };

/------------------------------------------------------------------------------/
/F/ Port open callbacks by user.
.auth.p.poUser:()!();

/------------------------------------------------------------------------------/
/F/ Logging user login.
/P/ h:SHORT - connection handle
// port open user - .z.u
.auth.p.po:{[h]
  .auth.p.poUser[.z.u;h];
  };

/------------------------------------------------------------------------------/
/F/ Port open callback definition.
.auth.p.poCall:{[h]
  ip:"."sv string "i"$0x0 vs .z.a; host:.Q.host .z.a;
  `.auth.status insert (.z.u;h;`$ip;host;.sl.zp[]);
  .log.info[`auth] `action`user`hnd`ip`addr!(`USER_LOGIN;.z.u;h;ip;host);
  };

/------------------------------------------------------------------------------/
/F/ Synchronous callbacks by user.
.auth.p.pgUser:()!();

/------------------------------------------------------------------------------/
/F/ Logging synchronous access with turn on authentication provided by u/U file (u_opt in system.cfg).
/P/ cmd:STRING - command
.auth.p.pgUOptOn:{[cmd]
  .auth.p.pgUser[.z.u;cmd]
  };

/------------------------------------------------------------------------------/
/F/ Logging synchronous access with turn off authentication (no settings for u_opt in system.cfg).
/P/ cmd:STRING - command
.auth.p.pgUOptOff:{[cmd]
  if[.z.u in .auth.cfg.tab`users;:.auth.p.pgUser[.z.u;cmd]];
  value cmd
  };

/------------------------------------------------------------------------------/
/F/ Default initialization as turned off.
.auth.p.pg:.auth.p.pgUOptOff;

/------------------------------------------------------------------------------/
/F/ Synchronous callback for logging audit.
.auth.p.pgAudit:{[cmd]
  f:10=type cmd;
  .log.info[`auth] `action`user`hnd`asString`query!(`SYNC_STARTED;.z.u;.z.w;f;$[f;cmd;"(",(";" sv .Q.s1 each cmd),")"]);
  res:@[value;cmd;{.log.warn[`auth]`action`signal!(`SYNC_FAILED;x);'x}];
  .log.info[`auth] `action`resType`resCount!(`SYNC_COMPLETED;type res;count res);
  res
  };

/------------------------------------------------------------------------------/
/F/ Synchronous callback with only command evaluation.
.auth.p.pgOff:value;

/------------------------------------------------------------------------------/
/F/ Synchronous callback for authorization.
.auth.p.pgAuth:{[cmd]
  if[not .auth.p.validcmd[u:.z.u;cmd];
    .log.warn[`auth] "ACCESS_DENIED    user=",.Q.s1[u], " hnd=", string[.z.w]," query=", $[10=type cmd;cmd;"(",(";" sv .Q.s1 each cmd),")"];
    '"access denied"
    ]; 
  value cmd
  };

/------------------------------------------------------------------------------/
/F/ Synchronous callback for authorization and audit logging.
.auth.p.pgAuthAudit:{[cmd]
  if[not .auth.p.validcmd[u:.z.u;cmd];
    .log.warn[`auth] "ACCESS_DENIED    user=",.Q.s1[u], " hnd=", string[.z.w]," query=", $[10=type cmd;cmd;"(",(";" sv .Q.s1 each cmd),")"];
    '"access denied"
    ]; 
  .auth.p.pgAudit[cmd]
  };

/------------------------------------------------------------------------------/
.auth.p.pgAuthSignal:{[cmd]
  u:.z.u;
  d:exec first checkLevel, first usergroups from .auth.cfg.tab where users=u;
  '"Invalid checkLevel: ", string[d[`checkLevel]], " in access.cfg for userGroup: ",  string[d[`usergroups]], ". checkLevel should be one of NONE, FLEX or STRICT"
  };

/------------------------------------------------------------------------------/
/F/ Asynchronous callbacks by user.
.auth.p.psUser:()!();

/------------------------------------------------------------------------------/
/F/ Logging asynchronous access with turn on authentication provided by u/U file (u_opt in system.cfg).
/P/ cmd:STRING - command
.auth.p.psUOptOn:{[cmd]
  .auth.p.psUser[.z.u;cmd]
  };

/------------------------------------------------------------------------------/
/F/ Logging asynchronous access with turn off authentication (no settings for u_opt in system.cfg).
/P/ cmd:STRING - command
.auth.p.psUOptOff:{[cmd]
  if[.z.u in .auth.cfg.tab`users;:.auth.p.psUser[.z.u;cmd]];
  value cmd
  };

/------------------------------------------------------------------------------/
/F/ Default initialization as turned off.
.auth.p.ps:.auth.p.psUOptOff;

/------------------------------------------------------------------------------/
/F/ Asynchronous callback for logging audit.
.auth.p.psCall:{[cmd]
  f:10=type cmd;
  .log.info[`auth] `action`user`hnd`asString`query!(`ASYNC_STARTED;.z.u;.z.w;f;$[f;cmd;"(",(";" sv .Q.s1 each cmd),")"]);
  res:@[value;cmd;{.log.warn[`auth]`action`signal!(`ASYNC_FAILED;x);'x}];
  .log.info[`auth] `action`resType`resCount!(`ASYNC_COMPLETED;type res;count res);
  res
  };

/------------------------------------------------------------------------------/
/F/ Asynchronous callback with only command evaluation.
.auth.p.psDef:value;

/------------------------------------------------------------------------------/
.auth.p.getKind:{[nm;kind] :(),raze ` sv/:nm,/:@[system;kind," ",string nm;()]};
.auth.p.getFuns:.auth.p.getKind[;"f"];
.auth.p.getVars:.auth.p.getKind[;"v"];
.auth.p.getNs:{[nm] :raze (.auth.p.getVars;.auth.p.getFuns)@\:nm};

/------------------------------------------------------------------------------/
/F/ Verify if command is permitted for execution for user.
/P/ u:SYMBOL   - user name
/P/ cmd:STRING - command executed by the user
.auth.p.validcmd:{[u;cmd]
  :@[.auth.p.check[.auth.checkLevels[u]][u;];cmd;{[x;cmd;u]'"unsupported query type for check level: ",string[exec first checkLevel from .auth.cfg.tab where users=u], ", query: ", .Q.s1[cmd]}[;cmd;u]];
  };

/------------------------------------------------------------------------------/
/F/ Command parse tree. Helper function for command validation.
/P/ cmd:(LIST|STRING  - command to execute given (as string or list)
/E/ .auth.p.cmdpt cmd:(".demo.test1"; `param1; 2012.01.01)
/E/ .auth.p.cmdpt cmd:".demo.test1[`param1; 2012.01.01]"
.auth.p.cmdpt:{[cmd]
  $[10h=type cmd;parse cmd;cmd]
  };

/------------------------------------------------------------------------------/
/F/ Tokenize supplied command. Return symbols defining functions used in the expression.
/P/ x:LIST - parse tree of a supplied command. Can contain nested expressions.
/E/ .auth.p.tokenize cmd:.auth.p.cmdpt[(".demo.test1";`param1;2012.01.01)]
/E/ .auth.p.tokenize cmd:.auth.p.cmdpt[(".demo.test1";`param1;2012.01.01)]
.auth.p.tokenize:{[x]
  :raze (raze each)over {
    $[0h=type x;
      $[(not 0h=type fx)&1=count $[10h=type fx:first x;fx:`$fx;fx];fx;()],.z.s each x where 0h=type each x;()]
      }x
  };

/-------------------------------- Checks logic --------------------------------/
/ Func / No check on supplied command for given user.
/ Param / u:SYMBOL - username
/ Param / cmd:LIST - command to execute
.auth.p.check.NONE:{[u;cmd]
  :1b
  };

/------------------------------------------------------------------------------/
/ Func / Simple check on supplied command
/ Func / For a command only first level of arguments (of nested type) is check. If its a function call, check fails.
/ Func / Otherwise function call name is checked against allowed namespaces
.auth.p.check.STRICT:{[u;cmd]
  fs:type each first each cmd where 0=type each cmd;
  fc:$[10h=type fc:first cmd;`$fc;fc];
  if[not any(fs=-11)or(fs>99);
    :.auth.user2nm[u] fc;
    ];
  :0b;
  };

/------------------------------------------------------------------------------/
/ Func / Perform full check on all levels recursively down the parse tree.
/ Func / For strings: (1) split by alphanumeric and (2) check result against stopWords and (3) namespaces
/ Func / For parse tree: (1) return potential execution tokens (functions and variable names), (2) and (3) as for strings
/ Param / u:SYMBOL - username executing checked command
/ Param / cmd:STRING - command to execute supplied as string
/ Param / cmd:LIST - command to execute supplied as a parse tree (general list)
.auth.p.check.FLEX:{[u;cmd]
  tc:type cmd:(),cmd;
  words:{`$1_'(where not x in .Q.an,"./\\")_ x:" ",x} $[10h=tc; (),cmd;.Q.s1 cmd];
  tokens:{:distinct .auth.p.tokenize[x],x where -11h=type each x} enlist .auth.p.cmdpt cmd;
  if[any .auth.stopWords[u] in (((),words) except `);:0b];
  /if[any .auth.stopWords[u] in (((),tokens) except `);:0b];
  wc:$[count l:where words in tokens;words l;`];
  :all .auth.user2nm[u] wc;
  };

//----------------------------------------------------------------------------//
//                            init functions                                  //
//----------------------------------------------------------------------------//
/F/ Initializes authorization library. Automatically invoked in .sl.run[] on process startup.
/-/ Function extracts authorization information from access.cfg configuration file.
/R/ no return value
/E/ .auth.init[]
.auth.init:{[]
  uOpt:`;
  users:([]users:`symbol$(); usergroups:(); userType:`symbol$(); pass:`symbol$());
  groups:([]usergroups:`symbol$(); auditView:(); namespaces:(); checkLevel:(); stopWords:());
  warnList:();
  //if config reader available
  if[`cr in key`;
    //get u opt
    uOpt:`$.cr.getCfgField[`THIS;`group;`uOpt];

    //get user config
    usersGroups:select users:sectionVal,usergroups:finalValue, userType:section from .cr.getGroupCfgTab[`user`technicalUser;`usergroups];
    users:usersGroups lj 1!select users:sectionVal,pass:finalValue from .cr.getGroupCfgTab[`user`technicalUser;`pass];

    //get groups config
    groups:select usergroups:sectionVal, auditView, namespaces, checkLevel, stopWords from .cr.getCfgPivot[`THIS; `userGroup;`auditView`namespaces`checkLevel`stopWords];

    //get warning dictionary
    if[.cr.isCfgFieldDefined[`THIS;`group;`cfg.warnIfSyncAccess];    warnList,:`SYNC];
    if[.cr.isCfgFieldDefined[`THIS;`group;`cfg.warnIfAsyncAccess];   warnList,:`ASYNCH];
    if[.cr.isCfgFieldDefined[`THIS;`group;`cfg.warnIfAuthorization]; warnList,:`AUTH];
    ];
  .auth.p.init[users;groups;uOpt;warnList];
  };

//----------------------------------------------------------------------------//
.auth.p.init:{[users;groups;uOpt;warnList]
  if[`initialized in key .auth.p; 
    .log.debug[`auth] "already initialized";
    :()
    ];
  .auth.p.initialized:1b;
  /G/ Table with current status of the authorization library.
  /-/  -- user:SYMBOL       - user name
  /-/  -- hnd:INT           - connection handle
  /-/  -- ip:SYMBOL         - user ip
  /-/  -- host:SYMBOL       - user host name
  /-/  -- loginTs:TIMESTAMP - user login timestamp
  .auth.status:([]user:`symbol$(); hnd:`int$(); ip:`symbol$(); host:`symbol$(); loginTs:`timestamp$());
  //Note: .auding.p.pc is using handle column in .hnd.status to determine whether 
  //     the connection is initialized internally or externally.
  //     For that reason this callback must be called before the hnd pc callback 
  //     (which is removing handle from .hnd.status table).
  .cb.setFirst[`.z.pc;`.auth.p.pc];
  .cb.setFirst[`.z.po;`.auth.p.po];
  $[uOpt in `U`u;
    [.log.info[`auth]"uOpt in system.cfg is turned on, access and audit view is granted for users defined in access.cfg";
      .auth.p.pg:.auth.p.pgUOptOn;
      .auth.p.ps:.auth.p.psUOptOn];
    [.log.info[`auth]"uOpt in system.cfg is turned off, access for all users is granted. Audit view will be enabled only for users defined in access.cfg";
      .auth.p.pg:.auth.p.pgUOptOff;
      .auth.p.ps:.auth.p.psUOptOff]
    ];
  .auth.cfg.tab:ej[`usergroups;ungroup update count'[usergroups]#'enlist each pass from users;groups];
  // add ` user for handling subscription -> subscriber opens conenction to producer, handle catched in .z.w on producer side ans user ` is used for data publishing 
  .auth.cfg.tab,:update users:` from 1 sublist select from .auth.cfg.tab where userType=`technicalUser;
  // add .z.u user for handling callback with handle 0, e.g. journal replay with -11!
  .auth.cfg.tab,:update users:.z.u from 1 sublist select from .auth.cfg.tab where userType=`technicalUser;
  if[(`SYNC in warnList) and `SYNC_ACCESS_INFO in raze .auth.cfg.tab`auditView;
    .log.warn[`auth]"Processing of synchronous messages will be slowed down, because audit for synchronous communication is turned on.";
    ];
  if[(`ASYNC in warnList) and `ASYNC_ACCESS_INFO in raze .auth.cfg.tab`auditView;
    .log.warn[`auth]"Processing of asynchronous messages will be slowed down, because audit for asynchronous communication is turned on.";
    ];
  if[(`AUTH in warnList) and any not .auth.cfg.tab[`checkLevel] in `NONE;
    .log.warn[`auth]"Processing of synchronous messages will be slowed down, because authorization is turned on.";
    ];

  /G/ Dictionary with stop words per user, loaded from access.cfg.
  /-/  -- key:SYMBOL - user name
  /-/  -- val:LAMBDA - list of stop words for the given user
  .auth.stopWords:`$exec users!stopWords from  .auth.cfg.tab;
  /G/ Dictionary with checkLevel (NONE, FLEX or STRICT) per user, loaded from access.cfg.
  /-/  -- key:SYMBOL                     - user name
  /-/  -- val:ENUM(NONE, FLEX or STRICT) - check level 
  .auth.checkLevels:exec users!checkLevel from  .auth.cfg.tab;
  .auth.updateAuthFunctions[];
  .auth.setAuth[select users, auditView, checkLevel from .auth.cfg.tab];
  };

/------------------------------------------------------------------------------/
/
